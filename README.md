# ObservaDH — Camada de Dados (v2)

Este repositório contém a camada de dados do ObservaDH: leitura das planilhas recebidas, transformação e disponibilização dos indicadores finais para a aplicação.

> **Temas no pipeline:** LGBTQIA+, ICI e PSR. Próximos: PI e PCD.
>
> **Roteiro de operação** (instalação, ciclo anual, padrão das planilhas, entrega e uma página por temática): `docs/wiki/`, a fonte das páginas publicadas na wiki do projeto.

## Estrutura

```
observadh/
├── ingestion/          # Python — importa TODA aba de TODA planilha para o schema raw
│   ├── input/           # planilhas recebidas, organizadas por tema/ano
│   └── temas/            # um arquivo de configuração por tema (prefixo de tabela, schema, abas a ignorar)
│
└── transform/           # projeto dbt — staging → intermediate → marts
    ├── seeds/            # tabelas de referência compartilhadas entre temas (UF, município...)
    ├── macros/           # regras reutilizáveis entre temas (cálculo de %, agregações...)
    ├── models/
    │   ├── staging/       # 1 modelo por aba/planilha de origem — limpeza e tipagem, sem regra de negócio
    │   ├── intermediate/  # cálculo dos indicadores
    │   └── marts/         # tabela final única lgbt_indicadores (formato longo) + 3 views por nível
    └── tests/            # testes customizados de validação (fonte vs. calculado)
```

Ver a proposta completa de arquitetura em `proposta-arquitetura-observadh.md` (na raiz do projeto Claude) para o racional por trás dessas decisões.

O mapeamento completo **seção do relatório → fórmula → aba do Excel → tabela `raw` → modelo dbt** está em [`docs/lgbt/catalogo-indicadores-lgbt.md`](docs/lgbt/catalogo-indicadores-lgbt.md), junto com os 6 documentos-fonte da equipe (3 de cálculo + 3 de texto-base do relatório) e as inconsistências pendentes de decisão. Para a aplicação, o guia de consumo da tabela final está em [`docs/lgbt/consumo-lgbt_indicadores.md`](docs/lgbt/consumo-lgbt_indicadores.md).

## Como rodar um ciclo (quando os dados do tema estiverem prontos)

```bash
# 0. Uma vez só (fora do Docker): instalar as dependências
pip install -r requirements.txt

# 1. Colocar as planilhas em ingestion/input/<tema>/<ano>/  (o "ano" = ciclo de recebimento)

# 2. Rodar a ingestão (Python) — importa TODA aba de TODA planilha para o schema raw.
#    Cada execução recria as tabelas do zero. Use --dry-run para ver os nomes
#    de tabela gerados sem gravar; --manter-log para preservar o histórico de execuções.
python ingestion/ingest.py --tema lgbt --ano 2026

# 3. Rodar a transformação (dbt) — recalcula staging → intermediate → marts e roda os testes
cd transform
dbt deps   # instala dbt-utils (usado nos testes de schema)
dbt seed   # carrega as tabelas de referência (dim_municipio, dim_uf)
dbt build --select tag:lgbt

# 4. Conferir o grafo de linhagem e a documentação
dbt docs generate && dbt docs serve
```

Conexão com o banco: variáveis `OBSERVADH_DB_HOST/_PORT/_NAME/_USER/_PASSWORD`
(a ingestão também aceita `DATABASE_URL`) e `transform/profiles.yml.example`
copiado para `~/.dbt/profiles.yml`.

## Rodando com Docker (forma recomendada)

Não precisa instalar Python, dbt nem Postgres — só o **Docker Desktop**. O
container traz tudo (Python + dbt + cliente Postgres 17) e sobe um **Postgres
local** só para o pipeline. O produto final continua sendo o pacote em
`entrega/<tema>/<data>/` (dump das tabelas finais), que vai para produção.

```bash
# uma vez só: construir a imagem (refazer só se mudar Dockerfile/requirements)
make imagem
make verifica        # confere banco, dbt e quais planilhas estão na pasta

# a cada ciclo:
# 1. colocar as planilhas em ingestion/input/<tema>/<ano>/
# 2. rodar tudo: ingestão → dbt seed/build (com testes) → exportação
make ciclo TEMA=lgbt ANO=2026
```

Os testes do dbt rodam dentro do `build`: se algum falhar, o ciclo para antes
da exportação. Ajuste o modelo `.sql` (no seu editor, normalmente — o
repositório está montado dentro do container), rode `make transforma TEMA=lgbt`
até ficar verde, depois `make exporta TEMA=lgbt` e comite o ajuste.

