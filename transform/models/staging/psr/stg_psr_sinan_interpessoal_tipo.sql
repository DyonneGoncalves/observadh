-- Staging: Violência interpessoal (SINAN 2024) por tipo. Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_sinan_interpessoal_tipo') }}
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
        {{ psr_num('o.fisica') }} as qtd_fisica,
        {{ psr_num('o.psicologica_moral') }} as qtd_psicologica_moral,
        {{ psr_num('o.tortura') }} as qtd_tortura,
        {{ psr_num('o.sexual') }} as qtd_sexual,
        {{ psr_num('o.trafico_de_seres_dh') }} as qtd_trafico_de_seres_humanos,
        {{ psr_num('o.financeira_economica') }} as qtd_financeira_economica,
        {{ psr_num('o.negligencia_abandono') }} as qtd_negligencia_abandono,
        {{ psr_num('o.trab_infantil') }} as qtd_trabalho_infantil,
        {{ psr_num('o.intervencao_legal') }} as qtd_intervencao_legal,
        {{ psr_num('o.outros') }} as qtd_outros,
        {{ psr_num('o.total_de_notif_com_resposta_para_outros_tipos_de_viol_v') }} as qtd_total_com_resposta,
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
