-- Staging: PSR ocupadas / não ocupadas (CadÚnico dez/2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_pessoas_ocupadas') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.pessoas_ocupadas') }} as qtd_ocupadas,
        {{ psr_num('o.pessoas_nao_ocupadas') }} as qtd_nao_ocupadas,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