| Comando | O que faz |
|---|---|
| `make ciclo TEMA= ANO=` | ingestão + build + exportação |
| `make dry-run TEMA= ANO=` | mostra as tabelas `raw` que seriam criadas, sem gravar |
| `make ingest TEMA= ANO=` | só a ingestão |
| `make transforma TEMA=` | `dbt seed` + `dbt build --select tag:<tema>` |
| `make exporta TEMA=` | gera `entrega/<tema>/<data>/` e o `.zip` que vai para o dev |
| `make verifica` | confere banco, dbt e planilhas presentes |
| `make novo-tema TEMA=` | cria o esqueleto de um tema novo (ver abaixo) |
| `make docs` | linhagem/documentação dbt em http://localhost:8080 |
| `make psql` / `make shell` | psql no banco local / terminal no container |
| `make parar` / `make zerar-banco` | desliga o banco / apaga o banco para recomeçar |

Sem `make`: `docker compose run --rm pipeline ciclo lgbt 2026` (o comando
`docker compose run --rm pipeline` sem argumentos lista as opções).

A exportação é a mesma para todos os temas (`scripts/exporta_entrega.sh <tema>`).
O que muda por tema (níveis, documentos que vão junto, LEIA-ME e notas do
MANIFEST) fica em `scripts/entrega/<tema>.*`; para um tema novo, basta criar
esses arquivos.

Para abrir o banco no DBeaver: `localhost:5433`, banco `observadh`, usuário e
senha `observadh` (padrões em `.env.example`; copie para `.env` para mudar).
Os dados ficam no volume `pgdata` entre execuções. Arquivos do container:
`Dockerfile`, `docker-compose.yml`, `Makefile`, `docker/`, `requirements.txt`
(lista única de dependências, com versões fixadas).

Rodar o pipeline **não precisa de internet**: tudo (inclusive o pacote
`dbt_utils`) é baixado só no `make imagem`. Se a rede bloquear o Docker Hub ou
o repositório do PostgreSQL nesse momento, aponte as imagens base para o
registro interno com `PYTHON_IMAGE` / `POSTGRES_IMAGE` no `.env` (exemplo em
`.env.example`).

## Novo tema (PI, PCD e os próximos)

Todo tema segue o mesmo padrão; o esqueleto é criado por um comando:

```bash
make novo-tema TEMA=pi
```

Isso cria (sem sobrescrever nada que já exista) a config de ingestão
(`ingestion/temas/pi_config.yml`), a pasta das planilhas
(`ingestion/input/pi/`), as pastas `staging/intermediate/marts/pi/` com um
`sources.yml` modelo, os arquivos de entrega (`scripts/entrega/pi.*`), um
catálogo em branco (`docs/pi/`) e registra a tag `pi` no `dbt_project.yml`.
Depois:

1. planilhas em `ingestion/input/pi/<ano>/` e `make dry-run TEMA=pi ANO=<ano>`
   para ver os nomes das tabelas `raw`;
2. `make ingest TEMA=pi ANO=<ano>`;
3. preencher `_pi__sources.yml` e escrever os modelos, seguindo o LGBTQIA+, o
   ICI e o PSR como referência: staging (limpeza) → intermediate (regras dos
   indicadores, um modelo por seção) → mart `pi_indicadores` + tabelas
   `pi_indicadores_<nível>`;
4. teste de valores em `transform/tests/` contra os números validados pela área
   (planilha de cálculo ou relatório aprovado);
5. `make transforma TEMA=pi` até ficar verde, ajustar `scripts/entrega/pi.*`
   e `make exporta TEMA=pi`.

## Status LGBTQIA+

- [x] **Todas as 8 planilhas ingeridas** — 54 tabelas no schema `raw` (toda aba de todo arquivo), 234.557 linhas, via descoberta automática (`ingestion/ingest.py`)
- [x] Sources dbt (`_lgbt__sources.yml`) — apontam para o schema `raw` via `identifier`
- [x] **Seção 6.1 — Proteção Social Especial** (piloto) — nos 3 níveis, migrada para o **formato longo** (`int_lgbt_6_1_protecao_social_especial`). Testes contra o % pré-calculado da planilha.
- [x] **Formato longo** — mart único `lgbt_indicadores` (uma linha por nivel × recorte × seção × indicador × categoria) + views `_nacional`/`_estadual`/`_municipal`. Cada (sub)seção é um `int_lgbt_<secao>_*`.
- [x] **Seção 5.1 — Serviços de saúde para pessoas trans** (N, E) no formato longo. Validada contra a planilha de cálculo da equipe.
- [x] **Seção 2.5 — Casamentos e uniões** (N, E, M; parte PNS só N) no formato longo. Validada contra a planilha de cálculo e contra o texto-base do relatório.
- [x] **Seção 4.1 — Projetos escolares contra LGBTQIAfobia** (N, E) no formato longo. Validada contra a planilha de cálculo.
- [x] **Seção 7.1 — Denúncias de violações de DH (ONDH)** (N, E, M) no formato longo. Validada contra a planilha de cálculo. Falta local e relação do suspeito.
- [x] **Seção 7.0 — Notificações de violência (SINAN)** (N, E, M) no formato longo. Validada. Falta local e perfil do agressor.
- [x] **Seções 1, 2, 3, 4 e 5 (PNS 2019 / Censo)** no formato longo, só nacional para as partes de perfil. Validadas contra a planilha de cálculo e o texto-base do relatório.
- [x] **Abertura da seção 6** (CRAS/Centros de Convivência) + **extras de 7.0/7.1** (local de ocorrência, perfil do agressor, relação do suspeito) no formato longo. Validados contra a planilha de cálculo.
- [x] `dbt build --select tag:lgbt` — tudo verde (49 nós). **`lgbt_indicadores`: ~595k linhas.** O relatório LGBTQIA+ está completo no formato longo (falta só a 2.5 "% casamentos mesmo sexo por estado", de denominador ambíguo).

