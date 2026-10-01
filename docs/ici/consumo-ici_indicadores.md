# Como consumir `ici_indicadores`

Guia para a aplicação que monta o relatório do ICI (Índice de Capacidade
Institucional) nos níveis estadual e municipal. Não existe nível nacional —
o ICI não tem relatório nacional (`Filtro_Nacional_V1` é só texto
institucional, ver catálogo).

## Onde

| Objeto (schema `<target>_marts`) | Uso |
|---|---|
| `ici_indicadores` | tabela longa completa (estadual + municipal) |
| `ici_indicadores_estadual` | tabela: `nivel = 'estadual'`; recorte renomeado para `uf_codigo`/`uf_nome`; grupo de comparação é a `regiao` |
| `ici_indicadores_municipal` | tabela: `nivel = 'municipal'`; recorte renomeado para `municipio_codigo_ibge`/`municipio_nome`; grupo de comparação é a `uf_nome` |

## Grão e colunas

Uma linha por **`(nivel, recorte_codigo, indice, ano_referencia)`**.

| Coluna | Descrição |
|---|---|
| `nivel` | `estadual` \| `municipal` |
| `recorte_codigo` / `recorte_nome` | código e nome do território (UF ou município) |
| `uf_codigo` / `uf_sigla` | UF do recorte — igual ao próprio recorte no nível estadual |
| `indice` | `ici_dh` \| `ici_ca` \| `ici_lgbtqia` \| `ici_pcd` \| `ici_pi`. **Sem `ici_psr`** — planilha não recebida (catálogo, Problema 3) |
| `ano_referencia` | `2014` \| `2019` \| `2023` |
| `valor` | o índice, entre 0 e 1 — já vem calculado na planilha-fonte, não é derivado por nós |
| `classificacao` | `Baixa` / `Moderada` / `Alta capacidade institucional` — sempre derivada de `valor` (nunca lida da planilha, que tem grafia inconsistente — catálogo, Problema 7) |
| `media_nacional` | média simples de `valor` entre todos os recortes do mesmo nível/índice/ano |
| `grupo_comparacao_nome` / `media_grupo_comparacao` | região (estadual) ou UF (municipal) usada como par de comparação, e a média de `valor` dentro dela |

⚠️ `media_nacional` e `media_grupo_comparacao` são **médias simples** (cada
território vale 1 voto), não ponderadas por população. Isso ainda não foi
confirmado com a equipe (catálogo, Problema 10) — se a decisão for por
média ponderada, o ajuste fica isolado na CTE `medias` de
`int_ici_estadual.sql`/`int_ici_municipal.sql`.

### A consulta da aplicação

Uma query por render de relatório — a tabela de série histórica de cada
sub-índice sai direto, filtrando por território e índice:

```sql
-- ESTADUAL — tabela "No estado XXXX, os ICI-DH obtidos em 2014/2019/2023..."
select ano_referencia, valor, classificacao, media_nacional, media_regiao
from ici_indicadores_estadual
where uf_codigo = :uf_codigo       -- ex.: 35 (São Paulo)
  and indice = 'ici_dh'
order by ano_referencia;

-- MUNICIPAL — mesma tabela, nível município
select ano_referencia, valor, classificacao, media_nacional, media_estado
from ici_indicadores_municipal
where municipio_codigo_ibge = :cod_ibge   -- ex.: 3550308
  and indice = 'ici_dh'
order by ano_referencia;

-- RESUMO (tabela final de cada relatório, ano fixo 2023, todos os índices)
select indice, valor, classificacao
from ici_indicadores_estadual
where uf_codigo = :uf_codigo and ano_referencia = 2023;
```

## O que falta (não é responsabilidade desta tabela resolver sozinha)

- **ICI-PSR municipal** (22 capitais) — sem planilha-fonte, seção do
  relatório municipal não tem de onde vir. Ver catálogo, Problema 3.
- **Peso das médias** — hoje simples, não ponderada por população (acima).
- Os parágrafos de contexto fixo de cada seção do relatório (números como
  "105 municípios com ICI-CA máximo") **não vêm desta tabela** — são texto
  fixo no próprio `Filtro_*.docx`, fora do escopo da camada de dados (ver
  catálogo, Problema 11).
