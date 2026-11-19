# Imagem do pipeline do ObservaDH: Python (ingestão) + dbt (transformação)
# + cliente Postgres 17 (pg_dump/psql para gerar a entrega).
# O banco NÃO fica nesta imagem — sobe como serviço separado no docker-compose.
FROM python:3.13-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DBT_PROFILES_DIR=/app/docker \
    DBT_SEND_ANONYMOUS_USAGE_STATS=false

# Cliente Postgres 17 (o Debian traz o 15, que não consegue fazer pg_dump de
# um servidor 17). Vem do repositório oficial do PostgreSQL (PGDG).
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates postgresql-common \
 && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
 && apt-get install -y --no-install-recommends postgresql-client-17 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY docker/requirements.txt docker/requirements.txt
RUN pip install -r docker/requirements.txt

# Código do projeto (planilhas e entregas ficam de fora — ver .dockerignore;
# no uso normal o repositório inteiro é montado em /app pelo docker-compose).
COPY . .
RUN cd transform && dbt deps \
 && chmod +x docker/pipeline.sh

ENTRYPOINT ["/app/docker/pipeline.sh"]
CMD ["ajuda"]
