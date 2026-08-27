"""
Framework comum de ingestão do ObservaDH.

Responsabilidade única: ler as planilhas de um tema (conforme descrito no
arquivo de configuração ingestion/temas/<tema>_config.yml) e gravar o
conteúdo, SEM transformação de negócio, em tabelas RAW no Postgres.

Toda a lógica de normalização/cálculo de indicador fica no projeto dbt
(transform/), não aqui. Este script só deve: identificar arquivos, ler,
tipar minimamente, anexar metadados de carga e persistir.

Uso:
    python ingest.py --tema lgbtqia_plus --ano 2026
    python ingest.py --tema lgbtqia_plus --ano 2026 --dry-run

Variáveis de ambiente esperadas (conexão com o banco):
    OBSERVADH_DB_HOST, OBSERVADH_DB_PORT, OBSERVADH_DB_NAME,
    OBSERVADH_DB_USER, OBSERVADH_DB_PASSWORD
"""

import argparse
import hashlib
import logging
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
import yaml

try:
    from sqlalchemy import create_engine, text
except ImportError:  # pragma: no cover
    create_engine = None
    text = None

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("observadh.ingest")

ROOT_DIR = Path(__file__).resolve().parent
TEMAS_DIR = ROOT_DIR / "temas"
INPUT_DIR = ROOT_DIR / "input"


def carregar_config_tema(tema: str) -> dict:
    caminho = TEMAS_DIR / f"{tema}_config.yml"
    if not caminho.exists():
        raise FileNotFoundError(
            f"Não encontrei config para o tema '{tema}' em {caminho}. "
            f"Crie o arquivo de configuração antes de rodar a ingestão."
        )
    with open(caminho, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def hash_arquivo(caminho: Path) -> str:
    """Hash do conteúdo do arquivo — usado para registrar, no log de carga,
    exatamente qual versão do arquivo foi processada (rastreabilidade)."""
    h = hashlib.sha256()
    with open(caminho, "rb") as f:
        for bloco in iter(lambda: f.read(8192), b""):
            h.update(bloco)
    return h.hexdigest()


def get_engine():
    if create_engine is None:
        raise RuntimeError(
            "sqlalchemy não instalado. Rode: pip install sqlalchemy psycopg2-binary"
        )
    host = os.environ["OBSERVADH_DB_HOST"]
    port = os.environ.get("OBSERVADH_DB_PORT", "5432")
    name = os.environ["OBSERVADH_DB_NAME"]
    user = os.environ["OBSERVADH_DB_USER"]
    password = os.environ["OBSERVADH_DB_PASSWORD"]
    url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{name}"
    return create_engine(url)


def registrar_metadados_carga(engine, id_carga: str, tema: str, arquivo: str,
                               hash_arq: str, linhas_carregadas: int, ano: int):
    """Grava uma linha na tabela de controle metadados_carga — o log de
    auditoria que responde 'de qual arquivo, e quando, saiu este dado'."""
    with engine.begin() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS metadados_carga (
                id_carga UUID PRIMARY KEY,
                tema TEXT NOT NULL,
                arquivo_origem TEXT NOT NULL,
                hash_arquivo TEXT NOT NULL,
                ano_referencia INT NOT NULL,
                linhas_carregadas INT NOT NULL,
                data_processamento TIMESTAMPTZ NOT NULL
            )
        """))
        conn.execute(text("""
            INSERT INTO metadados_carga
                (id_carga, tema, arquivo_origem, hash_arquivo, ano_referencia,
                 linhas_carregadas, data_processamento)
            VALUES
                (:id_carga, :tema, :arquivo, :hash_arq, :ano, :linhas, :agora)
        """), dict(
            id_carga=id_carga, tema=tema, arquivo=arquivo, hash_arq=hash_arq,
            ano=ano, linhas=linhas_carregadas, agora=datetime.now(timezone.utc),
        ))


def processar_aba(engine, tema: str, ano: int, caminho_arquivo: Path,
                   aba_cfg: dict, id_carga: str, dry_run: bool) -> int:
    nome_aba = aba_cfg["nome_aba"]
    tabela_raw = aba_cfg["tabela_raw"]
    cabecalho_linha = aba_cfg.get("cabecalho_linha", 1)

    log.info("Lendo %s (aba: %s) -> %s", caminho_arquivo.name, nome_aba, tabela_raw)

    df = pd.read_excel(
        caminho_arquivo,
        sheet_name=nome_aba,
        header=cabecalho_linha - 1,
    )

    # Metadados de carga — mantidos em toda tabela RAW para rastreabilidade.
    df["arquivo_origem"] = caminho_arquivo.name
    df["nome_aba"] = nome_aba
    df["ano_referencia_carga"] = ano
    df["id_carga"] = id_carga
    df["data_processamento"] = datetime.now(timezone.utc)

    if dry_run:
        log.info("[dry-run] %d linhas lidas de %s, nada gravado.", len(df), nome_aba)
        return len(df)

    # RAW é append-only: cada carga soma ao histórico, nunca sobrescreve.
    df.to_sql(tabela_raw, engine, if_exists="append", index=False)
    log.info("Gravadas %d linhas em %s", len(df), tabela_raw)
    return len(df)


def ingerir_tema(tema: str, ano: int, dry_run: bool = False):
    config = carregar_config_tema(tema)
    diretorio_ano = INPUT_DIR / tema / str(ano)

    if not diretorio_ano.exists():
        raise FileNotFoundError(
            f"Diretório de entrada não encontrado: {diretorio_ano}. "
            f"Coloque as planilhas em ingestion/input/{tema}/{ano}/ antes de rodar."
        )

    engine = None if dry_run else get_engine()
    total_linhas = 0

    for planilha_cfg in config["planilhas"]:
        nome_arquivo = planilha_cfg["arquivo"]
        caminho_arquivo = diretorio_ano / nome_arquivo

        if not caminho_arquivo.exists():
            log.warning("Arquivo esperado não encontrado, pulando: %s", caminho_arquivo)
            continue

        id_carga = str(uuid.uuid4())
        hash_arq = hash_arquivo(caminho_arquivo)

        for aba_cfg in planilha_cfg["abas"]:
            linhas = processar_aba(
                engine, tema, ano, caminho_arquivo, aba_cfg, id_carga, dry_run
            )
            total_linhas += linhas

        if not dry_run:
            registrar_metadados_carga(
                engine, id_carga, tema, nome_arquivo, hash_arq, total_linhas, ano
            )

    log.info(
        "Ingestão do tema '%s' (ano %d) concluída. Total de linhas processadas: %d",
        tema, ano, total_linhas,
    )


def main():
    parser = argparse.ArgumentParser(description="Ingestão de planilhas do ObservaDH")
    parser.add_argument("--tema", required=True, help="ex.: lgbtqia_plus")
    parser.add_argument("--ano", type=int, required=True, help="ano de referência da carga")
    parser.add_argument("--dry-run", action="store_true",
                         help="lê e valida as planilhas sem gravar no banco")
    args = parser.parse_args()

    try:
        ingerir_tema(args.tema, args.ano, dry_run=args.dry_run)
    except Exception:
        log.exception("Falha na ingestão do tema '%s'", args.tema)
        sys.exit(1)


if __name__ == "__main__":
    main()
