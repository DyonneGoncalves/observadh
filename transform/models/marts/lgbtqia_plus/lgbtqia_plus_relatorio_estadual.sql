-- Mart: indicadores de Proteção Social Especial (categoria 6.1) por UF.
-- Percentuais recalculados a partir dos totais agregados por UF (nunca como
-- média dos percentuais municipais — evita viés de município pequeno).

with paefi_mais_recente as (

    select *
    from (
        select *, row_number() over (partition by municipio_codigo_ibge order by ano_referencia desc) as rn
        from {{ ref('int_lgbtqia_plus_paefi_por_municipio') }}
    ) t
    where rn = 1

),

paefi_uf as (
    select uf_codigo, uf_sigla, sum(qtd_vitimas_paefi) as qtd_vitimas_paefi
    from paefi_mais_recente
    group by 1, 2
),

creas_orientacao_uf as (
    select
        uf_codigo, uf_sigla,
        sum(qtd_total_creas)                    as qtd_total_creas_orientacao,
        sum(qtd_creas_nao_atende_orientacao)     as qtd_creas_nao_atende_orientacao
    from {{ ref('int_lgbtqia_plus_creas_orientacao_por_municipio') }}
    group by 1, 2
),

creas_identidade_uf as (
    select
        uf_codigo, uf_sigla,
        sum(qtd_total_creas)                    as qtd_total_creas_identidade,
        sum(qtd_creas_nao_atende_identidade)     as qtd_creas_nao_atende_identidade
    from {{ ref('int_lgbtqia_plus_creas_identidade_por_municipio') }}
    group by 1, 2
),

centros_pop_uf as (
    select
        uf_codigo, uf_sigla,
        sum(qtd_total_centros_pop)   as qtd_total_centros_pop,
        sum(qtd_atenderam_lgbtqia)   as qtd_atenderam_lgbtqia
    from {{ ref('int_lgbtqia_plus_centros_pop_por_municipio') }}
    group by 1, 2
),

acolhimento_uf as (
    select
        uf_codigo, uf_sigla,
        sum(qtd_unidades_acolhimento)         as qtd_unidades_acolhimento,
        sum(qtd_unidades_com_pessoas_trans)   as qtd_unidades_com_pessoas_trans,
        sum(qtd_pessoas_acolhidas_total)      as qtd_pessoas_acolhidas_total,
        sum(qtd_pessoas_trans_acolhidas_total) as qtd_pessoas_trans_acolhidas_total
    from {{ ref('int_lgbtqia_plus_acolhimento_por_municipio') }}
    group by 1, 2
),

base_uf as (

    select distinct codigo_uf as uf_codigo, sigla_uf as uf_sigla, nome_uf
    from {{ ref('dim_uf') }}

)

select
    b.uf_codigo,
    b.uf_sigla,
    b.nome_uf,

    p.qtd_vitimas_paefi,

    co.qtd_total_creas_orientacao,
    co.qtd_creas_nao_atende_orientacao,
    {{ calcula_percentual('co.qtd_creas_nao_atende_orientacao', 'co.qtd_total_creas_orientacao') }} as pct_creas_nao_atende_orientacao,

    ci.qtd_total_creas_identidade,
    ci.qtd_creas_nao_atende_identidade,
    {{ calcula_percentual('ci.qtd_creas_nao_atende_identidade', 'ci.qtd_total_creas_identidade') }} as pct_creas_nao_atende_identidade,

    cp.qtd_total_centros_pop,
    cp.qtd_atenderam_lgbtqia,
    {{ calcula_percentual('cp.qtd_atenderam_lgbtqia', 'cp.qtd_total_centros_pop') }} as pct_centros_pop_atenderam_lgbtqia,

    ac.qtd_unidades_acolhimento,
    ac.qtd_unidades_com_pessoas_trans,
    {{ calcula_percentual('ac.qtd_unidades_com_pessoas_trans', 'ac.qtd_unidades_acolhimento') }} as pct_unidades_com_pessoas_trans,
    ac.qtd_pessoas_acolhidas_total,
    ac.qtd_pessoas_trans_acolhidas_total

from base_uf b
left join paefi_uf              p  on p.uf_codigo = b.uf_codigo
left join creas_orientacao_uf   co on co.uf_codigo = b.uf_codigo
left join creas_identidade_uf   ci on ci.uf_codigo = b.uf_codigo
left join centros_pop_uf        cp on cp.uf_codigo = b.uf_codigo
left join acolhimento_uf        ac on ac.uf_codigo = b.uf_codigo
