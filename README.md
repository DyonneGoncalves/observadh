# ObservaDH — Camada de Dados (v2)

Este repositório contém a camada de dados do ObservaDH: leitura das planilhas recebidas, transformação e disponibilização dos indicadores finais para a aplicação.

> **Status:** projeto novo, em construção. Os temas PSR, PI e PCD continuam rodando no processo atual (fora deste repositório) até serem migrados um a um. O piloto desta nova arquitetura é o tema **LGBTQIA+**, começando pela categoria **6.1 — Proteção Social Especial** (a mais limpa da especificação — ver catálogo de indicadores).

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
    │   └── marts/         # tabelas finais: <tema>_relatorio_nacional / _estadual / _municipal
    └── tests/            # testes customizados de validação (fonte vs. calculado)
```

Ver a proposta completa de arquitetura em `proposta-arquitetura-observadh.md` (na raiz do projeto Claude) para o racional por trás dessas decisões.

O mapeamento completo **seção do relatório → fórmula → aba do Excel → tabela `raw` → modelo dbt** está em [`docs/lgbtqia_plus/catalogo-indicadores-lgbtqia.md`](docs/lgbtqia_plus/catalogo-indicadores-lgbtqia.md), junto com os 6 documentos-fonte da equipe (3 de cálculo + 3 de texto-base do relatório) e as inconsistências pendentes de decisão.

## Como rodar um ciclo (quando os dados do tema estiverem prontos)

```bash
# 1. Colocar as planilhas em ingestion/input/<tema>/<ano>/  (o "ano" = ciclo de recebimento)

# 2. Rodar a ingestão (Python) — importa TODA aba de TODA planilha para o schema raw.
#    Cada execução recria as tabelas do zero. Use --dry-run para ver os nomes
#    de tabela gerados sem gravar; --manter-log para preservar o histórico de execuções.
python ingestion/ingest.py --tema lgbtqia_plus --ano 2026

# 3. Rodar a transformação (dbt) — recalcula staging → intermediate → marts e roda os testes
cd transform
dbt deps   # instala dbt-utils (usado nos testes de schema)
dbt seed   # carrega as tabelas de referência (dim_municipio, dim_uf)
dbt build --select tag:lgbtqia_plus

# 4. Conferir o grafo de linhagem e a documentação
dbt docs generate && dbt docs serve
```

Conexão com o banco: variáveis `OBSERVADH_DB_HOST/_PORT/_NAME/_USER/_PASSWORD`
(a ingestão também aceita `DATABASE_URL`) e `transform/profiles.yml.example`
copiado para `~/.dbt/profiles.yml`.

## Status LGBTQIA+

- [x] **Todas as 8 planilhas ingeridas** — 54 tabelas no schema `raw` (toda aba de todo arquivo), 234.557 linhas, via descoberta automática (`ingestion/ingest.py`)
- [x] Sources dbt (`_lgbtqia_plus__sources.yml`) — apontam para o schema `raw` via `identifier`
- [x] **Seção 6.1 — Proteção Social Especial** (piloto) — staging + intermediate + marts nos 3 níveis, no **formato largo** (`lgbtqia_plus_relatorio_nacional/_estadual/_municipal`). Testes de validação contra o % pré-calculado da planilha. *A migrar para o formato longo.*
- [x] **Formato longo** — mart único `lgbtqia_plus_indicadores` (uma linha por nivel × recorte × seção × indicador × categoria) + views `_nacional`/`_estadual`/`_municipal`. Cada (sub)seção é um `int_lgbtqia_plus_<secao>_*`.
- [x] **Seção 5.1 — Serviços de saúde para pessoas trans** (N, E) no formato longo. Validada contra a planilha de cálculo da equipe.
- [x] **Seção 2.5 — Casamentos e uniões** (N, E, M; parte PNS só N) no formato longo. Validada contra a planilha de cálculo e contra o texto-base do relatório.
- [x] **Seção 4.1 — Projetos escolares contra LGBTQIAfobia** (N, E) no formato longo. Validada contra a planilha de cálculo.
- [x] **Seção 7.1 — Denúncias de violações de DH (ONDH)** (N, E, M) no formato longo. Validada contra a planilha de cálculo. Falta local e relação do suspeito.
- [x] **Seção 7.0 — Notificações de violência (SINAN)** (N, E, M) no formato longo. Validada. Falta local e perfil do agressor.
- [x] **Seções 1, 2.0–2.4 e 3 — População, Perfil e Trabalho (PNS 2019 / Censo)** no formato longo. Validadas contra a planilha de cálculo e o texto-base.
- [x] `dbt build --select tag:lgbtqia_plus` — tudo verde (57 nós). `lgbtqia_plus_indicadores` com ~412k linhas — **8 das 8 seções do relatório** (falta só migrar a 6.1).
- [ ] Migrar a **6.1** do formato largo para o `lgbtqia_plus_indicadores`; extras adiados de 7.0/7.1 (local, agressor, relação do suspeito). Ver [`docs/lgbtqia_plus/catalogo-indicadores-lgbtqia.md`](docs/lgbtqia_plus/catalogo-indicadores-lgbtqia.md).
- [ ] Migrar a 6.1 do formato largo para o `lgbtqia_plus_indicadores`.
