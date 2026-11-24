#!/usr/bin/env bash
# Ponto de entrada do container do pipeline.
#   docker compose run --rm pipeline <comando> [argumentos]
set -euo pipefail
cd /app

temas() {
  # um tema existe quando tem config de ingestão: ingestion/temas/<tema>_config.yml
  local t out=()
  for t in ingestion/temas/*_config.yml; do
    [ -e "$t" ] || continue
    t="$(basename "$t")"; out+=("${t%_config.yml}")
  done
  echo "${out[*]:-nenhum}"
}

ajuda() {
  cat <<TXT
Comandos do pipeline ObservaDH:

  ciclo   <tema> <ano>   ingestão + dbt seed/build + exportação (.zip) da entrega
  ingest  <tema> <ano>   só a ingestão das planilhas (ingestion/input/<tema>/<ano>/)
                         aceita --dry-run no fim
  build   <tema>         dbt seed + dbt build --select tag:<tema> (com testes)
  exporta <tema> [dir]   gera o pacote de entrega em entrega/<tema>/<data>/ (+ .zip)
  verifica               confere banco, dbt e planilhas presentes (rode primeiro)
  novo-tema <tema>       cria o esqueleto de um tema novo (config, pastas dbt,
                         arquivos de entrega) — ver README, "Novo tema"
  docs                   gera e serve a documentação dbt em http://localhost:8080
                         (rodar com: docker compose run --rm --service-ports pipeline docs)
  dbt     <args...>      qualquer comando dbt, dentro de transform/
  psql    [args...]      abre o psql no banco local
  shell                  terminal dentro do container

Temas: $(temas)
TXT
}

garante_tema() {
  local tema="$1"
  [ -f "ingestion/temas/${tema}_config.yml" ] || {
    echo "ERRO: tema '$tema' não existe (temas: $(temas))." >&2
    echo "      Para criar: novo-tema $tema" >&2
    exit 1
  }
}

garante_deps() {
  # A pasta montada do seu computador esconde os pacotes instalados na imagem;
  # copia de lá (sem internet). Só baixa se a imagem não tiver (imagem antiga).
  [ -d transform/dbt_packages/dbt_utils ] && return 0
  if [ -d "${DBT_PACOTES_IMAGEM:-/nao-existe}" ]; then
    mkdir -p transform/dbt_packages
    cp -r "$DBT_PACOTES_IMAGEM"/. transform/dbt_packages/
  else
    (cd transform && dbt deps)
  fi
}

ingest() {
  local tema="${1:?informe o tema, ex.: lgbt}" ano="${2:?informe o ano, ex.: 2026}"
  shift 2
  garante_tema "$tema"
  local dir="ingestion/input/$tema/$ano"
  if ! ls "$dir"/*.xls* >/dev/null 2>&1; then
    echo "ERRO: nenhuma planilha (.xlsx/.xls) em $dir/" >&2
    echo "      Coloque as planilhas do ciclo nessa pasta e rode de novo." >&2
    exit 1
  fi
  echo "==> Ingestão: tema=$tema ano=$ano"
  python ingestion/ingest.py --tema "$tema" --ano "$ano" "$@"
}

build() {
  local tema="${1:?informe o tema, ex.: lgbt}"
  shift
  garante_tema "$tema"
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

verifica() {
  local ok=0
  echo "==> Banco ($PGHOST:$PGPORT/$PGDATABASE)"
  if pg_isready -q; then echo "  ok  respondendo"; else echo "  ERRO  banco não responde"; ok=1; fi
  echo "==> Ferramentas"
  echo "  python $(python --version 2>&1 | cut -d' ' -f2) | $(dbt --version 2>/dev/null | grep -m1 -i 'installed' | sed 's/^ *- *//') | $(pg_dump --version)"
  echo "==> dbt"
  garante_deps
  # --connection: testa só a conexão (o debug completo exige git, que o
  # container não precisa — os commits são feitos no seu computador)
  if (cd transform && dbt debug --connection >/tmp/dbt_debug.log 2>&1); then echo "  ok  conexão do dbt com o banco"
  else echo "  ERRO  conexão do dbt:"; tail -15 /tmp/dbt_debug.log | sed 's/^/        /'; ok=1; fi
  if (cd transform && dbt parse --quiet >/tmp/dbt_parse.log 2>&1); then echo "  ok  projeto dbt válido (modelos, sources, testes)"
  else echo "  ERRO  projeto dbt:"; tail -15 /tmp/dbt_parse.log | sed 's/^/        /'; ok=1; fi
  echo "==> Planilhas por tema/ano"
  local t d n
  for t in $(temas); do
    for d in ingestion/input/"$t"/*/; do
      [ -d "$d" ] || continue
      n=$(find "$d" -maxdepth 1 -name '*.xls*' | wc -l | tr -d ' ')
      printf '  %-8s %-6s %s planilha(s)\n' "$t" "$(basename "$d")" "$n"
    done
  done
  [ $ok -eq 0 ] && echo "Tudo certo." || { echo "Há problemas acima."; exit 1; }
}

cmd="${1:-ajuda}"
if [ $# -gt 0 ]; then shift; fi

case "$cmd" in
  ajuda|-h|--help) ajuda ;;
  ingest)  ingest "$@" ;;
  build)   build "$@" ;;
  exporta) exporta "$@" ;;
  verifica) verifica ;;
  novo-tema) exec python scripts/novo_tema.py "$@" ;;
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
  *) echo "Comando desconhecido: $cmd" >&2; echo >&2; ajuda >&2; exit 1 ;;
esac
