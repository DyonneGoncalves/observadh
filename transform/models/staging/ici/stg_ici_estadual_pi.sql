-- Staging: ICI-PI estadual. Ver stg_ici_estadual_dh.sql para o racional.

with origem as (

    select * from {{ source('raw_ici', 'raw_ici_estadual_pi') }}

),

longo as (

    select cod_uf::int as uf_codigo, 2014 as ano_referencia, ici_pi_2014::numeric as ici_valor
    from origem

    union all
    select cod_uf::int, 2019, ici_pi_2019::numeric
    from origem

    union all
    select cod_uf::int, 2023, ici_pi_2023::numeric
    from origem

)

select
    uf_codigo,
    ano_referencia,
    ici_valor
from longo
