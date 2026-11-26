-- Staging: Atendimentos individuais das eCR (Sisab). Só municípios com atendimento. Grão: município × ano.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_atendimentos_ecr') }}
),

tipado as (
    select
        {{ codigo_num('o.ibge_7') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano') }} as ano_referencia,
        {{ psr_num('o.total_de_atend') }} as qtd_atendimentos,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
