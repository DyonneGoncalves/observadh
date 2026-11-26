-- Staging: Frequência escolar das PSR por faixa etária (CadÚnico dez/2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_frequencia_escolar') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.frequentam_a_escola_0_a_5_anos') }} as qtd_freq_0_5,
        {{ psr_num('o.pessoas_em_situacao_de_rua_0_a_5_anos') }} as qtd_psr_0_5,
        {{ psr_num('o.frequentam_a_escola_6_a_11_anos') }} as qtd_freq_6_11,
        {{ psr_num('o.pessoas_em_situacao_de_rua_6_a_11_anos') }} as qtd_psr_6_11,
        {{ psr_num('o.frequentam_a_escola_12_a_17_anos') }} as qtd_freq_12_17,
        {{ psr_num('o.pessoas_em_situacao_de_rua_12_a_17_anos') }} as qtd_psr_12_17,
        {{ psr_num('o.frequentam_a_escola_18_a_24_anos') }} as qtd_freq_18_24,
        {{ psr_num('o.pessoas_em_situacao_de_rua_18_a_24_anos') }} as qtd_psr_18_24,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
