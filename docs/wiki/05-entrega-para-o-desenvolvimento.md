# Entrega para o desenvolvimento

O produto da camada de dados é um **pacote por temática**, gerado no fim do
ciclo (`make ciclo` ou `make exporta TEMA=<tema>`):

```
entrega/<tema>/<data>/          (+ <data>.zip, que é o que se envia)
├── <tema>_indicadores_nacional.sql     CREATE TABLE + dados (COPY)
├── <tema>_indicadores_estadual.sql
├── <tema>_indicadores_municipal.sql
├── _schema.sql                         só as estruturas (DDL), juntas
├── consumo-<tema>_indicadores.md       como a aplicação consulta e faz o bind no texto
├── dicionario-<tema>_indicadores.csv   1 linha por indicador
├── LEIA-ME.txt
└── MANIFEST.txt                        contagem de linhas + md5 + chave natural
```

## Como carregar

Os `.sql` não têm schema fixo, dono ou permissões: entram no `search_path` do
banco de destino.

```bash
psql -d <BANCO> -v ON_ERROR_STOP=1 -f <tema>_indicadores_nacional.sql
psql -d <BANCO> -v ON_ERROR_STOP=1 -f <tema>_indicadores_estadual.sql
psql -d <BANCO> -v ON_ERROR_STOP=1 -f <tema>_indicadores_municipal.sql
```

Depois, confira as contagens com o `MANIFEST.txt`.

## Contrato com a aplicação

- Mesmas colunas em todas as temáticas: `secao`, `secao_nome`, `indicador`, `categoria`, `valor`, `valor_tipo`, `ano_referencia` (+ `uf_codigo`/`uf_nome` no estadual e `municipio_codigo_ibge`/`municipio_nome` no municipal).
- O texto-base do relatório é preenchido por **chave** (`indicador` ou `indicador|categoria`). O mapa trecho do texto → chave está no `consumo-<tema>_indicadores.md`.
- Ano novo ou indicador novo = **linhas novas**, sem mudança de estrutura.
- Percentual com 4 casas: o arredondamento para exibição é da aplicação. `NULL` = sem dado.
