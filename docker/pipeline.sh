#!/usr/bin/env bash
# Ponto de entrada do container do pipeline.
#   docker compose run --rm pipeline <comando> [argumentos]
set -euo pipefail
cd /app

ajuda() {
  cat <<'TXT'
Comandos do pipeline ObservaDH:

  ciclo   <tema> <ano>   ingestão + dbt seed/build + exportação da entrega
  ingest  <tema> <ano>   só a ingestão das planilhas (ingestion/input/<tema>/<ano>/)
                         aceita --dry-run no fim
  build   <tema>         dbt seed + dbt build --select tag:<tema> (com testes)
  exporta <tema> [dir]   gera o pacote de entrega em entrega/<tema>/<data>/
  docs                   gera e serve a documentação dbt em http://localhost:8080
                         (rodar com: docker compose run --rm --service-ports pipeline docs)
  dbt     <args...>      qualquer comando dbt, dentro de transform/
  psql    [args...]      abre o psql no banco local
  shell                  terminal dentro do container

Temas: lgbt, ici
TXT
}

garante_deps() {
  # a pasta montada do seu computador pode não ter o dbt_utils ainda
  [ -d transform/dbt_packages/dbt_utils ] || (cd transform && dbt deps)
}

ingest() {
  local tema="${1:?informe o tema, ex.: lgbt}" ano="${2:?informe o ano, ex.: 2026}"
  shift 2
  echo "==> Ingestão: tema=$tema ano=$ano"
  python ingestion/ingest.py --tema "$tema" --ano "$ano" "$@"
}

build() {
  local tema="${1:?informe o tema, ex.: lgbt}"
  shift
  garante_deps
  echo "==> dbt seed + build: tag:$tema"
  (cd transform && dbt seed && dbt build --select "tag:$tema" "$@")
}

exporta() {
  local tema="${1:?informe o tema, ex.: lgbt}"
  shift
  echo "==> Exportação da entrega: $tema"
  bash scripts/exporta_entrega.sh "$tema" "$@"
}

cmd="${1:-ajuda}"
if [ $# -gt 0 ]; then shift; fi

case "$cmd" in
  ajuda|-h|--help) ajuda ;;
  ingest)  ingest "$@" ;;
  build)   build "$@" ;;
  exporta) exporta "$@" ;;
  ciclo)
    tema="${1:?informe o tema, ex.: lgbt}"; ano="${2:?informe o ano, ex.: 2026}"
    ingest "$tema" "$ano"
    build "$tema"
    exporta "$tema"
    echo "==> Ciclo concluído: $tema $ano"
    ;;
  docs)
    garante_deps
    cd transform && dbt docs generate && exec dbt docs serve --host 0.0.0.0 --port 8080 --no-browser
    ;;
  dbt)   garante_deps; cd transform && exec dbt "$@" ;;
  psql)  exec psql "$@" ;;
  shell|bash) exec bash ;;
  *) exec "$cmd" "$@" ;;
esac
