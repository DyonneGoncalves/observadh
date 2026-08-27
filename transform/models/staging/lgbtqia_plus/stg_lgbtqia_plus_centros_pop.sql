-- Staging: Centros POP — atendimento à população LGBTQIA+.
-- Grão: 1 linha por município x ano de referência.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_centros_pop') }}

),

renomeado as (

    select
        "Cod_IBGE_7"::bigint                          as municipio_codigo_ibge,
        "Nome do Município"                           as municipio_nome,
        "Cod_UF"::int                                 as uf_codigo,
        "UF"                                           as uf_sigla,
        "Ano de referência"::int                       as ano_referencia,
        "Número total de Centros Pop"::numeric         as qtd_total_centros_pop,
        coalesce("Atenderam pessoas LGBTQIA+"::numeric, 0)      as qtd_atenderam_lgbtqia,
        coalesce("Não atenderam pessoas LGBTQIA+"::numeric, 0)  as qtd_nao_atenderam_lgbtqia,
        arquivo_origem,
        id_carga,
        data_processamento
    from origem

)

select * from renomeado
