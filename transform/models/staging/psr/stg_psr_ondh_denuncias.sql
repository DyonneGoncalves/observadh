-- Staging: Denúncias e violações ONDH (2020-2024). Grão: município × ano.
-- Código de 6 dígitos → 7 via dim_municipio. A linha "Ignorado" (código 0)
-- é mantida com municipio_codigo_ibge = 0: entra só no total nacional.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_ondh_serie') }}
),

-- código de 6 dígitos → 7 dígitos (dim_municipio). Código 0 = Ignorado.
dim_mun as (
    select codigo_municipio_6dig::int as cod6, codigo_municipio::int as cod7
    from {{ ref('dim_municipio') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as cod6,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.qtd_de_denuncias') }} as qtd_denuncias,
        {{ psr_num('o.qtd_de_violacoes') }} as qtd_violacoes,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select
    case when t.cod6 = 0 then 0 else d.cod7 end as municipio_codigo_ibge,
    t.*
from tipado t
left join dim_mun d on d.cod6 = t.cod6
where t.cod6 is not null
