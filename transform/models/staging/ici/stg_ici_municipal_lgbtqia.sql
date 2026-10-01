-- Staging: ICI-LGBTQIA+ municipal. Ver stg_ici_municipal_dh.sql para o
-- racional. A aba de 2014 tem 6 colunas extras totalmente vazias na origem
-- (ver catálogo, Problema 8) — já descartadas pelo ingest.py, não aparecem
-- aqui.

with ano_2014 as (

    select
        codmun::bigint as municipio_codigo,
        cod_uf::int    as uf_codigo,
        2014           as ano_referencia,
        ici_lgbtqia_municipal_2014::numeric as ici_valor
    from {{ source('raw_ici', 'raw_ici_municipal_lgbtqia_2014') }}

),

ano_2019 as (

    select
        codmun::bigint as municipio_codigo,
        cod_uf::int    as uf_codigo,
        2019           as ano_referencia,
        ici_lgbtqia_municipal_2019::numeric as ici_valor
    from {{ source('raw_ici', 'raw_ici_municipal_lgbtqia_2019') }}

),

ano_2023 as (

    select
        cod_munic::bigint as municipio_codigo,
        cod_uf::int       as uf_codigo,
        2023              as ano_referencia,
        ici_lgbtqia_municipal_2023::numeric as ici_valor
    from {{ source('raw_ici', 'raw_ici_municipal_lgbtqia_2023') }}

)

select * from ano_2014
union all
select * from ano_2019
union all
select * from ano_2023
