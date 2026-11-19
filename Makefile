# Atalhos para o pipeline em Docker. Ex.:  make ciclo TEMA=lgbt ANO=2026
TEMA ?= lgbt
ANO  ?= $(shell date +%Y)
RUN  := docker compose run --rm pipeline

.PHONY: ajuda imagem ciclo ingest dry-run transforma exporta docs psql shell parar zerar-banco

ajuda:        ## lista os comandos
	@awk -F':.*## ' '/^[a-z-]+:.*## / {printf "  make %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

imagem:       ## (re)constrói a imagem — só quando mudar Dockerfile/requirements
	docker compose build

ciclo:        ## ingestão + build + exportação (TEMA, ANO)
	$(RUN) ciclo $(TEMA) $(ANO)

ingest:       ## só a ingestão (TEMA, ANO)
	$(RUN) ingest $(TEMA) $(ANO)

dry-run:      ## mostra as tabelas que a ingestão criaria, sem gravar
	$(RUN) ingest $(TEMA) $(ANO) --dry-run

transforma:   ## dbt seed + build com testes (TEMA)
	$(RUN) build $(TEMA)

exporta:      ## gera entrega/<TEMA>/<data>/
	$(RUN) exporta $(TEMA)

docs:         ## documentação/linhagem do dbt em http://localhost:8080
	docker compose run --rm --service-ports pipeline docs

psql:         ## abre o psql no banco local
	$(RUN) psql

shell:        ## terminal dentro do container
	$(RUN) shell

parar:        ## desliga o banco (os dados ficam guardados)
	docker compose down

zerar-banco:  ## APAGA o banco local para começar do zero
	docker compose down -v
