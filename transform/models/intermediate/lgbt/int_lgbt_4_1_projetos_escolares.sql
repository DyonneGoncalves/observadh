-- Intermediate: seção 4.1 — Projetos escolares de enfrentamento à LGBTQIAfobia
-- (SAEB 2019 e 2021). Saída no FORMATO LONGO.
--
-- 4.1 existe nos níveis NACIONAL e ESTADUAL (Educação = "Sem dados municipais").
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+_{Nacional,Estadual}, 4.1):
--   pct_escolas_com_projeto            possui / base * 100, por ano (2019, 2021)   N E
--   pct_escolas_com_projeto_uf_maior   UF com maior % em 2021 (categoria = UF)      N
--   pct_escolas_com_projeto_uf_menor   UF com menor % em 2021 (categoria = UF)      N
--   pct_escolas_com_projeto_localizacao_2021  com_projeto / total_com_info * 100     N E
--     por localização (Urbana / Rural)
--   escolas_avaliadas_saeb             nº de escolas na base do %, por ano          N E
--     (chamado 27607, item 3) é o "XXXX" de "X% das XXXX escolas avaliadas".
--     Mesmo denominador do pct_escolas_com_projeto do ano — o relatório usa 2021.
-- base = "total com informação" em 2019, "total" em 2021 (ver staging).

with proj as (
    select * from {{ ref('stg_lgbt_projetos_homofobia') }}
),

local as (
    select * from {{ ref('stg_lgbt_projetos_homofobia_local') }}
),

dim_uf as (
    select codigo_uf, nome_uf from {{ ref('dim_uf') }}
),

-- % por ano: nacional e estadual
pct_ano as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, ano,
           sum(qtd_possui_projeto) as possui, sum(qtd_base) as base
    from proj group by ano
    union all
    select 'estadual', uf_codigo, ano, sum(qtd_possui_projeto), sum(qtd_base)
    from proj group by uf_codigo, ano
),

-- % estadual de 2021, para achar a UF de maior e de menor %
pct_uf_2021 as (
    select p.recorte_codigo as uf_codigo, u.nome_uf,
           {{ calcula_percentual('p.possui', 'p.base') }} as pct
    from pct_ano p
    join dim_uf u on u.codigo_uf = p.recorte_codigo
    where p.nivel = 'estadual' and p.ano = 2021
),

extremos_2021 as (
    select 'pct_escolas_com_projeto_uf_maior'::text as indicador, nome_uf as categoria, pct as valor
    from pct_uf_2021 order by pct desc limit 1
),
extremos_2021_min as (
    select 'pct_escolas_com_projeto_uf_menor'::text as indicador, nome_uf as categoria, pct as valor
    from pct_uf_2021 order by pct asc limit 1
),

-- % por localização (Urbana/Rural): nacional e estadual
pct_local as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, localizacao,
           sum(qtd_escolas_com_projeto) as com_projeto, sum(qtd_total_com_info) as base
    from local group by localizacao
    union all
    select 'estadual', uf_codigo, localizacao,
           sum(qtd_escolas_com_projeto), sum(qtd_total_com_info)
    from local group by uf_codigo, localizacao
),

-- ---------------------------------------------------------------- montagem long
linhas as (

    select nivel, recorte_codigo,
           'pct_escolas_com_projeto'::text            as indicador,
           ano::text                                  as categoria,
           {{ calcula_percentual('possui', 'base') }} as valor,
           'percentual'::text                         as valor_tipo,
           ano                                        as ano_referencia
    from pct_ano

    union all

    select nivel, recorte_codigo,
           'escolas_avaliadas_saeb', ano::text,
           coalesce(base, 0)::numeric, 'numero_absoluto', ano
    from pct_ano

    union all

    select 'nacional', null, indicador, categoria, valor, 'percentual', 2021
    from extremos_2021
    union all
    select 'nacional', null, indicador, categoria, valor, 'percentual', 2021
    from extremos_2021_min

    union all

    select nivel, recorte_codigo,
           'pct_escolas_com_projeto_localizacao_2021', localizacao,
           {{ calcula_percentual('com_projeto', 'base') }},
           'percentual', 2021
    from pct_local
)

select
    l.nivel,
    l.recorte_codigo,
    case l.nivel when 'nacional' then 'Brasil' else u.nome_uf end as recorte_nome,
    '4.1'::text                                                    as secao,
    'Educação — Projetos escolares de enfrentamento à LGBTQIAfobia'::text as secao_nome,
    l.indicador,
    l.categoria,
    l.valor,
    l.valor_tipo,
    l.ano_referencia
from linhas l
left join dim_uf u on l.nivel = 'estadual' and u.codigo_uf = l.recorte_codigo
