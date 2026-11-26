-- Staging: PSR (dez/2024) e população total IBGE 2024. Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_distribuicao_territorial') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.pop_total_do_municipio_ibge_2024') }} as qtd_pop_total,
        {{ psr_num('o.pop_em_situacao_de_rua_no_cadastro_unico_dezembro_2024') }} as qtd_psr,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
