"""
Framework comum de ingestão do ObservaDH.

Responsabilidade única: ler TODAS as abas de TODAS as planilhas de um tema e
gravar o conteúdo, SEM transformação de negócio, em tabelas RAW no Postgres.

Descoberta automática: cada aba de cada arquivo .xlsx/.xls em
    ingestion/input/<tema>/<ano>/
vira uma tabela  <schema_raw>.<prefixo>_<planilha>_<aba>.
  - <prefixo>   = prefixo_tabela do config (ex.: lgbt)
  - <planilha>  = prefixos_planilha[arquivo] do config, ou abreviação
                  automática do nome do arquivo (sem ano/versão)
  - <aba>       = nome da aba INTEIRO, só normalizado (sem acento, snake_case);
                  não é abreviado
Só a parte <planilha> é encurtada se o total passar de 63 caracteres.
Nenhum mapeamento manual de aba é necessário.

Cada execução RECRIA as tabelas do zero (carga limpa — sem histórico de
linhas). O histórico das EXECUÇÕES fica em  <schema_raw>.etl_importacao_arquivos.

Toda a lógica de normalização/cálculo de indicador fica no projeto dbt
(transform/), não aqui.

Uso:
    python ingest.py --tema lgbtqia_plus --ano 2026
    python ingest.py --tema lgbtqia_plus --ano 2026 --dry-run

Conexão com o banco (ordem de precedência):
    DATABASE_URL   ex.: postgresql+psycopg2://user:senha@host:5432/db
    ou as variáveis  OBSERVADH_DB_HOST / _PORT / _NAME / _USER / _PASSWORD
    (default: localhost:5432 / observadh / postgres / sem senha)
"""

import argparse
import logging
import os
import re
import sys
import unicodedata
from datetime import datetime
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


# --------------------------------------------------------------------------- #
# Configuração do tema
# --------------------------------------------------------------------------- #

