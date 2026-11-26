-- Staging: PSR por tipo de deficiência (CadÚnico dez/2024). Grão: município.
-- A aba tem linhas TOTAL/PERCENT no rodapé (sem código) — descartadas.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_perfil_tipo_deficiencia') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.cegueira') }} as qtd_cegueira,
        {{ psr_num('o.baixa_visao') }} as qtd_baixa_visao,
        {{ psr_num('o.surdez_severa') }} as qtd_surdez_severa,
        {{ psr_num('o.surdez_leve') }} as qtd_surdez_leve,
        {{ psr_num('o.fisica') }} as qtd_fisica,
        {{ psr_num('o.intelectual') }} as qtd_intelectual,
        {{ psr_num('o.sindrome_de_down') }} as qtd_sindrome_de_down,
        {{ psr_num('o.transtorno_mental') }} as qtd_transtorno_mental,
        {{ psr_num('o.total_com_info_sobre_deficiencia') }} as qtd_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
