-- Staging: PNS 2019 — população por estado civil e orientação sexual (Brasil).
-- Grão: 1 linha por orientação sexual x estado civil (formato longo).

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_pessoas_estado_civil') }}

),

renomeado as (

    select
        tipo_de_orient_sexual                                     as orientacao_sexual,
        casado_a::bigint                                          as casado,
        divorciado_a_ou_desquitado_a_ou_separado_a_judicialment::bigint as divorciado_separado,
        viuvo_a::bigint                                           as viuvo,
        solteiro_a::bigint                                        as solteiro,
        total_com_info_de_estado_civil::bigint                    as total_com_info
    from origem

),

longo as (

    select
        r.orientacao_sexual,
        v.estado_civil,
        v.quantidade::bigint  as quantidade,
        r.total_com_info
    from renomeado r
    cross join lateral (values
        ('Casado(a)',                    r.casado),
        ('Divorciado(a)/separado(a)',    r.divorciado_separado),
        ('Viúvo(a)',                     r.viuvo),
        ('Solteiro(a)',                  r.solteiro)
    ) as v(estado_civil, quantidade)

)

select * from longo
