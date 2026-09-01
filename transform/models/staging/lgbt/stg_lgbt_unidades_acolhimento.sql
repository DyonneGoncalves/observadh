-- Staging: Unidades de Acolhimento — pessoas trans/travestis acolhidas.
-- Grão: 1 linha por UNIDADE de acolhimento (várias unidades por município;
-- a agregação por município acontece em intermediate).
--
-- Particularidades desta aba em relação às demais de Assistência Social:
--   - só tem código IBGE de 6 dígitos (não 7) -> junta com
--     dim_municipio via codigo_municipio_6dig, não codigo_municipio.
--   - não tem coluna "Ano de referência": ano fixo 2024 (nome da aba
--     "Unidades de Acolhimento 2024" -> hardcoded abaixo; ATUALIZAR se uma
--     futura carga trouxer o ano na planilha).
--
-- Nomes de coluna vêm da ingestão automática (normalizados/truncados).

with origem as (

    select *
    from {{ source('raw_lgbt', 'raw_lgbt_unidades_acolhimento') }}

),

renomeado as (

    select
        cod_ibge_6::bigint    as municipio_codigo_ibge_6dig,
        municipio             as municipio_nome,
        uf                    as uf_sigla,
        2024                  as ano_referencia,
        -- "Total de pessoas acolhidas hoje nesta unidade (Q11)"
        total_de_pessoas_acolhidas_hoje_nesta_unid_q11::numeric as qtd_pessoas_acolhidas_unidade,
        -- "Nº de travestis, transexuais e transgênero acolhidos hoje nesta unidade (q18_3)"
        no_de_trav_trans_e_transgenero_acolhidos_hoje_nesta_uni::numeric as qtd_pessoas_trans_acolhidas_unidade,
        -- "Possui pessoas trans ou travestis acolhidas hoje" (Sim/Não)
        upper(trim(possui_pessoas_trans_ou_trav_acolhidas_hoje)) = 'SIM' as possui_pessoas_trans_acolhidas,
        nm_arquivo_origem,
        dt_importacao
    from origem

)

select * from renomeado
