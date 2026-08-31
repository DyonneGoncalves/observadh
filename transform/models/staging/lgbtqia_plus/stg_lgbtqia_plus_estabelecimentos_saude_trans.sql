-- Staging: estabelecimentos de saúde habilitados para atenção a pessoas trans
-- (procedimentos ambulatoriais e/ou hospitalares), CNES 2025 — seção 5.1.
--
-- Grão: 1 linha por estabelecimento. As 12 UFs sem nenhum estabelecimento
-- vêm na planilha como 1 linha "Não possui" (cnes = 0) — mantidas aqui com
-- possui_servico = false para permitir a contagem de UFs sem serviço.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_estabelecimento_cnes') }}

),

renomeado as (

    select
        cod_uf::int                                as uf_codigo,
        uf                                         as uf_sigla,
        estado                                     as uf_nome,
        regiao                                     as regiao,
        ano_de_referencia::int                     as ano_referencia,
        nullif(cnes, 0)::bigint                    as cnes_codigo,
        nullif(estabelecimento, 'Não possui')     as estabelecimento_nome,
        nullif(tipo_de_habilitacao, 'Não possui') as tipo_habilitacao,
        (tipo_de_habilitacao <> 'Não possui')     as possui_servico,
        nm_arquivo_origem,
        dt_importacao
    from origem

)

select * from renomeado
