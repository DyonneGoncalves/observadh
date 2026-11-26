-- Staging: Bolsa Família: PSR beneficiárias e que atenderiam ao critério de renda sem receber (CadÚnico 2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_bolsa_familia') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia_psr_benef') }} as ano_referencia,
        {{ psr_num('o.pessoas_em_situacao_de_rua_benef_do_pbc') }} as qtd_beneficiarias,
        {{ psr_num('o.pessoas_em_situacao_de_rua_que_atenderiam_ao_criterio_d') }} as qtd_elegiveis_sem_beneficio,
        {{ psr_num('o.pessoas_em_situacao_de_rua') }} as qtd_psr,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
