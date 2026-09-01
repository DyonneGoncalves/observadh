-- Intermediate: seção 2.5 — Casamentos e uniões, parte da PNS 2019.
-- Saída no FORMATO LONGO. Só nível NACIONAL (a PNS só tem recorte Brasil por
-- orientação sexual).
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+_Nacional, 2.5):
--   pct_estado_civil_por_orientacao       estado civil X / total com info da orientação Y * 100
--   pct_natureza_juridica_por_orientacao  natureza X / total com info da orientação Y * 100
-- categoria = "<orientação> / <estado civil ou natureza>".

with estado_civil as (
    select * from {{ ref('stg_lgbt_pessoas_estado_civil') }}
),

natureza as (
    select * from {{ ref('stg_lgbt_natureza_juridica_uniao') }}
),

linhas as (

    select
        'pct_estado_civil_por_orientacao'::text                     as indicador,
        orientacao_sexual || ' / ' || estado_civil                  as categoria,
        {{ calcula_percentual('quantidade', 'total_com_info') }}    as valor
    from estado_civil

    union all

    select
        'pct_natureza_juridica_por_orientacao',
        orientacao_sexual || ' / ' || natureza_juridica,
        {{ calcula_percentual('quantidade', 'total_com_info') }}
    from natureza
)

select
    'nacional'::text                        as nivel,
    null::int                               as recorte_codigo,
    'Brasil'::text                          as recorte_nome,
    '2.5'::text                             as secao,
    'Perfil — Casamentos e uniões'::text     as secao_nome,
    indicador,
    categoria,
    valor,
    'percentual'::text                      as valor_tipo,
    2019                                    as ano_referencia
from linhas
