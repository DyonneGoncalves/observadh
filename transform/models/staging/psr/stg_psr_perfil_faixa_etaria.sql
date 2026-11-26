-- Staging: PSR por faixa etária (CadÚnico dez/2024), formato largo. Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_perfil_faixa_etaria') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o."0_a_5_anos"') }} as qtd_0_a_5_anos,
        {{ psr_num('o."6_a_11_anos"') }} as qtd_6_a_11_anos,
        {{ psr_num('o."12_a_17_anos"') }} as qtd_12_a_17_anos,
        {{ psr_num('o."18_a_29_anos"') }} as qtd_18_a_29_anos,
        {{ psr_num('o."30_a_39_anos"') }} as qtd_30_a_39_anos,
        {{ psr_num('o."40_a_49_anos"') }} as qtd_40_a_49_anos,
        {{ psr_num('o."50_a_59_anos"') }} as qtd_50_a_59_anos,
        {{ psr_num('o."60_a_69_anos"') }} as qtd_60_a_69_anos,
        {{ psr_num('o."70_a_79_anos"') }} as qtd_70_a_79_anos,
        {{ psr_num('o."80_a_89_anos"') }} as qtd_80_a_89_anos,
        {{ psr_num('o."90_a_99_anos"') }} as qtd_90_a_99_anos,
        {{ psr_num('o."100_anos_ou_mais"') }} as qtd_100_anos_ou_mais,
        {{ psr_num('o.total_com_info_idade_dez_2024') }} as qtd_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
