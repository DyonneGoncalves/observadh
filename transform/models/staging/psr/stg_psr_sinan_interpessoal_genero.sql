-- Staging: Vítimas de violência interpessoal (SINAN 2024) por gênero. Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_sinan_interpessoal_genero') }}
),

-- código de 6 dígitos → 7 dígitos (dim_municipio). Código 0 = Ignorado.
dim_mun as (
    select codigo_municipio_6dig::int as cod6, codigo_municipio::int as cod7
    from {{ ref('dim_municipio') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as cod6,
        {{ codigo_num('o.ano_de_referencia_notif_de_viol_interpesssoal_de_gen_ps') }} as ano_referencia,
        {{ psr_num('o.fem') }} as qtd_feminino,
        {{ psr_num('o.masc') }} as qtd_masculino,
        {{ psr_num('o.total_com_info_de_gen') }} as qtd_total_com_info,
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
