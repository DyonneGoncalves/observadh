-- Staging: ICI-DH estadual. 1 linha por UF na origem, com 2014/2019/2023 em
-- colunas — aqui só reshape para formato longo (1 linha por UF x ano), sem
-- regra de negócio. A classificação de origem é descartada (grafia
-- inconsistente entre linhas — ver catálogo, Problema 7); recalculada no
-- intermediate com a macro classifica_ici.

with origem as (

    select * from {{ source('raw_ici', 'raw_ici_estadual_dh') }}

),

longo as (

    select cod_uf::int as uf_codigo, 2014 as ano_referencia, ici_dh_2014::numeric as ici_valor
    from origem

    union all
    select cod_uf::int, 2019, ici_dh_2019::numeric
    from origem

    union all
    select cod_uf::int, 2023, ici_dh_2023::numeric
    from origem

)

select
    uf_codigo,
    ano_referencia,
    ici_valor
from longo
