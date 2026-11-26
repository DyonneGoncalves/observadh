# Ciclo anual de atualização

Roteiro **genérico**, igual para todas as temáticas. O que muda por temática
(planilhas esperadas, anos de referência, valores de conferência) está na
página da temática, na seção **Checklist do ano seguinte**.

> Antes de começar: ambiente instalado ([Instalação do ambiente](/Dados-ObservaDH/Instalação-do-ambiente))
> e Docker Desktop aberto.

## 1. Receber e conferir as planilhas

- Confirme que chegaram **todos** os arquivos listados na página da temática.
- Confira se seguem o [Padrão das planilhas](/Dados-ObservaDH/Padrão-das-planilhas): mesmos nomes de aba, mesmos cabeçalhos e uma linha por município.
- Se a área mudou a estrutura (aba nova, coluna renomeada, indicador novo), **anote antes de rodar**. Isso vai exigir ajuste no código (passo 5).

## 2. Criar uma branch e colocar as planilhas na pasta do ciclo

```bash
git switch main && git pull
git switch -c <tema>-<ano>                    # ex.: psr-2027
mkdir -p ingestion/input/<tema>/<ano>         # ano = ano em que as planilhas foram recebidas
```

Copie as planilhas para `ingestion/input/<tema>/<ano>/`. Os nomes dos arquivos
precisam bater com os listados em `ingestion/temas/<tema>_config.yml`
(`prefixos_planilha`). Se o nome mudou (ex.: `2015_2024` → `2015_2025`),
atualize o arquivo de configuração.

## 3. Atualizar os anos de referência

No `transform/dbt_project.yml`, seção `vars`, ajuste os anos da temática
(ex.: `psr_ano_referencia: 2025`). É deles que sai a coluna `ano_referencia`
dos indicadores.

## 4. Simular a ingestão

```bash
make dry-run TEMA=<tema> ANO=<ano>
```

Lista as tabelas `raw` que seriam criadas, uma por aba, sem gravar nada.
Compare com os `identifier` de `transform/models/staging/<tema>/_<tema>__sources.yml`.
Se uma aba mudou de nome, a tabela muda de nome e o `identifier` precisa ser
atualizado.

## 5. Rodar o ciclo

```bash
make ciclo TEMA=<tema> ANO=<ano>
```

Executa, em ordem:

1. **Ingestão**: todas as abas → schema `raw` (recriadas do zero).
2. **Transformação**: `dbt seed` + `dbt build` (staging → intermediate → marts).
3. **Testes**: unicidade, campos obrigatórios, valores aceitos e **conferência dos valores** com os números validados pela área.
4. **Exportação**: gera `entrega/<tema>/<data>/` e o `.zip`.

Leva poucos minutos. No fim do dbt aparece um resumo como
`Done. PASS=19 WARN=0 ERROR=0 SKIP=0`.

- **Tudo `PASS`**: siga para o passo 7.
- **Algum `ERROR` ou `FAIL`**: o ciclo para antes da exportação. Vá para o passo 6.

## 6. Se algo falhar

| Mensagem | Causa provável | O que fazer |
|---|---|---|
| `nenhuma planilha (.xlsx/.xls) em ingestion/input/...` | pasta ou ano errados | confira o caminho e o `ANO=` |
| `relation "raw.<tabela>" does not exist` | aba renomeada na planilha | rode o dry-run (passo 4) e ajuste o `identifier` no `_<tema>__sources.yml` |
| `column "<coluna>" does not exist` em um `stg_*` | cabeçalho renomeado na planilha | ajuste o nome da coluna no modelo `stg_*` indicado |
| falha em `not_null_stg_*_municipio_codigo_ibge` | município com código fora da tabela de referência (ex.: município novo) | inclua o município em `transform/seeds/dim_municipio.csv` |
| falha em `<tema>_valores` | valor calculado diferente do esperado | veja abaixo |

**Falha no teste de valores.** O teste compara os indicadores com os números
validados pela área. No ano novo, os valores esperados precisam ser
atualizados com os números da conferência daquele ano: a planilha de cálculo
ou o relatório aprovado pela área. Se um número continuar diferente com o
valor esperado atualizado, a diferença é real. Investigue a regra no modelo
`int_<tema>_<seção>` correspondente, com a área.

Depois de ajustar, rode só a parte que falhou:

```bash
make transforma TEMA=<tema>     # dbt seed + build + testes
make exporta TEMA=<tema>        # quando estiver tudo verde
```

## 7. Conferir, versionar e entregar

1. Confira o `entrega/<tema>/<data>/MANIFEST.txt`: contagem de linhas por tabela (deve ser da mesma ordem do ciclo anterior).
2. Versione os ajustes (configuração, anos, valores esperados, modelos):

   ```bash
   git add -A
   git commit -m "<tema>: ciclo <ano>"
   git push --set-upstream origin <tema>-<ano>
   ```
   Abra o pull request para a `main`.
3. Envie o `entrega/<tema>/<data>.zip` ao desenvolvimento (ver [Entrega para o desenvolvimento](/Dados-ObservaDH/Entrega-para-o-desenvolvimento)).
