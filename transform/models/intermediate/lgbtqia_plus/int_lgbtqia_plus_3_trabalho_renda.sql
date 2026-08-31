-- Intermediate: seção 3 — Trabalho e renda de pessoas LGBTQIA+ (PNS 2019).
-- Formato LONGO. Só nível NACIONAL (a PNS só publica esse recorte; Estadual e
-- Municipal = "Sem dados").
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+_Nacional, 3):
--   pct_pessoas_ocupadas_por_orientacao       % de pessoas ocupadas (18+), por orientação
--   pct_renda_per_capita_por_orientacao       % em cada faixa de renda per capita, por orientação
--                                             (faixa X da orientação Y / total da orientação Y × 100)

with ocupacao as (
    select {{ orientacao_canonica('orient_sexual') }} as orientacao,
           de_pessoas_ocupadas::numeric              as pct_ocupadas
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_taxa_ocupacao_orient_sexual') }}
),

renda as (
    select * from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_renda_per_capita') }}
),

linhas as (

    select 'pct_pessoas_ocupadas_por_orientacao'::text as indicador,
           orientacao                                  as categoria,
           pct_ocupadas                                as valor
    from ocupacao

    union all

    select 'pct_renda_per_capita_por_orientacao',
           {{ orientacao_canonica('r.orient_sexual') }} || ' / ' || v.faixa,
           {{ calcula_percentual('v.qtd', 'r.total::numeric') }}
    from renda r
    cross join lateral (values
        ('Sem rendimento a 1/2 salário mínimo', r.sem_rend_a_1_2_salario_minimo::numeric),
        ('Mais de 1/2 a 1 salário mínimo',      r.mais_de_1_2_a_1_do_salario_minimo::numeric),
        ('Mais de 1 a 3 salários mínimos',      r.mais_de_1_a_3_salarios_minimos::numeric),
        ('Mais de 3 a 5 salários mínimos',      r.mais_de_3_a_5_salarios_minimos::numeric),
        ('Mais de 5 salários mínimos',          r.mais_de_5_salarios_minimos::numeric)
    ) as v(faixa, qtd)
)

select
    'nacional'::text                              as nivel,
    null::int                                     as recorte_codigo,
    'Brasil'::text                                as recorte_nome,
    '3'::text                                     as secao,
    'Trabalho e renda de pessoas LGBTQIA+'::text   as secao_nome,
    indicador,
    categoria,
    valor,
    'percentual'::text                            as valor_tipo,
    2019                                          as ano_referencia
from linhas
