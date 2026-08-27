-- Staging: CREAS — atendimento a discriminação por orientação sexual.
-- Grão: 1 linha por município x ano de referência.
-- A planilha já traz o percentual pré-calculado por município — mantemos
-- como golden value (pct_nao_atende_orientacao_fonte) para validar nosso
-- próprio cálculo em intermediate (ver tests/).
--
-- Nomes de coluna vêm da ingestão automática (normalizados/truncados).

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_creas_discriminacao_orientacao') }}

),

renomeado as (

    select
        cod_ibge_7::bigint         as municipio_codigo_ibge,
        nome_do_municipio          as municipio_nome,
        cod_uf::int                as uf_codigo,
        uf                         as uf_sigla,
        ano_de_referencia::int     as ano_referencia,
        total_de_creas::numeric    as qtd_total_creas,
        -- "Não atende este tipo de situação" (contagem)
        nao_atende_este_tipo_de_situacao::numeric as qtd_creas_nao_atende_orientacao,
        -- "Discriminação por orientação sexual - Não atende este tipo de
        --  situação" (percentual pré-calculado na planilha)
        discrim_por_orient_sexual_nao_atende_este_tipo_de_situa::numeric as pct_nao_atende_orientacao_fonte,
        nm_arquivo_origem,
        dt_importacao
    from origem

)

select * from renomeado
