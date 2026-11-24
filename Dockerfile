# Imagem do pipeline do ObservaDH: Python (ingestão) + dbt (transformação)
# + cliente Postgres 17 (pg_dump/psql para gerar a entrega).
# O banco NÃO fica nesta imagem — sobe como serviço separado no docker-compose.
#
# Rede institucional: se o Docker Hub ou o apt.postgresql.org forem bloqueados,
# aponte para o registro/espelho interno sem editar este arquivo:
#   docker compose build --build-arg PYTHON_IMAGE=registro.interno/python:3.13-slim-bookworm
# (ou defina PYTHON_IMAGE / POSTGRES_IMAGE no .env — ver .env.example)
ARG PYTHON_IMAGE=python:3.13-slim-bookworm
FROM ${PYTHON_IMAGE}

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DBT_PROFILES_DIR=/app/docker \
    DBT_SEND_ANONYMOUS_USAGE_STATS=false \
    DBT_PACOTES_IMAGEM=/opt/observadh/dbt_packages

# Cliente Postgres 17 (o Debian traz o 15, que não consegue fazer pg_dump de
# um servidor 17) — vem do repositório oficial do PostgreSQL (PGDG).
# zip: para compactar o pacote de entrega no fim do ciclo.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates postgresql-common zip \
 && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
 && apt-get install -y --no-install-recommends postgresql-client-17 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Código do projeto (planilhas e entregas ficam de fora — ver .dockerignore).
# No uso normal o repositório inteiro é montado em /app pelo docker-compose,
# então o que vale é o código do seu computador; esta cópia serve para a
# imagem também funcionar sozinha (ex.: CI, ou rodar sem montar a pasta).
COPY . .

# Pacotes dbt (dbt_utils) baixados AGORA, no build, e guardados fora de /app:
# como /app é sobrescrito pela pasta montada, o pipeline.sh copia daqui —
# assim rodar o pipeline não depende de internet.
RUN cd /app/transform \
 && dbt deps \
 && mkdir -p "$(dirname "$DBT_PACOTES_IMAGEM")" \
 && cp -r dbt_packages "$DBT_PACOTES_IMAGEM"

# Chamado via bash: não depende do bit de execução do arquivo no computador
# de quem montou a pasta (Windows/zip perdem esse bit).
ENTRYPOINT ["bash", "/app/docker/pipeline.sh"]
CMD ["ajuda"]
