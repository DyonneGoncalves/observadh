# Como consumir `lgbt_indicadores`

Guia para a aplicação que monta o relatório LGBTQIA+ nos 3 níveis (nacional,
estadual, municipal). Toda a saída da camada de dados está numa tabela só.

## Onde

| Objeto (schema `<target>_marts`) | Uso |
|---|---|
| `lgbt_indicadores` | tabela longa completa (todos os níveis) |
| `lgbt_indicadores_nacional` | tabela: `nivel = 'nacional'` (sem colunas de recorte) |
| `lgbt_indicadores_estadual` | tabela: `nivel = 'estadual'`; `recorte_*` → `uf_codigo` / `uf_nome` |
| `lgbt_indicadores_municipal` | tabela: `nivel = 'municipal'`; `recorte_*` → `municipio_codigo_ibge` / `municipio_nome` |

As 3 tabelas por nível são o que vai no dump para a aplicação (uma migration
cada). Gera o pacote com `scripts/exporta_entrega_lgbt.sh` — sai `.sql`
(CREATE TABLE + COPY) por tabela, `_schema.sql`, `MANIFEST.txt`, o
**dicionário** (`dicionario-lgbt_indicadores.csv`) e este guia.

O **dicionário** (`docs/lgbt/dicionario-lgbt_indicadores.csv`, gerado por
`scripts/gera_dicionario_lgbt.py`) tem **uma linha por indicador**:
`secao`, `indicador`, `chave_bind` (o formato da chave do mapa —
`indicador` ou `indicador|<categoria>`), `tem_quebra_categoria`,
`categorias` (lista completa quando há quebra), `valor_tipo`, `unidade`,
`niveis` (N/E/M onde existe), `ano_referencia`, `descricao`. É o de-para
entre o texto do relatório e a chave que a aplicação lê.

## Grão e colunas

Uma linha por **`(nivel, recorte_codigo, secao, indicador, categoria, ano_referencia)`**.

| Coluna | Descrição |
|---|---|
| `nivel` | `nacional` \| `estadual` \| `municipal` |
| `recorte_codigo` | `NULL` (nacional) · código IBGE da UF, 2 díg. (estadual) · código IBGE do município, 7 díg. (municipal) |
| `recorte_nome` | `Brasil` · nome da UF · nome do município |
| `secao` | número da (sub)seção no sumário do relatório (ver tabela abaixo) |
| `secao_nome` | nome legível da seção |
| `indicador` | slug estável (ex.: `pct_creas_nao_atende_orientacao`) |
| `categoria` | quebra dentro do indicador (ex.: `Feminino`, `2023`, `Homossexual / Mulheres`). `NULL` quando o indicador é um valor único |
| `valor` | numérico. **Pode ser `NULL`** — ver abaixo |
| `valor_tipo` | `numero_absoluto` \| `percentual` \| `variacao_percentual` \| `sentido_variacao` \| `categoria_predominante` (os dois últimos são indicadores de texto: a palavra vem em `categoria` — ver abaixo) |
| `ano_referencia` | ano a que o dado se refere (varia por indicador) |

### A consulta da aplicação

Uma query por render de relatório. Sempre a mesma forma — muda só a tabela e o filtro:

```sql
-- NACIONAL (1 recorte, sem filtro)
select indicador, categoria, valor, valor_tipo, ano_referencia
from lgbt_indicadores_nacional;

-- ESTADUAL
select indicador, categoria, valor, valor_tipo, ano_referencia
from lgbt_indicadores_estadual
where uf_codigo = :uf_codigo;            -- ex.: 35 (São Paulo)

-- MUNICIPAL
select indicador, categoria, valor, valor_tipo, ano_referencia
from lgbt_indicadores_municipal
where municipio_codigo_ibge = :cod_ibge; -- ex.: 3550308
```

Para uma seção só, adicione `and secao = :secao`.

### Do resultado ao bind no template

O padrão é: carregar as linhas → montar um mapa `chave → valor` → o template
referencia a chave. A **chave** é `indicador` quando não há quebra, e
`indicador|categoria` quando há (ver coluna `chave_bind` no dicionário).

