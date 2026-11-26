-- Staging: Taxa de analfabetismo 15+: PSR (CadÚnico 2024) e população geral (Censo 2022). Só municípios com PSR 15+ (2.682).
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_analfabetismo') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia_psr_sabem_ler_e_escrevercadunico') }} as ano_referencia,
        {{ psr_num('o.psr_com_15_anos_ou_mais_que_nao_sabem_ler_e_escrever_ca') }} as qtd_psr_15_mais_analfabeta,
        {{ psr_num('o.total_de_psr_com_15_anos_ou_mais_cadunico_2024') }} as qtd_psr_15_mais,
        {{ codigo_num('o.ano_de_referencia_pop_censo_demografico') }} as ano_censo,
        {{ psr_num('o.pop_com_15_anos_ou_mais_que_nao_sabe_ler_e_escrever_cen') }} as qtd_pop_15_mais_analfabeta,
        {{ psr_num('o.pop_geral_com_15_anos_ou_mais_censo_demografico_2022') }} as qtd_pop_15_mais,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
