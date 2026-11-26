-- Staging: PSR com/sem deficiência (CadÚnico dez/2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_perfil_existencia_deficiencia') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.pessoa_com_deficiencia') }} as qtd_com_deficiencia,
        {{ psr_num('o.pessoa_sem_deficiencia') }} as qtd_sem_deficiencia,
        {{ psr_num('o.total_com_info_sobre_deficiencia') }} as qtd_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
