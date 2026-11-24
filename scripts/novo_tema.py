#!/usr/bin/env python3
"""Cria o esqueleto de um tema novo no pipeline do ObservaDH.

Uso (no container):  make novo-tema TEMA=psr
           ou:       docker compose run --rm pipeline novo-tema psr
Fora do container:   python scripts/novo_tema.py psr

Cria só o que ainda não existe (nunca sobrescreve):
  ingestion/temas/<tema>_config.yml        config da ingestão
  ingestion/input/<tema>/.gitkeep          pasta das planilhas (<tema>/<ano>/)
  transform/models/{staging,intermediate,marts}/<tema>/
  transform/models/staging/<tema>/_<tema>__sources.yml
  scripts/entrega/<tema>.conf / .LEIA-ME.txt / .MANIFEST-notas.txt
  docs/<tema>/catalogo-indicadores-<tema>.md
e registra a tag do tema nas 3 camadas do transform/dbt_project.yml.
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def arquivos(t: str, titulo: str) -> dict:
    return {
        f"ingestion/temas/{t}_config.yml": f"""\
# Configuração de ingestão do tema {titulo}
#
# Ingestão automática: uma tabela raw por aba de cada planilha em
# ingestion/input/{t}/<ano>/. Nome da tabela = <prefixo>_<planilha>_<aba>.
# Rode primeiro com --dry-run para ver os nomes gerados:
#   make dry-run TEMA={t} ANO=<ano>

tema: {t}

# Prefixo das tabelas raw.
prefixo_tabela: {t}

# Schema onde as tabelas brutas e a tabela de log são criadas.
schema_raw: raw

# (opcional) nome curto da parte "planilha" no nome da tabela.
# Chave = nome EXATO do arquivo. Sem isso, o nome é abreviado automaticamente.
prefixos_planilha: {{}}

# (opcional) abas que não são dado (notas, legendas, regras).
ignorar_abas: []
""",
        f"ingestion/input/{t}/.gitkeep": "",
        f"transform/models/intermediate/{t}/.gitkeep": "",
        f"transform/models/marts/{t}/.gitkeep": "",
        f"transform/models/staging/{t}/_{t}__sources.yml": f"""\
# Sources do tema {titulo} — tabelas do schema `raw` usadas pelos modelos.
# Preencha depois da primeira ingestão (os nomes saem do --dry-run).
# Exemplo:
#
# version: 2
# sources:
#   - name: raw_{t}
#     schema: raw
#     loaded_at_field: dt_importacao
#     tables:
#       - name: raw_{t}_perfil
#         identifier: {t}_perfil_<aba>
""",
        f"scripts/entrega/{t}.conf": f"""\
# Configuração da entrega do tema {titulo} — lida por scripts/exporta_entrega.sh
TITULO="indicadores {titulo}"
TABELAS=(nacional estadual municipal)          # vira {t}_indicadores_<nível>
GERA_DICIONARIO=""
EXTRAS=(                                       # copiados para a pasta da entrega
  docs/{t}/consumo-{t}_indicadores.md
  docs/{t}/dicionario-{t}_indicadores.csv
)
""",
        f"scripts/entrega/{t}.LEIA-ME.txt": f"""\
Entrega dos indicadores do relatório {titulo} — formato longo.

Tabelas:
  {t}_indicadores_nacional
  {t}_indicadores_estadual
  {t}_indicadores_municipal

(TODO: descrever as colunas de cada tabela — ver docs/{t}/)

Cada .sql tem o CREATE TABLE + os dados (COPY ... FROM stdin). Sem schema
qualificado, sem OWNER, sem GRANT. As DDLs também estão em _schema.sql.

Carregar (exemplo):
  psql -d SEU_BANCO -v ON_ERROR_STOP=1 -f {t}_indicadores_nacional.sql
""",
        f"scripts/entrega/{t}.MANIFEST-notas.txt": """\
## Chave natural de cada tabela (para PK/índice na migration)
  (TODO)
""",
        f"docs/{t}/catalogo-indicadores-{t}.md": f"""\
# Catálogo de indicadores — {titulo}

Mapeamento seção do relatório → fórmula → aba do Excel → tabela `raw` → modelo dbt.

| Seção | Indicador | Fórmula | Planilha / aba | Tabela raw | Modelo dbt |
|---|---|---|---|---|---|
""",
    }


def registra_tags(t: str) -> list[str]:
    """Adiciona `<tema>: +tags: ["<tema>"]` em staging/intermediate/marts."""
    p = RAIZ / "transform/dbt_project.yml"
    s = p.read_text(encoding="utf-8")
    feitas = []
    for camada in ("staging", "intermediate", "marts"):
        bloco = re.search(rf"^    {camada}:\n((?:      .*\n|\s*\n)*)", s, re.M)
        if not bloco:
            print(f"  (aviso: camada '{camada}' não encontrada no dbt_project.yml — adicione a tag à mão)")
            continue
        if re.search(rf"^      {t}:\s*$", bloco.group(1), re.M):
            continue
        fim = bloco.end(1)
        # mantém linhas em branco do fim do bloco depois da inserção
        while s[fim - 2:fim] == "\n\n":
            fim -= 1
        s = s[:fim] + f'      {t}:\n        +tags: ["{t}"]\n' + s[fim:]
        feitas.append(camada)
    p.write_text(s, encoding="utf-8")
    return feitas


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        return 1
    t = sys.argv[1].strip().lower()
    if not re.fullmatch(r"[a-z][a-z0-9_]{1,30}", t):
        print("ERRO: nome do tema deve ser minúsculo, sem espaço/acento (ex.: psr, pcd, pessoa_idosa).")
        return 1
    titulo = " ".join(sys.argv[2:]) or t.upper()

    print(f"Criando tema '{t}':")
    for rel, conteudo in arquivos(t, titulo).items():
        destino = RAIZ / rel
        if destino.exists():
            print(f"  já existe  {rel}")
            continue
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_text(conteudo, encoding="utf-8")
        print(f"  criado     {rel}")

    camadas = registra_tags(t)
    if camadas:
        print(f"  tag        transform/dbt_project.yml ({', '.join(camadas)})")

    print(f"""
Próximos passos:
  1. planilhas em ingestion/input/{t}/<ano>/
  2. make dry-run TEMA={t} ANO=<ano>   → nomes das tabelas raw
  3. make ingest  TEMA={t} ANO=<ano>
  4. preencher _{t}__sources.yml e escrever staging → intermediate → marts
     (o mart final se chama {t}_indicadores + views {t}_indicadores_<nível>)
  5. make transforma TEMA={t}  até os testes passarem
  6. ajustar scripts/entrega/{t}.* e rodar make exporta TEMA={t}
""")
    return 0


if __name__ == "__main__":
    sys.exit(main())
