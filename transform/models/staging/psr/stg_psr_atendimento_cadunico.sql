-- Staging: PSR atendidas por serviço de assistência social, segundo o CadÚnico (2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_atendimento_cadunico') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.cras') }} as qtd_cras,
        {{ psr_num('o.creas') }} as qtd_creas,
        {{ psr_num('o.instituicao_governamental') }} as qtd_inst_governamental,
        {{ psr_num('o.instituicao_nao_governamental') }} as qtd_inst_nao_governamental,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