## Status ICI (Índice de Capacidade Institucional)

> **Diferente do LGBTQIA+**: as planilhas do ICI já chegam com o índice final calculado (0 a 1) por território/ano/subíndice — não há regra de cálculo de indicador para implementar, só padronização de schema e cálculo das médias de comparação que o relatório pede. Ver [`docs/ici/catalogo-indicadores-ici.md`](docs/ici/catalogo-indicadores-ici.md).

- [x] **Catálogo de indicadores** — mapeamento das 3 planilhas (Estadual, Municipal 2014/2019, Municipal 2023) e dos 3 `Filtro_*_V1.docx`, com 12 inconsistências documentadas.
- [x] **Ingestão configurada** (`ingestion/temas/ici_config.yml`) e as 3 planilhas copiadas para `ingestion/input/ici/2026/`.
- [x] **Staging** — 1 modelo por sub-índice × nível (`stg_ici_estadual_{dh,ca,lgbtqia,pcd,pi}`, `stg_ici_municipal_{dh,ca,lgbtqia,pcd,pi}`).
- [x] **Intermediate** — `int_ici_estadual` / `int_ici_municipal`: junção com `dim_uf`/`dim_municipio`, média nacional, média do grupo de comparação (região no estadual, UF no municipal) e classificação via macro `classifica_ici`.
- [x] **Mart** — `ici_indicadores` (formato longo) + views `ici_indicadores_estadual` / `ici_indicadores_municipal`. Guia de consumo em [`docs/ici/consumo-ici_indicadores.md`](docs/ici/consumo-ici_indicadores.md).
- [x] **Testes** — `not_null`/`accepted_values` no schema.yml + teste estrutural de cobertura (27 UFs / 5.570 municípios por índice e ano).
- [x] **Executado contra o Postgres real do projeto** (01/10/2026) — `ingest.py` + `dbt build --select tag:ici`: 33/33 PASS, 0 erro. `ici_indicadores` com 83.955 linhas (`ici_indicadores_estadual`: 405; `ici_indicadores_municipal`: 83.550).
- [ ] **ICI-PSR municipal** (22 capitais) — planilha não recebida, seção não implementada.
- [ ] **Decisão sobre peso das médias** (simples vs. ponderada por população) — implementado como simples por ora.

## Status PSR (Pessoas em Situação de Rua)

Ver [`docs/psr/catalogo-indicadores-psr.md`](docs/psr/catalogo-indicadores-psr.md) e o roteiro [`docs/wiki/tematicas/psr.md`](docs/wiki/tematicas/psr.md).

- [x] **8 planilhas** (CadÚnico, SINAN, ONDH, CNES/Sisab, Censo SUAS, Censo 2022) ingeridas via `ingestion/temas/psr_config.yml`.
- [x] **Staging** — 1 `stg_psr_*` por aba usada (código de município 6 → 7 dígitos, `-` → sem dado).
- [x] **Intermediate** — base municipal (`int_psr_municipio_base`) → recortes municipal/estadual/nacional (`int_psr_recortes`, somas) → 1 modelo por seção (`int_psr_1_populacao` … `int_psr_5_politicas_publicas`).
- [x] **Mart** — `psr_indicadores` (formato longo, 48 indicadores) + `psr_indicadores_{nacional,estadual,municipal}`. Guia de consumo em [`docs/psr/consumo-psr_indicadores.md`](docs/psr/consumo-psr_indicadores.md).
- [x] **Testes** — 62 valores de conferência validados pela área (`transform/tests/psr_valores.sql`) + unicidade/not_null/accepted_values.
- [x] **Executado** (26/11/2026): 36 modelos e 19 testes, tudo verde. Nacional 124 linhas, estadual 3.267, municipal 631.254.
