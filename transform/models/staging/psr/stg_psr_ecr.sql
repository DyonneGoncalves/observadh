-- Staging: Equipes de Consultório na Rua (CNES) por município × ano. '-' = sem equipe → NULL aqui.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_ecr') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge_7') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano') }} as ano_referencia,
        {{ psr_num('o.num_de_ecr') }} as qtd_ecr,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
