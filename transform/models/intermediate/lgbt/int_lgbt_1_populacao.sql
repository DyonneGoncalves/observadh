-- Intermediate: seção 1 — População LGBTQIA+ no Brasil. Formato LONGO.
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+, 1):
--   pct_populacao_lgbt_18_mais        (homossexual + bissexual + outra) / pop 18+ × 100   N E
--   conjuges_mesmo_sexo_2010             nº absoluto de cônjuges do mesmo sexo, Censo 2010     N E
--   conjuges_mesmo_sexo_2022             nº absoluto de cônjuges do mesmo sexo, Censo 2022     N E M
--   pessoas_uniao_mesmo_sexo_estimativa  conjuges 2022 × 2 (pessoas em união do mesmo sexo)    N

with orient_total as (
    select {{ orientacao_canonica('tipo_de_orient_sexual') }} as orientacao, total_da_pop::numeric as total_pop
    from {{ source('raw_lgbt', 'raw_lgbt_pessoas_orientacao_sexo_total') }}
),

orient_uf as (
    select cod_uf::int as uf_codigo,
           coalesce(homosexual, 0) + coalesce(bissexual, 0) + coalesce(outra_orient, 0) as pct_lgbt
    from {{ source('raw_lgbt', 'raw_lgbt_orientacao_sexual_por_uf') }}
),

censo2010_br as (
    select conjuge_ou_companheiro_a_de_mesmo_sexo::numeric as qtd
    from {{ source('raw_lgbt', 'raw_lgbt_censo_2010_reg') }}
    where brasil_e_grande_regiao ilike 'brasil'
),
censo2010_uf as (
    select cod_uf::int as uf_codigo, conjuge_ou_companheiro_a_de_mesmo_sexo::numeric as qtd
    from {{ source('raw_lgbt', 'raw_lgbt_censo_2010_uf') }}
),

censo2022 as (
    select
        cod_uf::int    as uf_codigo,
        cod_ibge_7::int as municipio_codigo_ibge,
        nullif(conjuge_ou_companheiro_a_de_mesmo_sexo, '-')::numeric as qtd
    from {{ source('raw_lgbt', 'raw_lgbt_conjuges_mesmo_sexo_2022') }}
),

linhas as (

    -- % população LGBTQIA+ 18+ — NACIONAL
    select 'nacional'::text as nivel, null::int as recorte_codigo,
           'pct_populacao_lgbt_18_mais'::text as indicador, null::text as categoria,
           {{ calcula_percentual(
               "(select sum(total_pop) from orient_total where orientacao in ('Homossexual','Bissexual','Outra orientação'))",
               "(select total_pop from orient_total where orientacao ilike 'total%')") }} as valor,
           'percentual'::text as valor_tipo, 2019 as ano_referencia

    union all
    -- % população LGBTQIA+ 18+ — ESTADUAL (colunas já são percentuais na origem)
    select 'estadual', uf_codigo, 'pct_populacao_lgbt_18_mais', null,
           round(pct_lgbt::numeric, 4), 'percentual', 2019
    from orient_uf

    union all
    -- cônjuges do mesmo sexo 2010 — NACIONAL
    select 'nacional', null, 'conjuges_mesmo_sexo_2010', null,
           (select qtd from censo2010_br), 'numero_absoluto', 2010

    union all
    -- cônjuges do mesmo sexo 2010 — ESTADUAL
    select 'estadual', uf_codigo, 'conjuges_mesmo_sexo_2010', null, qtd, 'numero_absoluto', 2010
    from censo2010_uf

    union all
    -- cônjuges do mesmo sexo 2022 — NACIONAL / ESTADUAL / MUNICIPAL
    -- (municípios com "-" na origem contam como 0)
    select 'nacional', null, 'conjuges_mesmo_sexo_2022', null, coalesce(sum(qtd), 0), 'numero_absoluto', 2022 from censo2022
    union all
    select 'estadual', uf_codigo, 'conjuges_mesmo_sexo_2022', null, coalesce(sum(qtd), 0), 'numero_absoluto', 2022 from censo2022 group by uf_codigo
    union all
    select 'municipal', municipio_codigo_ibge, 'conjuges_mesmo_sexo_2022', null, coalesce(sum(qtd), 0), 'numero_absoluto', 2022 from censo2022 group by municipio_codigo_ibge

    union all
    -- estimativa de pessoas em união do mesmo sexo (2022 × 2) — NACIONAL
    select 'nacional', null, 'pessoas_uniao_mesmo_sexo_estimativa', null,
           coalesce((select sum(qtd) from censo2022), 0) * 2, 'numero_absoluto', 2022
),

dim_uf as ( select codigo_uf, nome_uf from {{ ref('dim_uf') }} ),
dim_mun as ( select codigo_municipio, nome_municipio from {{ ref('dim_municipio') }} )

select
    l.nivel,
    l.recorte_codigo,
    case l.nivel
        when 'nacional'  then 'Brasil'
        when 'estadual'  then u.nome_uf
        when 'municipal' then m.nome_municipio
    end                                      as recorte_nome,
    '1'::text                                as secao,
    'População LGBTQIA+ no Brasil'::text      as secao_nome,
    l.indicador, l.categoria, l.valor, l.valor_tipo, l.ano_referencia
from linhas l
left join dim_uf  u on l.nivel = 'estadual'  and u.codigo_uf = l.recorte_codigo
left join dim_mun m on l.nivel = 'municipal' and m.codigo_municipio = l.recorte_codigo
where l.nivel = 'nacional'
   or (l.nivel = 'estadual'  and u.codigo_uf is not null)
   or (l.nivel = 'municipal' and m.codigo_municipio is not null)
