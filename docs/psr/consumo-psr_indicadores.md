# Como consumir `psr_indicadores`

Guia para a aplicação que monta o relatório **Pessoas em Situação de Rua (PSR)**
nos 3 níveis (nacional, estadual, municipal). Mesmo formato e mesma lógica de
consumo do `lgbt_indicadores`: toda a saída da camada de dados está numa
tabela longa.

## Onde

| Objeto (schema `<target>_marts`) | Uso |
|---|---|
| `psr_indicadores` | tabela longa completa (todos os níveis) |
| `psr_indicadores_nacional` | `nivel = 'nacional'` (sem colunas de recorte) |
| `psr_indicadores_estadual` | `nivel = 'estadual'`; `recorte_*` → `uf_codigo` / `uf_nome` |
| `psr_indicadores_municipal` | `nivel = 'municipal'`; `recorte_*` → `municipio_codigo_ibge` / `municipio_nome` |

As 3 tabelas por nível vão no pacote de entrega (`scripts/exporta_entrega.sh psr`),
junto com o **dicionário** (`dicionario-psr_indicadores.csv`, uma linha por
indicador: seção, chave de bind, categorias, tipo, níveis, ano, descrição) e
este guia.

## Grão e colunas

Uma linha por **`(nivel, recorte_codigo, secao, indicador, categoria, ano_referencia)`**.

| Coluna | Descrição |
|---|---|
| `nivel` | `nacional` \| `estadual` \| `municipal` |
| `recorte_codigo` | `NULL` (nacional) · código IBGE da UF, 2 díg. (estadual) · código IBGE do município, 7 díg. (municipal) |
| `recorte_nome` | `Brasil` · nome da UF · nome do município |
| `secao` | (sub)seção do relatório — ver tabela abaixo |
| `secao_nome` | nome legível da seção |
| `indicador` | slug estável (ex.: `pct_psr_por_genero`) |
| `categoria` | quebra dentro do indicador (ex.: `Feminino`, `2023`, `30 a 39 anos`). `NULL` quando é um valor único |
| `valor` | numérico; percentuais com 4 casas (o arredondamento para exibição é da aplicação). **Pode ser `NULL`** — ver abaixo |
| `valor_tipo` | `numero_absoluto` \| `percentual` \| `categoria_predominante` |
| `ano_referencia` | ano a que o dado se refere (varia por indicador: 2024, 2023 no Censo SUAS, 2022 no Censo IBGE, série 2015–2024) |

### A consulta da aplicação

Uma query por relatório — muda só a tabela e o filtro:

```sql
-- NACIONAL
select indicador, categoria, valor, valor_tipo, ano_referencia
from psr_indicadores_nacional;

-- ESTADUAL
select indicador, categoria, valor, valor_tipo, ano_referencia
from psr_indicadores_estadual
where uf_codigo = :uf_codigo;            -- ex.: 12 (Acre)

-- MUNICIPAL
select indicador, categoria, valor, valor_tipo, ano_referencia
from psr_indicadores_municipal
where municipio_codigo_ibge = :cod_ibge; -- ex.: 3550308 (São Paulo)
```

### Do resultado ao bind no template

Carregar as linhas → mapa `chave → valor` → o template referencia a chave. A
chave é `indicador` sem quebra e `indicador|categoria` com quebra (coluna
`chave_bind` do dicionário):

```js
const ind = {};
for (const r of rows) {
  const chave = r.categoria && r.valor_tipo !== 'categoria_predominante'
    ? `${r.indicador}|${r.categoria}` : r.indicador;
  ind[chave] = r;                         // guarde a linha: os predominantes usam categoria + valor
}
// ${ind["qtd_psr"].valor}
// ${ind["pct_psr_por_genero|Masculino"].valor}
// ${ind["tipo_violencia_principal"].categoria}  ${ind["tipo_violencia_principal"].valor}
```

### `valor` pode ser `NULL`

Percentual cujo denominador é zero → `NULL` = **sem dado** (ex.: município sem
nenhuma pessoa em situação de rua não tem "% de homens"; município sem
crianças de 0 a 5 anos não tem % de frequência escolar nessa faixa). Mostre
como preferir ("sem dado" ou 0,0%). Linhas `numero_absoluto` nunca são `NULL`.

