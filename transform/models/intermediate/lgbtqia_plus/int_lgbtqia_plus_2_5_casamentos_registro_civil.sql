-- Intermediate: seção 2.5 — Casamentos e uniões, parte do Registro Civil.
-- Saída no FORMATO LONGO (contrato de indicadores — ver cabeçalho de
-- int_lgbtqia_plus_5_1_servicos_saude_trans).
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+_{Nacional,Estadual,Municipal}, 2.5):
--   casamentos_mesmo_sexo_total_ano        série 2013..2023 (nº absoluto)   N E M
--   variacao_casamentos_mesmo_sexo_13_23   (tot2023 - tot2013)/tot2013 *100 N E M
--   pct_casamentos_mesmo_sexo_por_genero_23 gênero / total 2023 * 100        N E M
--   pct_casamentos_lesbohomoafetivos       lesbo / casamentos masc-fem *100  N E   (Total_Casamentos_UF)
--
-- "total" de um recorte/ano = "Casamentos entre homens" + "Casamentos entre mulheres".

with cas as (
    select * from {{ ref('stg_lgbtqia_plus_casamentos_mesmo_sexo') }}
),

dim_mun as (
    select codigo_municipio, nome_municipio, codigo_uf from {{ ref('dim_municipio') }}
),

dim_uf as (
    select codigo_uf, nome_uf from {{ ref('dim_uf') }}
),

tcuf as (
    select * from {{ ref('stg_lgbtqia_plus_total_casamentos_uf') }}
),

-- ---------------------------------------------------- somas por recorte x ano
serie as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, ano, sum(quantidade) as tot
    from cas group by ano
    union all
    select 'estadual', uf_codigo, ano, sum(quantidade)
    from cas group by uf_codigo, ano
    union all
    select 'municipal', municipio_codigo_ibge, ano, sum(quantidade)
    from cas group by municipio_codigo_ibge, ano
),

-- pivô 2013 / 2023 para a variação
variacao as (
    select
        nivel, recorte_codigo,
        max(tot) filter (where ano = 2013) as tot_2013,
        max(tot) filter (where ano = 2023) as tot_2023
    from serie
    group by nivel, recorte_codigo
),

-- gênero em 2023 por recorte
genero_2023 as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, categoria_casamento, sum(quantidade) as q
    from cas where ano = 2023 group by categoria_casamento
    union all
    select 'estadual', uf_codigo, categoria_casamento, sum(quantidade)
    from cas where ano = 2023 group by uf_codigo, categoria_casamento
    union all
    select 'municipal', municipio_codigo_ibge, categoria_casamento, sum(quantidade)
    from cas where ano = 2023 group by municipio_codigo_ibge, categoria_casamento
),

genero_2023_tot as (
    select nivel, recorte_codigo, sum(q) as tot from genero_2023 group by nivel, recorte_codigo
),

-- % lesbohomoafetivos (Total_Casamentos_UF) — nacional + estadual
lesbo as (
    select 'nacional'::text as nivel, null::int as recorte_codigo,
           sum(qtd_casamentos_lesbohomoafetivos) as lesbo,
           sum(qtd_casamentos_masc_fem)          as masc_fem,
           max(ano_referencia)                   as ano_referencia
    from tcuf
    union all
    select 'estadual', uf_codigo,
           qtd_casamentos_lesbohomoafetivos, qtd_casamentos_masc_fem, ano_referencia
    from tcuf
),

-- ---------------------------------------------------------------- montagem long
linhas as (

    -- série anual
    select nivel, recorte_codigo,
           'casamentos_mesmo_sexo_total_ano'::text as indicador,
           ano::text                               as categoria,
           tot::numeric                            as valor,
           'numero_absoluto'::text                 as valor_tipo,
           ano                                     as ano_referencia
    from serie

    union all

    -- variação 2013 -> 2023
    select nivel, recorte_codigo,
           'variacao_casamentos_mesmo_sexo_13_23',
           null,
           {{ calcula_percentual('(tot_2023 - tot_2013)', 'tot_2013') }},
           'variacao_percentual',
           2023
    from variacao

    union all

    -- % por gênero em 2023
    select g.nivel, g.recorte_codigo,
           'pct_casamentos_mesmo_sexo_por_genero_23',
           g.categoria_casamento,
           {{ calcula_percentual('g.q', 't.tot') }},
           'percentual',
           2023
    from genero_2023 g
    join genero_2023_tot t on t.nivel = g.nivel and t.recorte_codigo is not distinct from g.recorte_codigo

    union all

    -- % de casamentos lesbohomoafetivos sobre casamentos masc-fem
    select nivel, recorte_codigo,
           'pct_casamentos_lesbohomoafetivos',
           null,
           {{ calcula_percentual('lesbo', 'masc_fem') }},
           'percentual',
           ano_referencia
    from lesbo
)

select
    l.nivel,
    l.recorte_codigo,
    case l.nivel
        when 'nacional'  then 'Brasil'
        when 'estadual'  then u.nome_uf
        when 'municipal' then m.nome_municipio
    end                                          as recorte_nome,
    '2.5'::text                                   as secao,
    'Perfil — Casamentos e uniões'::text          as secao_nome,
    l.indicador,
    l.categoria,
    l.valor,
    l.valor_tipo,
    l.ano_referencia
from linhas l
left join dim_uf  u on l.nivel = 'estadual'  and u.codigo_uf = l.recorte_codigo
left join dim_mun m on l.nivel = 'municipal' and m.codigo_municipio = l.recorte_codigo
