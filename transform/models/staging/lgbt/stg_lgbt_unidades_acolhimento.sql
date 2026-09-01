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
--
-- DEDUP: a aba ingerida tem 7.465 linhas mas só 6.568 distintas — 897 linhas
-- são cópias exatas (o arquivo foi montado concatenando dois extratos que se
-- sobrepõem; a concentração é SP/RS/MG/PR/RJ). Sem a coluna de identificador
-- da unidade (NU_IDENTIFICADOR_UNIDADE, que a equipe usa no cálculo e não veio
-- nesta aba) o melhor que dá é remover as linhas 100% idênticas. Isso leva
-- "pessoas trans acolhidas" de 1.253 -> 1.124 (relatório: 1.126; resíduo de 2
-- unidades genuínas com atributos iguais que o distinct também colapsa).
-- ATUALIZAR para dedup por NU_IDENTIFICADOR_UNIDADE quando a aba correta chegar.

with origem as (

    select distinct
        cod_ibge_6,
        municipio,
        uf,
        total_de_pessoas_acolhidas_hoje_nesta_unid_q11,
        no_de_trav_trans_e_transgenero_acolhidos_hoje_nesta_uni,
        possui_pessoas_trans_ou_trav_acolhidas_hoje,
        nm_arquivo_origem,
        dt_importacao
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
