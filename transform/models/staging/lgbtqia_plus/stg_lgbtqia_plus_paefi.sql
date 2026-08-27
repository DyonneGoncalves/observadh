-- Staging: PAEFI — vítimas de discriminação por orientação sexual atendidas.
-- Grão: 1 linha por município x ano de referência.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_serie_atendimentos_paefi') }}

),

renomeado as (

    select
        "Cod_IBGE_7"::bigint                                                                                          as municipio_codigo_ibge,
        "Nome do Município"                                                                                           as municipio_nome,
        "Cod_UF"::int                                                                                                  as uf_codigo,
        "UF"                                                                                                           as uf_sigla,
        "Ano de referência"::int                                                                                       as ano_referencia,
        "Pessoas vítimas de discriminação por orientação sexual que ingressaram no PAEFI durante o mês de referência"::numeric as qtd_vitimas_paefi,
        arquivo_origem,
        id_carga,
        data_processamento
    from origem

)

select * from renomeado