def carregar_config_tema(tema: str) -> dict:
    caminho = TEMAS_DIR / f"{tema}_config.yml"
    if not caminho.exists():
        raise FileNotFoundError(
            f"Não encontrei config para o tema '{tema}' em {caminho}. "
            f"Crie o arquivo de configuração antes de rodar a ingestão."
        )
    with open(caminho, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


# --------------------------------------------------------------------------- #
# Normalização de nomes (portado do importador PSR/PI/PCD, já validado em
# produção nos temas anteriores)
# --------------------------------------------------------------------------- #

def normalizar_nome(texto) -> str:
    """minúsculo, sem acento/cedilha, separadores -> underscore, sem
    caracteres especiais, sem underscores duplicados."""
    if texto is None:
        return ""
    texto = str(texto).strip().lower()
    texto = unicodedata.normalize("NFKD", texto)
    texto = texto.encode("ascii", "ignore").decode("utf-8")
    texto = re.sub(r"[^a-z0-9]+", "_", texto)
    texto = re.sub(r"_+", "_", texto)
    return texto.strip("_")


ABREVIACOES = {
    # termos gerais
    "codigo": "cod", "unidade": "unid", "quantidade": "qtd", "numero": "num",
    "populacao": "pop", "percentual": "perc", "porcentagem": "perc",
    "medio": "medio", "rendimento": "rend", "salarial": "sal",
    "trabalho": "trab", "trabalhos": "trabs", "ocupacao": "ocup",
    "remuneradas": "remun", "remunerados": "remun", "formalizacao": "formal",
    "condicao": "cond", "relacao": "rel",
    # faixa etária / demografia
    "faixa": "fx", "masculino": "masc", "feminino": "fem",
    "indigena": "indigena",
    # assistência social / proteção social / benefício
    "beneficio": "benef", "assistencia": "assist", "politica": "polit",
    "participacao": "particip", "protecao": "prot",
    "beneficiarias": "benef", "beneficiarios": "benef",
    # educação
    "educacao": "educ", "graduacao": "graduacao", "instrucao": "instr",
    "fundamental": "fund", "incompleto": "incompl", "completo": "compl",
    "analfabetismo": "analfab", "analfabetos": "analfab",
    # saúde / violência / direitos humanos
    "saude": "saude", "avaliacao": "aval", "atendimentos": "atend",
    "atendimento": "atend", "notificacoes": "notif", "violencia": "viol",
    "violacoes": "violacoes", "denuncias": "denuncias", "denuncia": "denuncia",
    "direitos": "dir", "humanos": "dh",
    # LGBTQIA+
    "orientacao": "orient", "identidade": "ident", "genero": "gen",
    "discriminacao": "discrim", "acolhimento": "acolh",
    "transexuais": "trans", "travestis": "trav", "conjuges": "conj",
    "casamento": "casam", "casamentos": "casam",
}


def abreviar(nome: str) -> str:
    """Encurta nomes longos trocando termos conhecidos por abreviações
    estáveis. Termos desconhecidos passam intactos."""
    partes = nome.split("_")
    partes = [ABREVIACOES.get(p, p) for p in partes]
    return re.sub(r"_+", "_", "_".join(partes)).strip("_")


# Abreviações aplicadas SÓ à parte "nome da planilha" do nome da tabela.
# O nome da ABA é mantido inteiro (normalizado, sem abreviar) para facilitar
# a leitura no cliente do banco. Ver docs/lgbtqia_plus/catalogo-indicadores-lgbtqia.md.
PLANILHA_ABREV = {
    "assistencia": "assist", "estatisticas": "est", "estatistica": "est",
    "registro": "reg", "educacao": "educ", "trabalho": "trab",
    "violencia": "viol", "violencias": "viol", "quantas": "qtas",
    "orientacao": "orient", "identidade": "ident",
}


def abreviar_base_planilha(nome_base: str) -> str:
    """Abrevia a parte derivada do NOME DO ARQUIVO: normaliza, remove tokens
    de ano (19xx/20xx) e de versão (v2, v3...) e aplica PLANILHA_ABREV.
    Não trunca — o controle de 63 chars fica em montar_nome_tabela()."""
    tokens = []
    for t in normalizar_nome(nome_base).split("_"):
        if not t or re.fullmatch(r"(19|20)\d{2}", t) or re.fullmatch(r"v\d+", t):
            continue
        tokens.append(PLANILHA_ABREV.get(t, t))
    return re.sub(r"_+", "_", "_".join(tokens)).strip("_")


def montar_nome_tabela(prefixo: str, base_planilha: str, aba: str, limite: int = 63) -> str:
    """<prefixo>_<base_planilha>_<aba>. Se passar de `limite`, encurta APENAS
    a base_planilha (nunca o prefixo do tema nem o nome da aba)."""
    aba_norm = normalizar_nome(aba)
    nome = f"{prefixo}_{base_planilha}_{aba_norm}"
    if len(nome) <= limite:
        return nome
    espaco_base = limite - len(prefixo) - len(aba_norm) - 2  # 2 underscores
    if espaco_base >= 3:
        base_curta = base_planilha[:espaco_base].rstrip("_")
        nome = f"{prefixo}_{base_curta}_{aba_norm}"
        log.warning("base da planilha encurtada p/ caber em %d chars: %s", limite, nome)
        return nome
    # caso extremo: aba sozinha já estoura o limite -> trunca o todo
    nome = nome[:limite].rstrip("_")
    log.warning("nome de tabela truncado (aba muito longa): %s", nome)
    return nome


def normalizar_colunas_dataframe(df: pd.DataFrame, limite: int = 55) -> pd.DataFrame:
    """Normaliza os nomes das colunas garantindo legibilidade, tamanho
    controlado e unicidade (sufixo _1, _2... em colisão)."""
    novas = []
    usados: dict[str, int] = {}
    for col in df.columns:
        nome = abreviar(normalizar_nome(col)) or "coluna"
        base = nome[:limite].rstrip("_")
        if base not in usados:
            usados[base] = 0
            nome_final = base
        else:
            usados[base] += 1
            sufixo = f"_{usados[base]}"
            nome_final = f"{base[:limite - len(sufixo)]}{sufixo}"
        novas.append(nome_final)
    df.columns = novas
    return df


def tratar_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """Remove colunas e linhas totalmente vazias."""
    df = df.copy()
    df = df.dropna(axis=1, how="all")
    df = df.dropna(axis=0, how="all")
    return df


# --------------------------------------------------------------------------- #
# Banco
# --------------------------------------------------------------------------- #

def get_engine():
    if create_engine is None:
        raise RuntimeError(
            "sqlalchemy não instalado. Rode: pip install sqlalchemy psycopg2-binary"
        )
    url = os.getenv("DATABASE_URL")
    if not url:
        host = os.environ.get("OBSERVADH_DB_HOST", "localhost")
        port = os.environ.get("OBSERVADH_DB_PORT", "5432")
        name = os.environ.get("OBSERVADH_DB_NAME", "observadh")
        user = os.environ.get("OBSERVADH_DB_USER", "postgres")
        password = os.environ.get("OBSERVADH_DB_PASSWORD", "")
        url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{name}"
    return create_engine(url)


def criar_schema(engine, schema: str):
    with engine.begin() as conn:
        conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema}"'))


