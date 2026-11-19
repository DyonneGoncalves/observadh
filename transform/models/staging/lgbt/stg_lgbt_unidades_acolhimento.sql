-- Staging: Unidades de Acolhimento — pessoas trans/travestis acolhidas.
-- Grão: 1 linha por UNIDADE de acolhimento (várias unidades por município;
-- a agregação por município acontece em intermediate).
--
-- Fonte: aba "Atendimentos Trans" do arquivo
-- "Cálculo_Assistência social_Unidade Acolhimento_2024.xlsx" (reenvio da
-- equipe, nov/2026). Diferente da aba antiga "Unidades de Acolhimento 2024":
--   - traz NU_IDENTIFICADOR_UNIDADE -> chave da unidade (teste unique/not_null
--     no source). Não usamos mais `select distinct`: nesta base há ~800
--     unidades GENUÍNAS com todos os atributos iguais a outra unidade do mesmo
--     município (ex.: duas casas-lar com 10 acolhidos e 0 trans) — o distinct
--     as colapsava, e as duplicatas da aba antiga mascaravam o efeito. Era a
--     causa do gap 6.568/1.124 vs 6.538/1.126 da equipe (e de AL 56 vs 53).
--   - traz Cod_IBGE_7 -> join direto com dim_municipio.codigo_municipio.
--   - traz "Ano de referência" -> não precisa mais de ano fixo no código.
--
-- Contagens chegam como texto quando a célula está em branco (1 unidade de
-- Santo Antônio de Jesus/BA vem com "possui = SIM" e Q11/q18_3 vazios):
-- nullif(trim(..)) evita erro de cast; a unidade continua contando como
-- unidade com pessoa trans (igual à tabela dinâmica da equipe) e não soma
-- pessoas.
--
-- Nomes de coluna vêm da ingestão automática (normalizados/truncados).

with origem as (

    select *
    from {{ source('raw_lgbt', 'raw_lgbt_unidades_acolhimento') }}

),

renomeado as (

    select
        nu_identificador_unid::bigint      as unidade_id,
        cod_ibge_7::bigint                 as municipio_codigo_ibge,
        cod_ibge_6::bigint                 as municipio_codigo_ibge_6dig,
        municipio                          as municipio_nome,
        uf                                 as uf_sigla,
        ano_de_referencia::int             as ano_referencia,
        -- "Total de pessoas acolhidas hoje nesta unidade (Q11)"
        nullif(trim(total_de_pessoas_acolhidas_hoje_nesta_unid_q11::text), '')::numeric
                                           as qtd_pessoas_acolhidas_unidade,
        -- "Nº de travestis, transexuais e transgênero acolhidos hoje nesta unidade (q18_3)"
        nullif(trim(no_de_trav_trans_e_transgenero_acolhidos_hoje_nesta_uni::text), '')::numeric
                                           as qtd_pessoas_trans_acolhidas_unidade,
        -- "Possui pessoas trans ou travestis acolhidas hoje" (SIM/NÃO)
        upper(trim(possui_pessoas_trans_ou_trav_acolhidas_hoje)) = 'SIM'
                                           as possui_pessoas_trans_acolhidas,
        -- respondeu Sim ou Não (denominador do %, chamado 27607): unidades
        -- sem resposta ficam fora, como pede a fórmula "(Sim) / (Sim e Não)".
        -- Na carga de nov/2026 todas as 6.538 unidades responderam.
        upper(trim(possui_pessoas_trans_ou_trav_acolhidas_hoje)) in ('SIM', 'NÃO', 'NAO')
                                           as respondeu_pessoas_trans_acolhidas,
        nm_arquivo_origem,
        dt_importacao
    from origem

)

select * from renomeado
