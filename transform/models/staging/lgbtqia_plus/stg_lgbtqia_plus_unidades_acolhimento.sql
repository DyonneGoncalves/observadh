-- Staging: Unidades de Acolhimento — pessoas trans/travestis acolhidas.
-- Grão: 1 linha por UNIDADE de acolhimento (várias unidades por município;
-- a agregação por município acontece em intermediate).
--
-- Particularidades desta aba em relação às demais de Assistência Social:
--   - só tem código IBGE de 6 dígitos (não 7) -> junta com
--     dim_municipio via codigo_municipio_6dig, não codigo_municipio.
--   - não tem coluna "Ano de referência": ano é fixo 2026 (nome da aba
--     "Unidades de Acolhimento 2024" indica o ano de referência dos DADOS
--     é 2024, mesmo a aba tendo sido recebida no ciclo 2026 -> hardcoded
--     abaixo; ATUALIZAR se uma futura carga trouxer o ano na planilha).

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_unidades_acolhimento') }}

),

renomeado as (

    select
        "COD_IBGE 6"::bigint                                                                       as municipio_codigo_ibge_6dig,
        "Município"                                                                                as municipio_nome,
        "UF"                                                                                       as uf_sigla,
        2024                                                                                       as ano_referencia,
        "Total de pessoas acolhidas hoje nesta unidade (Q11)"::numeric                             as qtd_pessoas_acolhidas_unidade,
        "Nº de travestis, transexuais e transgênero acolhidos hoje nesta unidade (q18_3)"::numeric  as qtd_pessoas_trans_acolhidas_unidade,
        upper(trim("Possui pessoas trans ou travestis acolhidas hoje")) = 'SIM'                     as possui_pessoas_trans_acolhidas,
        arquivo_origem,
        id_carga,
        data_processamento
    from origem

)

select * from renomeado