def preparar_tabela_log(engine, schema: str, recriar: bool):
    with engine.begin() as conn:
        if recriar:
            conn.execute(text(f'DROP TABLE IF EXISTS "{schema}".etl_importacao_arquivos'))
        conn.execute(text(f'''
            CREATE TABLE IF NOT EXISTS "{schema}".etl_importacao_arquivos (
                id SERIAL PRIMARY KEY,
                nm_tema TEXT,
                nm_arquivo TEXT,
                nm_aba TEXT,
                nm_tabela TEXT,
                qtd_linhas INTEGER,
                dt_importacao TIMESTAMP,
                status_importacao TEXT,
                mensagem_erro TEXT
            )
        '''))


def log_importacao(engine, schema, tema, arquivo, aba, tabela, linhas,
                   status="SUCESSO", mensagem_erro=None):
    with engine.begin() as conn:
        conn.execute(text(f'''
            INSERT INTO "{schema}".etl_importacao_arquivos
            (nm_tema, nm_arquivo, nm_aba, nm_tabela, qtd_linhas,
             dt_importacao, status_importacao, mensagem_erro)
            VALUES (:tema, :arquivo, :aba, :tabela, :linhas, :data, :status, :erro)
        '''), dict(tema=tema, arquivo=arquivo, aba=aba, tabela=tabela,
                   linhas=linhas, data=datetime.now(), status=status,
                   erro=mensagem_erro))


def importar_dataframe(engine, schema: str, df: pd.DataFrame, tabela: str):
    """Recria a tabela raw do zero para garantir carga limpa."""
    with engine.begin() as conn:
        conn.execute(text(f'DROP TABLE IF EXISTS "{schema}"."{tabela}"'))
    df.to_sql(tabela, engine, schema=schema, if_exists="fail",
              index=False, method="multi", chunksize=1000)


# --------------------------------------------------------------------------- #
# Orquestração
# --------------------------------------------------------------------------- #

def nome_base_arquivo(nome_arquivo: str) -> str:
    base = normalizar_nome(re.sub(r"\.(xlsx|xls)$", "", nome_arquivo, flags=re.I))
    for prefixo in ("lgbtqia_", "lgbt_"):
        if base.startswith(prefixo):
            return base[len(prefixo):]
    return base


