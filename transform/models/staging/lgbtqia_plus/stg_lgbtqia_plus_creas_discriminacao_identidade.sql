-- Staging: CREAS — atendimento a discriminação por identidade de gênero.
-- Mesmo padrão de stg_lgbtqia_plus_creas_discriminacao_orientacao.sql.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_creas_discriminacao_identidade') }}

),

renomeado as (

    select
        "Cod_IBGE_7"::bigint                                                                as municipio_codigo_ibge,
        "Nome do Município"                                                                 as municipio_nome,
        "Cod_UF"::int                                                                       as uf_codigo,
        "UF"                                                                                as uf_sigla,
        "Ano de referência"::int                                                            as ano_referencia,
        "Total de CREAS"::numeric                                                           as qtd_total_creas,
        "Discriminação por identidade de gênero - Não atende este tipo de situação"::numeric as qtd_creas_nao_atende_identidade,
        "% Discriminação por identidade de gênero - Não atende este tipo de situação"::numeric as pct_nao_atende_identidade_fonte,
        arquivo_origem,
        id_carga,
        data_processamento
    from origem

)

select * from renomeado