`pct_populacao_por_raca_cor` também é `NULL` no município em que o IBGE
suprimiu aquela cor no Censo 2022.

### Indicadores `categoria_predominante`

A categoria vencedora vem em `categoria` (rótulo pronto, ex.: `Física`,
`Outra forma`, `São Paulo`) e `valor` é o % dela. Uma linha por recorte; **sem
linha** quando o recorte não tem nenhum caso (ex.: município sem notificação
de violência) — trate como "sem dado". Empate → vence a primeira na ordem das
colunas da planilha (resultado estável). Ajustes de redação (caixa etc.) são
da aplicação.

## Seções e mapa do texto-base

| `secao` | Nome | Trecho do texto-base → chave |
|---|---|---|
| `1` | População em situação de rua | "registrou **YYYY** pessoas" → `qtd_psr` · "passou de **X** em 2015 para **Y** em 2024" → `qtd_psr_por_ano\|2015` e `qtd_psr` |
| `1.1` | Evolução anual | gráfico → `qtd_psr_por_ano\|<ano>` |
| `1.2` | Distribuição | "corresponde a **Y%** do total nacional" (E/M) → `pct_psr_sobre_total_nacional` · N: `uf_maior_concentracao_psr_{1,2,3}`, `uf_maior_proporcao_psr`, `qtd_municipios_com_psr\|2015` e `\|2024` |
| `2.1` | Gênero | "Y% homens e Y% mulheres" → `pct_psr_por_genero\|Masculino` / `\|Feminino` |
| `2.2` | Faixa etária | gráficos → `qtd_psr_por_faixa_etaria\|<faixa>`, `pct_psr_por_faixa_etaria\|<faixa>` |
| `2.3` | Raça e cor | gráfico → `pct_psr_por_raca_cor\|<cor>` × `pct_populacao_por_raca_cor\|<cor>` |
| `2.4` | Deficiência | "cerca de **Y%**" → `pct_psr_com_deficiencia` · "principal tipo é **ZZZZ** (**Y%**)" → `tipo_deficiencia_principal_1` (N: também `_2` e `_3`) |
| `3` | Violência | "**YYYY** denúncias" → `qtd_denuncias_ondh` · "**YYYY** notificações" → `qtd_notificacoes_sinan` · N: "interpessoal soma **Y%**" → `pct_notificacoes_viol_interpessoal` · E/M: "violência **ZZZZ**, **Y%**" → `tipo_violencia_principal` |
| `3.1` | Perfil das vítimas | mulheres: `pct_psr_por_genero\|Feminino` (PSR) × `pct_vitimas_por_genero\|Feminino` (vítimas) · negras: `pct_psr_negras` × `pct_vitimas_negras` |
| `3.2` | Tipos de violência interpessoal | gráfico → `pct_viol_interpessoal_por_tipo\|<tipo>` |
| `4` | Renda | `pct_psr_por_ocupacao\|Ocupadas` / `\|Não ocupadas` · `pct_ocupadas_por_vinculo\|Com vínculo formal` / `\|Sem vínculo formal` · `forma_ganhar_dinheiro_principal` · N: `pct_psr_abaixo_linha_pobreza`, `pct_psr_extrema_pobreza` |
| `5.1` | Saúde | `qtd_ecr` · E/N: `qtd_municipios_com_ecr` · `qtd_atendimentos_ecr` |
| `5.2` | Assistência social | `qtd_centros_pop` · E/N: `qtd_municipios_com_centros_pop` · `qtd_psr_atendidas_por_servico\|CRAS` (CREAS, Instituição governamental, Instituição não governamental) · `qtd_psr_elegiveis_bpc` + `pct_elegiveis_bpc_recebem` · `qtd_psr_elegiveis_bolsa_familia` + `pct_elegiveis_bolsa_familia_recebem` |
| `5.3` | Educação | "Quase **Y%**" → `pct_psr_nao_sabem_ler_escrever` · taxas → `taxa_analfabetismo_psr`, `taxa_analfabetismo_populacao` · frequência → `pct_frequencia_escolar_por_faixa\|<faixa>` |

Inventário completo, com categorias e níveis de cada indicador:
`dicionario-psr_indicadores.csv`.
