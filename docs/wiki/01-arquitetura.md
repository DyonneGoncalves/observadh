# Arquitetura

## O problema

Os dados do ObservaDH chegam em **planilhas Excel** enviadas pelas áreas, que
consolidam fontes oficiais (CadÚnico, Censo, SINAN, ONDH, Censo SUAS, CNES…).
A atualização é **anual**. A cada ciclo chegam planilhas novas, às vezes com
correções ou indicadores novos. O processo precisa ser:

- **reprodutível**: as mesmas planilhas sempre geram os mesmos números;
- **rastreável**: dá para saber de qual planilha e aba saiu cada indicador;
- **validado**: os números conferem com os valores aprovados pela área;
- **fácil de repetir no ano seguinte**, por qualquer analista.

## O fluxo

```
PLANILHAS (.xlsx)            ingestion/input/<temática>/<ano>/
      │  Python (ingestion/ingest.py) — importa TODAS as abas, sem regra de negócio
      ▼
RAW (Postgres)               raw.<temática>_<planilha>_<aba>
      │  dbt
      ▼
STAGING                      limpeza e tipagem: 1 modelo por aba usada
      ▼
INTERMEDIATE                 regras de cálculo: 1 modelo por seção do relatório
      ▼
MARTS                        <temática>_indicadores (+ uma tabela por nível)
      │  testes de validação rodam aqui — se algum falhar, o ciclo para
      ▼
ENTREGA                      entrega/<temática>/<data>.zip → desenvolvimento → produção
```

| Peça | Papel |
|---|---|
| **Docker** | Empacota tudo (Python, dbt, Postgres). Ninguém precisa instalar essas ferramentas na própria máquina. |
| **Postgres local** | Banco de trabalho do pipeline, só na máquina do analista. Não é o banco de produção. |
| **Python (`ingest.py`)** | Lê as planilhas e grava cada aba numa tabela `raw`, com o nome do arquivo e da aba de origem. |
| **dbt** | Transformações em SQL versionado, com dependências explícitas, documentação e testes. Um comando recalcula tudo na ordem certa. |
| **Git** | Versiona código, regras e documentação. As planilhas **não** vão para o git (ficam na pasta `ingestion/input/`). |

## Formato das tabelas entregues

Todas as temáticas entregam o mesmo formato **longo**: uma linha por indicador.

| Coluna | Exemplo |
|---|---|
| `secao` | `2.1` |
| `indicador` | `pct_psr_por_genero` |
| `categoria` | `Feminino` |
| `valor` | `15.8015` |
| `valor_tipo` | `percentual` |
| `ano_referencia` | `2024` |

Com isso, um indicador novo ou um ano novo vira **linhas novas**, sem mudar a
estrutura das tabelas nem o código da aplicação.

## Documentação do dbt (linhagem)

```bash
make docs        # abre em http://localhost:8080
```

Mostra cada tabela e coluna, com descrição e testes, e o **grafo de
linhagem**: o caminho de qualquer indicador até a planilha de origem.
