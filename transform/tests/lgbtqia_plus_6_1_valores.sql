-- Valida a seção 6.1 (nível nacional) — os mesmos números do antigo mart
-- largo lgbtqia_plus_relatorio_nacional, conferidos na primeira execução real
-- do piloto contra a planilha de cálculo da equipe.

with esperado (indicador, valor) as (
    values
        ('vitimas_paefi',                              1528.0),
        ('pct_creas_nao_atende_orientacao',              60.60),
        ('pct_creas_nao_atende_identidade',              69.61),
        ('pct_centros_pop_atenderam_lgbtqia',            97.25),
        ('unidades_acolhimento_total',                 7465.0),
        ('pct_unidades_acolhimento_com_pessoas_trans',    7.11)
),

obtido as (
    select indicador, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where secao = '6.1' and nivel = 'nacional'
)

select e.indicador, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o on o.indicador = e.indicador
where o.valor is null or abs(o.valor - e.valor) > 0.01
