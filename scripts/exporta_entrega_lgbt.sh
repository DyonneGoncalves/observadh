#!/usr/bin/env bash
# Gera o pacote de entrega para o dev: dump SQL puro das 3 tabelas finais do
# relatório LGBTQIA+ (nacional / estadual / municipal), uma por arquivo, mais
# um schema-only combinado, um MANIFEST com contagem + md5, e o contrato.
#
# O dev usa o CREATE TABLE de cada arquivo para gerar a migration e o COPY
# para popular. O schema qualifier (dev_marts.) é removido — as tabelas
# entram no search_path de destino que ele escolher.
#
# Uso:
#   scripts/exporta_entrega_lgbt.sh [DIR_SAIDA]
#
# Conexão: usa as variáveis padrão do libpq (PGHOST/PGPORT/PGDATABASE/PGUSER/
# PGPASSWORD) ou, se não houver, o banco local "observadh".
set -euo pipefail

PG_BIN="/opt/homebrew/opt/postgresql@17/bin"
[ -d "$PG_BIN" ] && export PATH="$PG_BIN:$PATH"

DB="${PGDATABASE:-observadh}"
SCHEMA="${OBSERVADH_MARTS_SCHEMA:-dev_marts}"
SAIDA="${1:-entrega/lgbt/$(date +%Y-%m-%d)}"
TABELAS=(nacional estadual municipal)

# remove o qualificador de schema (com ou sem aspas) e as meta-linhas
# \restrict/\unrestrict que só existem em versões novas do psql.
limpa() {
  # 1) tira o qualificador de schema (com/sem aspas)
  # 2) tira as meta-linhas \restrict/\unrestrict (só psql novo)
  # 3) neutraliza o "search_path vazio" do pg_dump: sem ele as tabelas
  #    entram no search_path de destino (public, por padrão)
  sed -e "s/\"${SCHEMA}\"\.//g" -e "s/${SCHEMA}\.//g" \
      -e '/^\\restrict /d' -e '/^\\unrestrict /d' \
      -e "/SELECT pg_catalog.set_config('search_path'/d"
}

mkdir -p "$SAIDA"
echo "Banco:   $DB"
echo "Schema:  $SCHEMA"
echo "Saída:   $SAIDA"
echo

# --- 1. dump completo (estrutura + dados), um arquivo por tabela -------------
for t in "${TABELAS[@]}"; do
  rel="${SCHEMA}.lgbt_indicadores_${t}"
  out="$SAIDA/lgbt_indicadores_${t}.sql"
  pg_dump -d "$DB" --no-owner --no-privileges --no-tablespaces \
          --quote-all-identifiers -t "$rel" \
    | limpa \
    > "$out"
  echo "  ok  $out"
done

# --- 2. schema-only combinado (as 3 DDLs juntas) ---------------------------
pg_dump -d "$DB" --no-owner --no-privileges --no-tablespaces --schema-only \
        --quote-all-identifiers \
        -t "${SCHEMA}.lgbt_indicadores_nacional" \
        -t "${SCHEMA}.lgbt_indicadores_estadual" \
        -t "${SCHEMA}.lgbt_indicadores_municipal" \
  | limpa \
  > "$SAIDA/_schema.sql"
echo "  ok  $SAIDA/_schema.sql"

# --- 3. contrato + dicionário + leia-me ------------------------------------
cp docs/lgbt/consumo-lgbt_indicadores.md "$SAIDA/"
echo "  ok  $SAIDA/consumo-lgbt_indicadores.md"

if [ ! -f docs/lgbt/dicionario-lgbt_indicadores.csv ]; then
  python3 scripts/gera_dicionario_lgbt.py || echo "  (aviso: não gerou o dicionário)"
fi
[ -f docs/lgbt/dicionario-lgbt_indicadores.csv ] && \
  cp docs/lgbt/dicionario-lgbt_indicadores.csv "$SAIDA/" && \
  echo "  ok  $SAIDA/dicionario-lgbt_indicadores.csv"

cat > "$SAIDA/LEIA-ME.txt" <<'TXT'
Entrega dos indicadores do relatório LGBTQIA+ — formato longo.

3 tabelas (uma linha por indicador x recorte x categoria x ano):
  lgbt_indicadores_nacional   — sem coluna de recorte
  lgbt_indicadores_estadual   — uf_codigo (IBGE 2 díg) + uf_nome
  lgbt_indicadores_municipal  — municipio_codigo_ibge (IBGE 7 díg) + municipio_nome

Cada .sql tem o CREATE TABLE + os dados (COPY ... FROM stdin). Sem schema
qualificado: as tabelas entram no search_path de destino (public por padrão).
Sem OWNER, sem GRANT. As DDLs também estão isoladas em _schema.sql.

Carregar (exemplo):
  psql -d SEU_BANCO -v ON_ERROR_STOP=1 -f lgbt_indicadores_nacional.sql
  psql -d SEU_BANCO -v ON_ERROR_STOP=1 -f lgbt_indicadores_estadual.sql
  psql -d SEU_BANCO -v ON_ERROR_STOP=1 -f lgbt_indicadores_municipal.sql

Depois confira as contagens contra o MANIFEST.txt.

A consulta que a aplicação roda (1 por relatório), como virar as linhas num
mapa chave->valor e fazer o bind no template: ver consumo-lgbt_indicadores.md.

dicionario-lgbt_indicadores.csv = 1 linha por indicador (seção, chave de bind,
categorias, tipo, unidade, níveis, ano, descrição). É o de-para texto<->chave.

Chave natural (para PK/índice na migration): ver MANIFEST.txt.
TXT
echo "  ok  $SAIDA/LEIA-ME.txt"

# --- 4. MANIFEST (contagem + md5 para conferência de carga) -----------------
{
  echo "# Entrega — indicadores LGBTQIA+ (formato longo)"
  echo "# Gerado em $(date '+%Y-%m-%d %H:%M:%S') a partir de ${DB}.${SCHEMA}"
  echo
  echo "## Contagem de linhas (confira depois de carregar)"
  for t in "${TABELAS[@]}"; do
    n=$(psql -d "$DB" -tAc "select count(*) from ${SCHEMA}.lgbt_indicadores_${t}")
    printf '  lgbt_indicadores_%-10s %s\n' "$t" "$n"
  done
  echo
  echo "## Arquivos (md5)"
  for f in "$SAIDA"/*.sql; do
    printf '  %-36s %s\n' "$(basename "$f")" "$(md5 -q "$f" 2>/dev/null || md5sum "$f" | cut -d' ' -f1)"
  done
  echo
  echo "## Chave natural de cada tabela (para PK/índice na migration)"
  echo "  nacional : (secao, indicador, categoria, ano_referencia)"
  echo "  estadual : (uf_codigo, secao, indicador, categoria, ano_referencia)"
  echo "  municipal: (municipio_codigo_ibge, secao, indicador, categoria, ano_referencia)"
  echo "  categoria pode ser NULL -> use um índice único com NULLS NOT DISTINCT (PG15+)"
  echo "  ou trate NULL como '' na PK."
} > "$SAIDA/MANIFEST.txt"
echo "  ok  $SAIDA/MANIFEST.txt"

echo
echo "Pronto. Compacte com:  (cd $(dirname "$SAIDA") && zip -r $(basename "$SAIDA").zip $(basename "$SAIDA"))"
