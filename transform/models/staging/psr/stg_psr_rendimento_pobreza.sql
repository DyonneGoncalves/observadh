-- Staging: Renda familiar per capita abaixo da linha da pobreza (R$ 665) e da extrema pobreza (R$ 209). Grão: município.
-- Sem coluna de ano na aba: fixado em 2024 (var psr_ano_referencia).
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_rendimento_pobreza') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ var('psr_ano_referencia') }}::int as ano_referencia,
        {{ psr_num('o.pessoas_com_renda_familiar_abaixo_da_linha_da_pobreza_r') }} as qtd_abaixo_linha_pobreza,
        {{ psr_num('o.pessoas_com_renda_familiar_abaixo_da_linha_da_extrema_p') }} as qtd_extrema_pobreza,
        {{ psr_num('o.total_de_pessoas_em_situacao_de_rua_com_informacao') }} as qtd_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
