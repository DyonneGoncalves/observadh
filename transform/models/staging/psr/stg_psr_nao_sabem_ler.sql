-- Staging: PSR que não sabem ler e escrever (CadÚnico dez/2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_nao_sabem_ler') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.total_psr_que_nao_sabem_ler_e_escrever') }} as qtd_nao_sabem_ler,
        {{ psr_num('o.total_pessoas_em_situacao_de_rua') }} as qtd_psr,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
