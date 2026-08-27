-- Staging: PAEFI — vítimas de discriminação por orientação sexual atendidas.
-- Grão: 1 linha por município x ano de referência.
--
-- Nomes de coluna vêm da ingestão automática (normalizados e truncados em
-- 55 caracteres). O nome longo original está no comentário ao lado.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_serie_atendimentos_paefi') }}

),

renomeado as (

    select
        cod_ibge_7::bigint          as municipio_codigo_ibge,
        nome_do_municipio           as municipio_nome,
        cod_uf::int                 as uf_codigo,
        uf                          as uf_sigla,
        ano_de_referencia::int      as ano_referencia,
        -- "Pessoas vítimas de discriminação por orientação sexual que
        --  ingressaram no PAEFI durante o mês de referência"
        pessoas_vitimas_de_discrim_por_orient_sexual_que_ingres::numeric as qtd_vitimas_paefi,
        nm_arquivo_origem,
        dt_importacao
    from origem

)

select * from renomeado
