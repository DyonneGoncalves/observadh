-- Staging: ICI-CA estadual. Ver stg_ici_estadual_dh.sql para o racional
-- (mesmo reshape wide->long, mesma origem de classificação descartada).

with origem as (

    select * from {{ source('raw_ici', 'raw_ici_estadual_ca') }}

),

longo as (

    select cod_uf::int as uf_codigo, 2014 as ano_referencia, ici_ca_2014::numeric as ici_valor
    from origem

    union all
    select cod_uf::int, 2019, ici_ca_2019::numeric
    from origem

    union all
    select cod_uf::int, 2023, ici_ca_2023::numeric
    from origem

)

select
    uf_codigo,
    ano_referencia,
    ici_valor
from longo
