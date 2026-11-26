# Instalação do ambiente

Feito **uma vez** por máquina. Depois disso, cada ciclo anual é só o
[Ciclo anual de atualização](/Relatórios-Observa-DH/Arquitetura-de-Dados/Ciclo-anual-de-atualização).

## Pré-requisitos

| Item | Observação |
|---|---|
| **Docker Desktop** | Precisa estar aberto sempre que for rodar o pipeline. |
| **Git** | Para clonar o repositório e versionar ajustes. |
| **Acesso ao repositório** | `<URL do repositório no git do MDHC>` |
| Editor (opcional) | VS Code ou outro, para ajustar modelos SQL e configurações. |
| Cliente de banco (opcional) | DBeaver ou pgAdmin, para consultar o banco local. |

Não é preciso instalar Python, dbt nem Postgres: tudo roda dentro do Docker.

## Passo a passo

**1. Clonar o repositório**

```bash
git clone <URL do repositório no git do MDHC> observadh
cd observadh
```

**2. (Opcional) Ajustar usuário, senha ou porta do banco local**

```bash
cp .env.example .env     # e edite o .env se precisar
```

Padrão: banco `observadh`, usuário e senha `observadh`, porta `5433` no seu
computador. O banco é só local e não guarda nada de produção.

Em rede institucional que bloqueia o Docker Hub, aponte as imagens base para o
registro interno no `.env` (`PYTHON_IMAGE`, `POSTGRES_IMAGE`). Os exemplos
estão no `.env.example`.

**3. Construir a imagem**

```bash
make imagem
```

Baixa e monta tudo (Python, dbt, cliente Postgres e pacotes do dbt). Só
precisa de internet nesta etapa. Refaça só se mudarem o `Dockerfile` ou o
`requirements.txt`.

**4. Conferir**

```bash
make verifica
```

Resultado esperado: `ok` para o banco, para a conexão do dbt e para o projeto
dbt, seguido da lista de planilhas por temática e ano, e por fim `Tudo certo.`

## Comandos do dia a dia

| Comando | O que faz |
|---|---|
| `make ciclo TEMA=<t> ANO=<a>` | ingestão + transformação + testes + pacote de entrega |
| `make dry-run TEMA=<t> ANO=<a>` | mostra as tabelas que a ingestão criaria, sem gravar |
| `make ingest TEMA=<t> ANO=<a>` | só a ingestão |
| `make transforma TEMA=<t>` | só a transformação e os testes (dbt) |
| `make exporta TEMA=<t>` | só o pacote de entrega |
| `make docs` | documentação e linhagem do dbt (http://localhost:8080) |
| `make psql` | terminal SQL no banco local |
| `make parar` | desliga o banco (os dados ficam guardados) |
| `make zerar-banco` | apaga o banco local para recomeçar do zero |

Sem `make` (ex.: Windows sem make), use `docker compose run --rm pipeline <comando>`.
Exemplo: `docker compose run --rm pipeline ciclo psr 2026`.

Banco local no DBeaver/pgAdmin: `localhost:5433`, banco `observadh`.
