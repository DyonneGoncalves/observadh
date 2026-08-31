-- Staging: PNS 2019 — população por natureza jurídica da união e orientação
-- sexual (Brasil). Grão: 1 linha por orientação sexual x natureza (formato longo).

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_natureza_juridica_uniao') }}

),

renomeado as (

    select
        tipo_de_orient_sexual                                as orientacao_sexual,
        casam_civil::bigint                                  as casamento_civil,
        uniao_estavel::bigint                                as uniao_estavel,
        total_com_info_de_natureza_juridica_da_uniao::bigint as total_com_info
    from origem

),

longo as (

    select
        r.orientacao_sexual,
        v.natureza_juridica,
        v.quantidade::bigint  as quantidade,
        r.total_com_info
    from renomeado r
    cross join lateral (values
        ('Casamento civil', r.casamento_civil),
        ('União estável',   r.uniao_estavel)
    ) as v(natureza_juridica, quantidade)

)

select * from longo
