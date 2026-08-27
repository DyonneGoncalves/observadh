-- Staging: CREAS — atendimento a discriminação por orientação sexual.
-- Grão: 1 linha por município x ano de referência.
-- A planilha já traz "Discriminação por orientação sexual - Não atende este
-- tipo de situação" como percentual pré-calculado por município — mantemos
-- como golden value (pct_nao_atende_orientacao_fonte) para validar nosso
-- próprio cálculo em intermediate (ver tests/).

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_creas_discriminacao_orientacao') }}

),

renomeado as (

    select
        "Cod_IBGE_7"::bigint                                                             as municipio_codigo_ibge,
        "Nome do Município"                                                              as municipio_nome,
        "Cod_UF"::int                                                                    as uf_codigo,
        "UF"                                                                             as uf_sigla,
        "Ano de referência"::int                                                         as ano_referencia,
        "Total de CREAS"::numeric                                                        as qtd_total_creas,
        "Não atende este tipo de situação"::numeric                                      as qtd_creas_nao_atende_orientacao,
        "Discriminação por orientação sexual - Não atende este tipo de situação"::numeric as pct_nao_atende_orientacao_fonte,
        arquivo_origem,
        id_carga,
        data_processamento
    from origem

)

select * from renomeado
