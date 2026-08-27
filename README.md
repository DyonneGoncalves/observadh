# ObservaDH — Camada de Dados (v2)

Este repositório contém a camada de dados do ObservaDH: leitura das planilhas recebidas, transformação e disponibilização dos indicadores finais para a aplicação.

> **Status:** projeto novo, em construção. Os temas PSR, PI e PCD continuam rodando no processo atual (fora deste repositório) até serem migrados um a um. O piloto desta nova arquitetura é o tema **LGBTQIA+**, começando pela categoria **6.1 — Proteção Social Especial** (a mais limpa da especificação — ver catálogo de indicadores).

## Estrutura

```
observadh/
├── ingestion/          # Python — lê as planilhas e grava nas tabelas RAW
│   ├── input/           # planilhas recebidas, organizadas por tema/ano
│   └── temas/            # um arquivo de configuração por tema (mapeamento planilha → tabela raw)
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

Ver a proposta completa de arquitetura em `proposta-arquitetura-observadh.md` (na raiz do projeto Claude) para o racional por trás dessas decisões. Ver também o catálogo de indicadores do LGBTQIA+ (`catalogo-indicadores-lgbtqia.md`, também no projeto Claude) para o mapeamento completo fórmula → aba → categoria, incluindo 11 inconsistências encontradas nos documentos-fonte que ainda precisam de decisão da equipe.

## Como rodar um ciclo (quando os dados do tema estiverem prontos)

```bash
# 1. Colocar as planilhas em ingestion/input/<tema>/<ano>/

# 2. Rodar a ingestão (Python) — cria/atualiza as tabelas RAW
python ingestion/ingest.py --tema lgbtqia_plus --ano 2026

# 3. Rodar a transformação (dbt) — recalcula staging → intermediate → marts e roda os testes
cd transform
dbt deps   # instala dbt-utils (usado nos testes de schema)
dbt build --select tag:lgbtqia_plus

# 4. Conferir o grafo de linhagem e a documentação
dbt docs generate && dbt docs serve
```

## Status do piloto LGBTQIA+ — categoria 6.1 (Proteção Social Especial)

- [x] Planilhas recebidas e mapeadas (`ingestion/temas/lgbtqia_plus_config.yml`) — 5 de 8 arquivos com abas confirmadas
- [x] Ingestão Python rodando de verdade contra um Postgres — carga da planilha de Assistência Social (7 abas, 40.617 linhas) executada com sucesso
- [x] Sources dbt declaradas (`_lgbtqia_plus_assistencia_social__sources.yml`)
- [x] Modelos de staging (5 — PAEFI, CREAS orientação, CREAS identidade, Centros POP, Unidades de Acolhimento)
- [x] Modelos intermediate (5 — cálculo dos indicadores por município)
- [x] Marts finais (nacional / estadual / municipal)
- [x] Testes de validação (fonte vs. calculado) — lógica conferida em Python contra os dados reais: percentuais calculados batem com os pré-calculados da planilha (diferença máxima ~0,004 p.p.)
- [x] Rodar `dbt build` de verdade contra um Postgres real — `dbt build --select tag:lgbtqia_plus`: 13 modelos + 11 testes, tudo verde. Um bug de fan-out no `int_lgbtqia_plus_acolhimento_por_municipio` (agregava por nome de município em texto livre, com grafias inconsistentes) foi encontrado e corrigido nessa primeira execução real.
- [ ] Demais 6 categorias do LGBTQIA+ (2.5, 5.1, 4.1, 7/7.1, 1, 2)
- [ ] Ingerir os outros 4 arquivos já mapeados (Perfil, Quantas São, ONDH, SINAN) — necessários para as categorias além da 6.1
