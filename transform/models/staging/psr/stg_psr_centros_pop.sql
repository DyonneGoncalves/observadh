-- Staging: Centros Pop cadastrados (Censo SUAS) por município × ano (2017-2023).
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_centros_pop') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano') }} as ano_referencia,
        {{ psr_num('o.centros_pop_cadastrados') }} as qtd_centros_pop,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
