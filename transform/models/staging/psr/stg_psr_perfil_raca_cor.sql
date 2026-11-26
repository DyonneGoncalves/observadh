-- Staging: PSR por cor (CadÚnico 2024) e população geral por cor (Censo 2022). Grão: município.
-- '-' em qtd_pop_amarela/qtd_pop_indigena (supressão do IBGE) vira NULL aqui —
-- no municipal o % daquela cor fica sem dado; nas somas estadual/nacional conta 0.
-- As linhas de soma sem código no rodapé da aba são descartadas.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_perfil_raca_cor') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia_cadastro_unico') }} as ano_referencia,
        {{ psr_num('o.psr_branca') }} as qtd_psr_branca,
        {{ psr_num('o.psr_preta') }} as qtd_psr_preta,
        {{ psr_num('o.psr_amarela') }} as qtd_psr_amarela,
        {{ psr_num('o.psr_parda') }} as qtd_psr_parda,
        {{ psr_num('o.psr_indigena') }} as qtd_psr_indigena,
        {{ psr_num('o.total_psr_com_info_cor') }} as qtd_psr_total_com_info,
        {{ codigo_num('o.ano_de_referencia_censo_ibge') }} as ano_censo,
        {{ psr_num('o.total_branca') }} as qtd_pop_branca,
        {{ psr_num('o.total_preta') }} as qtd_pop_preta,
        {{ psr_num('o.total_amarela') }} as qtd_pop_amarela,
        {{ psr_num('o.total_parda') }} as qtd_pop_parda,
        {{ psr_num('o.total_indigena') }} as qtd_pop_indigena,
        {{ psr_num('o.pop_total_com_info_cor') }} as qtd_pop_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
