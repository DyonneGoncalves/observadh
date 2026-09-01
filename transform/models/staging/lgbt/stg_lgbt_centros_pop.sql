-- Staging: Centros POP — atendimento à população LGBTQIA+.
-- Grão: 1 linha por município x ano de referência.
--
-- Nomes de coluna vêm da ingestão automática (normalizados/truncados).

with origem as (

    select *
    from {{ source('raw_lgbt', 'raw_lgbt_centros_pop') }}

),

renomeado as (

    select
        cod_ibge_7::bigint            as municipio_codigo_ibge,
        nome_do_municipio            as municipio_nome,
        cod_uf::int                  as uf_codigo,
        uf                           as uf_sigla,
        ano_de_referencia::int       as ano_referencia,
        num_total_de_centros_pop::numeric                  as qtd_total_centros_pop,
        coalesce(atenderam_pessoas_lgbtqia::numeric, 0)     as qtd_atenderam_lgbt,
        coalesce(nao_atenderam_pessoas_lgbtqia::numeric, 0) as qtd_nao_atenderam_lgbt,
        nm_arquivo_origem,
        dt_importacao
    from origem

)

select * from renomeado