def processar_arquivo(engine, cfg: dict, caminho: Path, dry_run: bool) -> int:
    tema = cfg["tema"]
    prefixo = cfg.get("prefixo_tabela", tema)
    schema = cfg.get("schema_raw", "raw")
    ignorar_abas = {normalizar_nome(a) for a in cfg.get("ignorar_abas", [])}

    # Prefixo da tabela derivado do arquivo: usa o override explícito do
    # config (prefixos_planilha) e, se não houver, abrevia automaticamente.
    prefixos_planilha = cfg.get("prefixos_planilha") or {}
    nome_arquivo = caminho.name
    base_planilha = prefixos_planilha.get(nome_arquivo) or \
        abreviar_base_planilha(nome_base_arquivo(nome_arquivo))
    log.info("Arquivo: %s  (base: %s)", nome_arquivo, base_planilha)

    total = 0
    xls = pd.ExcelFile(caminho)
    for aba in xls.sheet_names:
        if normalizar_nome(aba) in ignorar_abas:
            log.info("  aba '%s' ignorada (ignorar_abas)", aba)
            continue

        tabela = None
        try:
            df = pd.read_excel(xls, sheet_name=aba)
            df = tratar_dataframe(df)
            if df.empty:
                log.info("  aba '%s' vazia/sem dados úteis — pulada", aba)
                continue

            df = normalizar_colunas_dataframe(df)
            df["nm_arquivo_origem"] = nome_arquivo
            df["nm_aba_origem"] = aba
            df["dt_importacao"] = datetime.now()

            tabela = montar_nome_tabela(prefixo, base_planilha, aba)

            if dry_run:
                log.info("  [dry-run] %s.%s <- aba '%s' (%d linhas, %d colunas)",
                         schema, tabela, aba, len(df), len(df.columns) - 3)
                total += len(df)
                continue

            importar_dataframe(engine, schema, df, tabela)
            log_importacao(engine, schema, tema, nome_arquivo, aba, tabela, len(df))
            log.info("  %s.%s  <- aba '%s'  (%d linhas)", schema, tabela, aba, len(df))
            total += len(df)

        except Exception as e:  # noqa: BLE001 — registra e segue para a próxima aba
            log.exception("  ERRO na aba '%s'", aba)
            if not dry_run:
                log_importacao(engine, schema, tema, nome_arquivo, aba,
                               tabela or "", 0, status="ERRO", mensagem_erro=str(e))

    return total


def ingerir_tema(tema: str, ano: int, dry_run: bool = False, recriar_log: bool = True):
    cfg = carregar_config_tema(tema)
    cfg["tema"] = tema
    schema = cfg.get("schema_raw", "raw")

    diretorio_ano = INPUT_DIR / tema / str(ano)
    if not diretorio_ano.exists():
        raise FileNotFoundError(
            f"Diretório de entrada não encontrado: {diretorio_ano}. "
            f"Coloque as planilhas em ingestion/input/{tema}/{ano}/ antes de rodar."
        )

    arquivos = sorted(
        p for p in diretorio_ano.iterdir()
        if p.is_file()
        and p.suffix.lower() in (".xlsx", ".xls")
        and not p.name.startswith("~$")
    )
    if not arquivos:
        log.warning("Nenhuma planilha .xlsx/.xls em %s", diretorio_ano)
        return

    log.info("Tema '%s' (ano %d): %d planilha(s) encontrada(s)", tema, ano, len(arquivos))

    engine = None if dry_run else get_engine()
    if not dry_run:
        criar_schema(engine, schema)
        preparar_tabela_log(engine, schema, recriar_log)

    total = 0
    for caminho in arquivos:
        total += processar_arquivo(engine, cfg, caminho, dry_run)

    log.info("Ingestão do tema '%s' (ano %d) concluída. Linhas processadas: %d",
             tema, ano, total)


def main():
    parser = argparse.ArgumentParser(description="Ingestão de planilhas do ObservaDH")
    parser.add_argument("--tema", required=True, help="ex.: lgbtqia_plus")
    parser.add_argument("--ano", type=int, required=True, help="ano do ciclo de recebimento das planilhas")
    parser.add_argument("--dry-run", action="store_true",
                        help="lê e normaliza as planilhas sem gravar no banco")
    parser.add_argument("--manter-log", action="store_true",
                        help="não recria a tabela de log — preserva o histórico de execuções")
    args = parser.parse_args()

    try:
        ingerir_tema(args.tema, args.ano, dry_run=args.dry_run,
                     recriar_log=not args.manter_log)
    except Exception:
        log.exception("Falha na ingestão do tema '%s'", args.tema)
        sys.exit(1)


if __name__ == "__main__":
    main()
