-- Valida a seção 6.1 ESTADUAL — Alagoas (UF 27), valores da CGTI (chamado 27607).
-- Falha (retorna linhas) se algum valor divergir.
--   vitimas_paefi_2017_2024: soma 2017-2024 = 141 (o relatório mostrava 9 = só 2024)
--   pct_unidades_acolhimento_com_pessoas_trans: 7,55% (4/53), como aponta a CGTI
--   demais valores do mesmo trecho, que a área marcou como corretos
-- Também confere, para todas as UFs, que vitimas_paefi_2017_2024 = soma da série.

with esperado (indicador, valor, tolerancia) as (
    values
        ('vitimas_paefi_2017_2024',                    141.0,  0.0),
        ('vitimas_paefi',                                9.0,  0.0),
        ('creas_total',                                 96.0,  0.0),
        ('pct_creas_nao_atende_orientacao',             80.2,  0.05),
        ('pct_creas_nao_atende_identidade',             84.4,  0.05),
        ('centros_pop_total',                            5.0,  0.0),
        ('pct_centros_pop_atenderam_lgbt',             100.0,  0.05),
        -- Acolhimento: 53 unidades (1 por NU_IDENTIFICADOR_UNIDADE), 4 com
        -- pessoas trans -> 7,55%. Resolvido com a aba "Atendimentos Trans"
        -- reenviada pela equipe (antes: 56 unidades pelo select distinct, 7,14%).
        ('unidades_acolhimento_total',                  53.0,  0.0),
        ('pct_unidades_acolhimento_com_pessoas_trans',   7.55, 0.01),
        ('pessoas_trans_acolhidas_total',               17.0,  0.0)
),

obtido as (
    select indicador, valor
    from {{ ref('lgbt_indicadores') }}
    where secao = '6.1' and nivel = 'estadual' and recorte_codigo = 27
),

soma_serie as (
    select recorte_codigo, sum(valor) as soma
    from {{ ref('lgbt_indicadores') }}
    where secao = '6.1' and nivel = 'estadual' and indicador = 'vitimas_paefi_serie_historica'
    group by recorte_codigo
),

periodo as (
    select recorte_codigo, valor
    from {{ ref('lgbt_indicadores') }}
    where secao = '6.1' and nivel = 'estadual' and indicador = 'vitimas_paefi_2017_2024'
)

select 'alagoas' as verificacao, e.indicador, null::int as recorte_codigo,
       e.valor as esperado, o.valor as obtido
from esperado e
left join obtido o on o.indicador = e.indicador
where o.valor is null or abs(o.valor - e.valor) > e.tolerancia

union all

select 'soma_serie', 'vitimas_paefi_2017_2024', s.recorte_codigo, s.soma, p.valor
from soma_serie s
left join periodo p on p.recorte_codigo = s.recorte_codigo
where p.valor is distinct from s.soma
