-- Staging: ICI-DH municipal. Une os 3 anos, que vêm em 3 tabelas raw
-- diferentes (arquivo 2014/2019 x arquivo 2023, com colunas renomeadas —
-- ver catálogo, Problema 6). Só renomeio para um schema comum, sem regra de
-- negócio — o código de município (codmun/cod_munic) é a única chave usada;
-- as colunas de UF/Região da origem são descartadas aqui de propósito (ver
-- catálogo, Problema 5) — sigla/nome/região canônicos vêm do seed dim_uf no
-- intermediate, a partir de cod_uf.

with ano_2014 as (

    select
        codmun::bigint as municipio_codigo,
        cod_uf::int    as uf_codigo,
        2014           as ano_referencia,
        ici_dh_municipal_2014::numeric as ici_valor
    from {{ source('raw_ici', 'raw_ici_municipal_dh_2014') }}

),

ano_2019 as (

    select
        codmun::bigint as municipio_codigo,
        cod_uf::int    as uf_codigo,
        2019           as ano_referencia,
        ici_dh_municipal_2019::numeric as ici_valor
    from {{ source('raw_ici', 'raw_ici_municipal_dh_2019') }}

),

ano_2023 as (

    select
        cod_munic::bigint as municipio_codigo,
        cod_uf::int       as uf_codigo,
        2023              as ano_referencia,
        ici_dh_municipal_2023::numeric as ici_valor
    from {{ source('raw_ici', 'raw_ici_municipal_dh_2023') }}

)

select * from ano_2014
union all
select * from ano_2019
union all
select * from ano_2023
