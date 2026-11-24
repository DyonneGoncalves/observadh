#!/usr/bin/env bash
# Gera o pacote de entrega de um tema para o dev: dump SQL puro de cada tabela
# final (<tema>_indicadores_<nível>), um schema-only combinado, os documentos
# de consumo e um MANIFEST com contagem + md5.
#
# O dev usa o CREATE TABLE de cada arquivo para gerar a migration e o COPY
# para popular. O schema qualifier (dev_marts.) é removido — as tabelas
# entram no search_path de destino que ele escolher.
#
# Uso:
#   scripts/exporta_entrega.sh <tema> [DIR_SAIDA]
#   ex.: scripts/exporta_entrega.sh ici
#
# Cada tema tem, em scripts/entrega/:
#   <tema>.conf               título, níveis, documentos a copiar
#   <tema>.LEIA-ME.txt        LEIA-ME que vai na pasta da entrega
#   <tema>.MANIFEST-notas.txt chave natural + observações (fim do MANIFEST)
# Novo tema = criar esses 3 arquivos, sem mexer neste script.
#
# Conexão: variáveis padrão do libpq (PGHOST/PGPORT/PGDATABASE/PGUSER/
# PGPASSWORD) ou, se não houver, o banco local "observadh".
set -euo pipefail

TEMA="${1:?uso: scripts/exporta_entrega.sh <tema> [DIR_SAIDA]}"
CONF_DIR="scripts/entrega"
CONF="$CONF_DIR/${TEMA}.conf"
[ -f "$CONF" ] || { echo "ERRO: não existe $CONF (temas: $(ls $CONF_DIR/*.conf | xargs -n1 basename | sed 's/\.conf//' | tr '\n' ' '))" >&2; exit 1; }

TITULO=""; TABELAS=(); EXTRAS=(); GERA_DICIONARIO=""
# shellcheck source=/dev/null
source "$CONF"

PG_BIN="/opt/homebrew/opt/postgresql@17/bin"
[ -d "$PG_BIN" ] && export PATH="$PG_BIN:$PATH"

DB="${PGDATABASE:-observadh}"
SCHEMA="${OBSERVADH_MARTS_SCHEMA:-dev_marts}"
SAIDA="${2:-entrega/${TEMA}/$(date +%Y-%m-%d)}"

# 1) tira o qualificador de schema (com/sem aspas)
# 2) tira as meta-linhas \restrict/\unrestrict (só psql novo)
# 3) neutraliza o "search_path vazio" do pg_dump: sem ele as tabelas
#    entram no search_path de destino (public, por padrão)
limpa() {
  sed -e "s/\"${SCHEMA}\"\.//g" -e "s/${SCHEMA}\.//g" \
      -e '/^\\restrict /d' -e '/^\\unrestrict /d' \
      -e "/SELECT pg_catalog.set_config('search_path'/d"
}

mkdir -p "$SAIDA"
echo "Tema:    $TEMA"
echo "Banco:   $DB"
echo "Schema:  $SCHEMA"
echo "Saída:   $SAIDA"
echo

# --- 0. confere se as tabelas existem (falha cedo, antes de gerar meia entrega)
for t in "${TABELAS[@]}"; do
  rel="${SCHEMA}.${TEMA}_indicadores_${t}"
  existe=$(psql -d "$DB" -tAc "select to_regclass('${rel}') is not null")
  [ "$existe" = "t" ] || { echo "ERRO: $rel não existe — rode o build do tema antes." >&2; exit 1; }
done

# --- 1. dump completo (estrutura + dados), um arquivo por tabela -------------
args_schema=()
for t in "${TABELAS[@]}"; do
  rel="${SCHEMA}.${TEMA}_indicadores_${t}"
  out="$SAIDA/${TEMA}_indicadores_${t}.sql"
  pg_dump -d "$DB" --no-owner --no-privileges --no-tablespaces \
          --quote-all-identifiers -t "$rel" \
    | limpa \
    > "$out"
  echo "  ok  $out"
  args_schema+=(-t "$rel")
done

# --- 2. schema-only combinado (todas as DDLs juntas) -----------------------
pg_dump -d "$DB" --no-owner --no-privileges --no-tablespaces --schema-only \
        --quote-all-identifiers "${args_schema[@]}" \
  | limpa \
  > "$SAIDA/_schema.sql"
echo "  ok  $SAIDA/_schema.sql"

# --- 3. documentos de consumo + leia-me ------------------------------------
if [ -n "$GERA_DICIONARIO" ] && [ -f "$GERA_DICIONARIO" ]; then
  dic=$(printf '%s\n' "${EXTRAS[@]}" | grep 'dicionario' || true)
  if [ -n "$dic" ] && [ ! -f "$dic" ]; then
    python3 "$GERA_DICIONARIO" || echo "  (aviso: não gerou o dicionário)"
  fi
fi
for f in "${EXTRAS[@]}"; do
  if [ -f "$f" ]; then
    cp "$f" "$SAIDA/" && echo "  ok  $SAIDA/$(basename "$f")"
  else
    echo "  (aviso: $f não encontrado — não foi incluído)"
  fi
done

cp "$CONF_DIR/${TEMA}.LEIA-ME.txt" "$SAIDA/LEIA-ME.txt"
echo "  ok  $SAIDA/LEIA-ME.txt"

# --- 4. MANIFEST (contagem + md5 para conferência de carga) -----------------
{
  echo "# Entrega — ${TITULO}"
  echo "# Gerado em $(date '+%Y-%m-%d %H:%M:%S') a partir de ${DB}.${SCHEMA}"
  echo
  echo "## Contagem de linhas (confira depois de carregar)"
  for t in "${TABELAS[@]}"; do
    n=$(psql -d "$DB" -tAc "select count(*) from ${SCHEMA}.${TEMA}_indicadores_${t}")
    printf '  %-27s %s\n' "${TEMA}_indicadores_${t}" "$n"
  done
  echo
  echo "## Arquivos (md5)"
  for f in "$SAIDA"/*.sql; do
    case "$(basename "$f")" in query-*) continue ;; esac   # só os dumps
    printf '  %-36s %s\n' "$(basename "$f")" "$(md5 -q "$f" 2>/dev/null || md5sum "$f" | cut -d' ' -f1)"
  done
  echo
  [ -f "$CONF_DIR/${TEMA}.MANIFEST-notas.txt" ] && cat "$CONF_DIR/${TEMA}.MANIFEST-notas.txt"
} > "$SAIDA/MANIFEST.txt"
echo "  ok  $SAIDA/MANIFEST.txt"

# --- 5. compacta (é o .zip que vai para o dev) ------------------------------
echo
if command -v zip >/dev/null 2>&1; then
  ( cd "$(dirname "$SAIDA")" && rm -f "$(basename "$SAIDA").zip" \
      && zip -qr "$(basename "$SAIDA").zip" "$(basename "$SAIDA")" -x '*.DS_Store' )
  echo "Pronto: ${SAIDA}.zip"
else
  echo "Pronto. Compacte com:  (cd $(dirname "$SAIDA") && zip -r $(basename "$SAIDA").zip $(basename "$SAIDA"))"
fi