```js
const rows = await db.query(SQL_ESTADUAL, { uf_codigo: 35 });

const ind = {};
for (const r of rows) {
  const chave = r.categoria ? `${r.indicador}|${r.categoria}` : r.indicador;
  ind[chave] = r.valor;                 // null = "sem dado" (ver abaixo)
}

// no template:
//   ${ind["pct_casamentos_lesbohomoafetivos"]}
//   ${ind["pct_casamentos_mesmo_sexo_por_genero_23|Casamentos entre mulheres"]}
//   ${ind["vitimas_paefi"]}
```

Indicador novo no relatório = linha nova no `lgbt_indicadores` + chave nova no
dicionário. **O schema do banco não muda** — nada de `ALTER TABLE` nos dois lados.

### `valor` pode ser `NULL`

Acontece quando o indicador não é calculável para aquele recorte — quase sempre
**percentual/variação com denominador zero** (ex.: um município sem nenhum
casamento entre pessoas do mesmo sexo em 2013 → `variacao_casamentos_mesmo_sexo_13_23`
= `NULL`). Linhas de `valor_tipo = 'numero_absoluto'` **nunca** são `NULL`.
Trate `NULL` como "sem dado", não como zero.

Na **seção 7.0 (SINAN)**, os percentuais de perfil (sexo, faixa etária,
raça/cor, orientação, identidade de gênero, local, agressor) e o % por tipo
vêm `NULL` quando o recorte **não teve notificação** — ex.: município sem
nenhuma violência interpessoal. `0` significa que houve notificação, mas
nenhuma naquela categoria. No gráfico: `NULL` → "sem notificações"; `0` → barra
de 0%.

### Indicadores de texto (`valor_tipo = 'sentido_variacao'`)

