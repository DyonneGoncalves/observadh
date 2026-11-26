-- Staging: PSR por gênero (CadÚnico dez/2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_perfil_genero') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.masc') }} as qtd_masculino,
        {{ psr_num('o.fem') }} as qtd_feminino,
        {{ psr_num('o.total_psr_com_info_gen_dez_2024') }} as qtd_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
