-- Staging: escolas com projeto de enfrentamento à LGBTQIAfobia por UF e
-- localização (Urbana/Rural), SAEB 2021 — seção 4.1.
-- Grão: 1 linha por UF x localização.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_projeto_homofobia_local_2021') }}

)

select
    cod_uf::int                    as uf_codigo,
    uf                             as uf_sigla,
    ano_de_referencia::int         as ano,
    localizacao                    as localizacao,
    total_com_info::bigint         as qtd_total_com_info,
    escolas_com_projeto::bigint    as qtd_escolas_com_projeto
from origem
