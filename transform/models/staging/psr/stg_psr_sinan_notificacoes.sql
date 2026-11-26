-- Staging: Notificações de violência contra PSR no SINAN (2015-2024). Grão: município de ocorrência × ano.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_sinan_serie') }}
),

-- código de 6 dígitos → 7 dígitos (dim_municipio). Código 0 = Ignorado.
dim_mun as (
    select codigo_municipio_6dig::int as cod6, codigo_municipio::int as cod7
    from {{ ref('dim_municipio') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge_de_ocorrencia') }} as cod6,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.total_de_notif_de_viol_tendo_como_vitima_a_pessoa_em_si') }} as qtd_notificacoes,
        {{ psr_num('o.viol_autoprovocada') }} as qtd_autoprovocada,
        {{ psr_num('o.viol_interpessoal') }} as qtd_interpessoal,
        {{ psr_num('o.origem_da_viol_nao_informada') }} as qtd_origem_nao_informada,
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