Quando o texto precisa de uma **palavra** que depende do dado (ex.: "representa
um **crescimento** de 202,6%"), a palavra vem na coluna `categoria` e `valor`
traz o sinal (+1 / −1 / 0). Há uma única linha por recorte, então basta ler a
`categoria` dela:

```sql
SELECT categoria FROM lgbt_indicadores
WHERE indicador = 'sentido_variacao_casamentos_mesmo_sexo_13_23'
  AND nivel = :nivel AND recorte_codigo IS NOT DISTINCT FROM :recorte;
```

O mesmo vale para `valor_tipo = 'categoria_predominante'` (ex.:
`autoavaliacao_saude_predominante_homossexual`,
`local_predominante_viol_*`, `sexo_predominante_viol_*`, `raca_cor_predominante_viol_*`,
`agressor_principal_{1,2,3}_viol_interpessoal` — um indicador por tópico da lista;
`*_predominante_denuncias` e `uf_maior_denuncias_{1,2,3}` da seção 7.1):
a categoria vencedora vem em `categoria` **com o rótulo exato da planilha**
(ex.: "Residência", "Muito boa e boa") e `valor` é o % dela. Ajustes de
redação (caixa, "Residência" → "casa da vítima" etc.) são da aplicação. Os
predominantes do SINAN não têm linha quando o recorte não teve notificação —
trate como "sem dado". Os % de bissexuais e
heterossexuais da mesma frase são do **mesmo grupo**:

```sql
SELECT split_part(o.categoria, ' / ', 1) AS orientacao, o.valor
FROM lgbt_indicadores p
JOIN lgbt_indicadores o
  ON o.indicador = 'pct_autoavaliacao_saude_por_orientacao'
 AND split_part(o.categoria, ' / ', 2) = p.categoria
WHERE p.indicador = 'autoavaliacao_saude_predominante_homossexual';
```

Com **queda**, a variação % vem negativa (ex.: −20,0): exiba o valor absoluto
("queda de 20,0%"), senão o texto fica "queda de -20,0%".

## Seções

| `secao` | Nome | Níveis | Ano(s) |
|---|---|---|---|
| `1` | População LGBTQIA+ no Brasil | N/E, e M (só cônjuges 2022) | 2010, 2019, 2022 |
| `2` | Perfil das pessoas LGBTQIA+ (2.0–2.4) | N/E (E só 2.0) | 2019 |
| `2.5` | Casamentos e uniões | N/E/M (parte PNS só N) | 2013–2023, 2019 |
| `3` | Trabalho e renda | N | 2019 |
| `4.1` | Projetos escolares contra LGBTQIAfobia | N/E | 2019, 2021 |
| `5.1` | Serviços de saúde para pessoas trans | N/E | 2025 |
| `6` | CRAS e Centros de Convivência (abertura da seção 6) | N/E/M | 2024 |
| `6.1` | Proteção social especial | N/E/M (1 indicador só E/M — ver abaixo) | 2024 (+ série 2017–2024) |
| `7.0` | Notificações de violência (SINAN) | N/E/M | 2015–2024 |
| `7.1` | Denúncias de violações de DH (ONDH) | N/E/M | 2020–2024 |

> 2.6 (População Trans), 3.1 (Pessoas Trans) e "O Censo Trans" (seção 4) são
> textos fixos do relatório, **sem dados** — não aparecem aqui.

## Inventário de indicadores

`num` = valor único · `%` = percentual · `Δ%` = variação percentual.
"categorias" descreve o eixo da coluna `categoria`.

### 1 — População
| indicador | tipo | níveis | categorias |
|---|---|---|---|
| `pct_populacao_lgbt_18_mais` | % | N/E | — |
| `conjuges_mesmo_sexo_2010` | num | N/E | — |
| `conjuges_mesmo_sexo_2022` | num | N/E/M | — |
| `pessoas_uniao_mesmo_sexo_estimativa` | num | N | — |

### 2 — Perfil (PNS 2019; 2.0 nacional e estadual, 2.1–2.4 só nacional)
| indicador | tipo | categorias |
|---|---|---|
| `pct_populacao_por_orientacao` | % | orientação sexual — **N/E** (as 6 categorias; no estadual alimenta "2. Perfil das pessoas LGBTQIA+ no estado") |
| `pct_orientacao_por_sexo` | % | `<orientação> / Homens\|Mulheres` |
| `pct_orientacao_por_faixa_etaria` | % | `<orientação> / <faixa>` |
| `pct_orientacao_por_raca_cor` | % | `<orientação> / <cor>` |
| `pct_orientacao_por_localidade` | % | `<orientação> / Urbana\|Rural` |

### 2.5 — Casamentos e uniões
| indicador | tipo | níveis | categorias |
|---|---|---|---|
| `casamentos_mesmo_sexo_total_ano` | num | N/E/M | ano `2013`..`2023` |
| `variacao_casamentos_mesmo_sexo_13_23` | Δ% | N/E/M | — |
| `sentido_variacao_casamentos_mesmo_sexo_13_23` | texto | N/E/M | **a palavra em si**: `crescimento` \| `queda` \| `estabilidade` (1 linha por recorte) |
| `pct_casamentos_mesmo_sexo_por_genero_23` | % | N/E/M | `Casamentos entre homens\|mulheres` |
| `pct_casamentos_lesbohomoafetivos` | % | N/E | — (ano_ref 2022) |
| `pct_estado_civil_por_orientacao` | % | N | `<orientação> / <estado civil>` |
| `pct_natureza_juridica_por_orientacao` | % | N | `<orientação> / Casamento civil\|União estável` |

### 3 — Trabalho e renda (só nacional)
| indicador | tipo | categorias |
|---|---|---|
| `pct_pessoas_ocupadas_por_orientacao` | % | orientação sexual |
| `pct_renda_per_capita_por_orientacao` | % | `<orientação> / <faixa de renda>` |

### 4.1 — Projetos escolares
| indicador | tipo | níveis | categorias |
|---|---|---|---|
| `pct_escolas_com_projeto` | % | N/E | ano `2019` / `2021` |
| `escolas_avaliadas_saeb` | num | N/E | ano `2019` / `2021` — o "XXXX escolas avaliadas" do texto usa `2021` |
| `pct_escolas_com_projeto_localizacao_2021` | % | N/E | `Urbana` / `Rural` |
| `pct_escolas_com_projeto_uf_maior` / `_uf_menor` | % | N | nome da UF |

### 5.1 — Serviços de saúde para pessoas trans
| indicador | tipo | níveis | categorias |
|---|---|---|---|
| `estabelecimentos_total` | num | N/E | — |
| `estabelecimentos_por_habilitacao` | num | N/E | `Ambulatorial` / `Hospitalar` / `Ambulatorial/Hospitalar` — sempre as 3, com `0` quando não há |
| `estados_com_habilitacao_hospitalar` / `estados_apenas_ambulatorial` / `estados_sem_servico` | num | N | — |

### 6 — CRAS e Centros de Convivência
| indicador | tipo | níveis |
|---|---|---|
| `pct_cras_abordaram_tema` | % | N/E/M |
| `pct_centros_convivencia_abordaram_tema` | % | N/E/M |

### 6.1 — Proteção social especial (N/E/M)
`vitimas_paefi`, `creas_total`, `creas_nao_atende_orientacao`,
`creas_nao_atende_identidade`, `centros_pop_total`,
`unidades_acolhimento_total`, `pessoas_acolhidas_total`,
`pessoas_trans_acolhidas_total` — todos `num`, sem categoria, ano 2024.
`pct_creas_nao_atende_orientacao`, `pct_creas_nao_atende_identidade`,
`pct_centros_pop_atenderam_lgbt`,
`pct_unidades_acolhimento_com_pessoas_trans` — todos `%`, sem categoria.

`vitimas_paefi_2017_2024` — **só estadual/municipal**. Soma 2017–2024: é o
número de "entre 2017 e 2024, XXXX pessoas vítimas..." do texto desses dois
relatórios (ex.: Alagoas = 141). **Não use `vitimas_paefi` nessa frase** — ele
é só o ano de 2024 (Alagoas = 9).

`pct_unidades_acolhimento_com_pessoas_trans` — denominador = unidades que
responderam Sim ou Não (unidades sem resposta ficam fora), conforme a fórmula.

`vitimas_paefi_serie_historica` — **só estadual/municipal** (não existe em
nacional). Série anual 2017–2024, `categoria` = ano (`"2017"`..`"2024"`,
mesmo padrão de `notificacoes_por_ano`). É o dado que alimenta o **gráfico**
da seção 6.1 nos relatórios estadual e municipal — `vitimas_paefi` sozinho
só dá o total de 2024, não a série.

### 7.0 — Notificações SINAN (N/E/M)
| indicador | tipo | categorias |
|---|---|---|
| `notificacoes_por_ano` · `violacoes_por_ano` *(7.1)* | num | ano |
| `notificacoes_total_2024` | num | — |
| `pct_notificacoes_por_tipo_2024` | % | `Interpessoal` / `Autoprovocada` / `Origem desconhecida` |
| `pct_municipios_com_notificacao_2024` | % | — (N/E; N ÷5.570, E ÷ nº de municípios da UF) |
| `pct_viol_interpessoal_por_<X>` e `pct_viol_autoprovocada_por_<X>` | % | `<X>` ∈ sexo, faixa_etaria, raca_cor, orientacao_sexual, identidade_genero, local |
| `pct_viol_interpessoal_por_agressor` | % | 6 grupos de agressor |

### 7.1 — Denúncias ONDH (N/E/M)
| indicador | tipo | categorias |
|---|---|---|
| `denuncias_por_ano` · `violacoes_por_ano` | num | ano `2020`..`2024` |
| `denuncias_total_2020_2024` | num | — |
| `pct_participacao_denuncias_2024` | % | — (E/M; recorte ÷ Brasil 2024) |
| `pct_denuncias_por_<X>` | % | `<X>` ∈ sexo, faixa_etaria, raca_cor, identidade_genero, orientacao_sexual, local (32), relacao_suspeito (49), tipo_violacao (~103) |

## Observações que afetam a leitura

- **`recorte_codigo` é polimórfico** (UF de 2 díg. no estadual, IBGE de 7 díg.
  no municipal). Use sempre junto com `nivel`.
- **SINAN/ONDH**: os dados de perfil são de **2024**; a série histórica cobre
  o intervalo indicado. Denúncias da ONDH com local no **exterior** entram só
  no total **nacional** (não têm UF/município).
- **6.1 / gráfico de PAEFI**: `vitimas_paefi` é só o total de 2024 (bate com
  o relatório nacional publicado). A série 2017–2024 para o gráfico é o
  indicador separado `vitimas_paefi_serie_historica`, e só existe em
  estadual/municipal — a especificação nacional não pede esse gráfico.
- **7.0/7.1**: "Heterossexual" nas quebras por orientação sexual do SINAN é
  **derivado** (total − demais categorias) — a planilha de origem não traz a
  coluna. Os demais valores vêm direto das abas.
- **Rankings** ("10 maiores locais", "10 maiores relações de suspeito"): a
  tabela traz **todas** as categorias; o "top N" é escolha de apresentação.
- **`pct_denuncias_por_relacao_suspeito`**: a categoria `Outros` é a maior
  (~24%); `Não se aplica` é uma categoria pequena e distinta.
- Cada indicador foi **validado** contra a planilha de cálculo da equipe
  (`transform/tests/lgbt_*_valores.sql`).
