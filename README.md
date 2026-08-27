# ObservaDH — Camada de Dados (v2)

Este repositório contém a camada de dados do ObservaDH: leitura das planilhas recebidas, transformação e disponibilização dos indicadores finais para a aplicação.

> **Status:** projeto novo, em construção. Os temas PSR, PI e PCD continuam rodando no processo atual (fora deste repositório) até serem migrados um a um. O piloto desta nova arquitetura é o tema **LGBTQIA+**.

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

Ver a proposta completa de arquitetura em `proposta-arquitetura-observadh.md` (na raiz do projeto Claude) para o racional por trás dessas decisões. Ver também o catálogo de indicadores do LGBTQIA+ (`catalogo-indicadores-lgbtqia.md`, também no projeto Claude) para o mapeamento completo fórmula → aba → categoria.

## Como rodar um ciclo (quando os dados do tema estiverem prontos)

```bash
# 1. Colocar as planilhas em ingestion/input/<tema>/<ano>/

# 2. Rodar a ingestão (Python) — cria/atualiza as tabelas RAW
python ingestion/ingest.py --tema lgbtqia_plus --ano 2026

# 3. Rodar a transformação (dbt) — recalcula staging → intermediate → marts e roda os testes
cd transform
dbt build --select tag:lgbtqia_plus

# 4. Conferir o grafo de linhagem e a documentação
dbt docs generate && dbt docs serve
```

## Status do piloto LGBTQIA+

- [x] Planilhas recebidas e mapeadas (`ingestion/temas/lgbtqia_plus_config.yml`) — 5 de 8 arquivos com abas confirmadas
- [ ] Ingestão Python rodando (tabelas RAW criadas)
- [ ] Sources dbt declaradas (`transform/models/staging/lgbtqia_plus/_lgbtqia_plus__sources.yml`)
- [ ] Modelos de staging
- [ ] Modelos intermediate (regras de cálculo dos indicadores)
- [ ] Marts finais (nacional / estadual / municipal)
- [ ] Testes de validação
