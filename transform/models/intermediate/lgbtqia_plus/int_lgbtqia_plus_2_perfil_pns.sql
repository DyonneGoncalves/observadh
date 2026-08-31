-- Intermediate: seção 2 — Perfil das pessoas LGBTQIA+ (PNS 2019). Formato LONGO.
-- Nível NACIONAL apenas (a PNS só publica esse recorte por orientação sexual).
--
-- As tabelas de origem já estão no nível Brasil: 1 linha por orientação sexual
-- + 1 linha "Total com info". O % é calculado LINHA A LINHA (categoria da
-- orientação X / total da orientação X × 100), sem agregação entre municípios.
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+_Nacional, 2 / 2.1-2.4):
--   pct_populacao_por_orientacao       total da orientação X / total geral × 100
--   pct_orientacao_por_sexo            homens|mulheres da orient. X / total da orient. X
--   pct_orientacao_por_faixa_etaria    faixa Y da orient. X / total com info de faixa da orient. X
--   pct_orientacao_por_raca_cor        cor Y da orient. X / total com info de cor da orient. X
--   pct_orientacao_por_localidade      área Y da orient. X / total com info de localidade da orient. X

with sexo_total as (
    select {{ orientacao_canonica('tipo_de_orient_sexual') }} as orientacao,
           total_da_pop::numeric        as total_pop,
           total_de_homens::numeric     as homens,
           total_de_mulheres::numeric   as mulheres
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_pessoas_orientacao_sexo_total') }}
),
total_geral as (
    select total_pop from sexo_total where orientacao ilike 'total%'
),

faixa as (
    select * from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_pessoas_faixa_etaria') }}
),
raca as (
    select * from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_pessoas_cor_ou_raca') }}
),
localidade as (
    select * from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_pessoas_area_localidade') }}
),

linhas as (

    -- 2.0 — % da população por orientação
    select 'pct_populacao_por_orientacao'::text as indicador,
           orientacao                           as categoria,
           {{ calcula_percentual('total_pop', '(select total_pop from total_geral)') }} as valor
    from sexo_total
    where orientacao not ilike 'total%'

    union all
    -- 2.1 — % da orientação por sexo
    select 'pct_orientacao_por_sexo', s.orientacao || ' / ' || v.sexo,
           {{ calcula_percentual('v.qtd', 's.total_pop') }}
    from sexo_total s
    cross join lateral (values ('Homens', s.homens), ('Mulheres', s.mulheres)) as v(sexo, qtd)
    where s.orientacao not ilike 'total%'

    union all
    -- 2.2 — % da orientação por faixa etária
    select 'pct_orientacao_por_faixa_etaria',
           {{ orientacao_canonica('f.tipo_de_orient_sexual') }} || ' / ' || v.faixa,
           {{ calcula_percentual('v.qtd', 'f.total_com_info_de_fx_etaria::numeric') }}
    from faixa f
    cross join lateral (values
        ('18 a 29 anos', f."18_a_29_anos"::numeric), ('30 a 39 anos', f."30_a_39_anos"::numeric),
        ('40 a 49 anos', f."40_a_49_anos"::numeric), ('50 a 59 anos', f."50_a_59_anos"::numeric),
        ('60 a 69 anos', f."60_a_69_anos"::numeric), ('70 a 79 anos', f."70_a_79_anos"::numeric),
        ('80 anos ou mais', f."80_anos_ou_mais"::numeric)
    ) as v(faixa, qtd)

    union all
    -- 2.3 — % da orientação por cor/raça
    select 'pct_orientacao_por_raca_cor',
           {{ orientacao_canonica('r.tipo_de_orient_sexual') }} || ' / ' || v.cor,
           {{ calcula_percentual('v.qtd', 'r.total_com_info_de_cor_ou_raca::numeric') }}
    from raca r
    cross join lateral (values
        ('Branca', r.branca::numeric), ('Preta', r.preta::numeric), ('Parda', r.parda::numeric),
        ('Amarela', r.amarela::numeric), ('Indígena', r.indigena::numeric)
    ) as v(cor, qtd)

    union all
    -- 2.4 — % da orientação por localidade
    select 'pct_orientacao_por_localidade',
           {{ orientacao_canonica('l.tipo_de_orient_sexual') }} || ' / ' || v.area,
           {{ calcula_percentual('v.qtd', 'l.total_com_info_de_localidade::numeric') }}
    from localidade l
    cross join lateral (values ('Urbana', l.urbano::numeric), ('Rural', l.rural::numeric)) as v(area, qtd)
)

select
    'nacional'::text                        as nivel,
    null::int                               as recorte_codigo,
    'Brasil'::text                          as recorte_nome,
    '2'::text                               as secao,
    'Perfil das pessoas LGBTQIA+'::text      as secao_nome,
    indicador,
    categoria,
    valor,
    'percentual'::text                      as valor_tipo,
    2019                                    as ano_referencia
from linhas
