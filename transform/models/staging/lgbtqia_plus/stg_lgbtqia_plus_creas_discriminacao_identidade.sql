-- Staging: CREAS — atendimento a discriminação por identidade de gênero.
-- Mesmo padrão de stg_lgbtqia_plus_creas_discriminacao_orientacao.sql.
--
-- Atenção: as duas colunas de "não atende" da planilha (contagem e %)
-- normalizam para o mesmo nome; a ingestão desambigua com sufixo _1 na
-- segunda ocorrência. Aqui: sem sufixo = contagem (bigint na origem),
-- com _1 = percentual pré-calculado (double na origem).

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_creas_discriminacao_identidade') }}

),

renomeado as (

    select
        cod_ibge_7::bigint         as municipio_codigo_ibge,
        nome_do_municipio          as municipio_nome,
        cod_uf::int                as uf_codigo,
        uf                         as uf_sigla,
        ano_de_referencia::int     as ano_referencia,
        total_de_creas::numeric    as qtd_total_creas,
        -- "Discriminação por identidade de gênero - Não atende este tipo de
        --  situação" (contagem)
        discrim_por_ident_de_gen_nao_atende_este_tipo_de_situac::numeric as qtd_creas_nao_atende_identidade,
        -- "% Discriminação por identidade de gênero - Não atende este tipo
        --  de situação" (percentual pré-calculado na planilha)
        discrim_por_ident_de_gen_nao_atende_este_tipo_de_situ_1::numeric as pct_nao_atende_identidade_fonte,
        nm_arquivo_origem,
        dt_importacao
    from origem

)

select * from renomeado
