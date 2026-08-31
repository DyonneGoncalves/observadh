-- Valida a seção 3 (nacional) contra a planilha de cálculo
-- (Cálculo_LGBTQIA_Trabalho_PNS_2019). Falha se algum valor divergir (tol. 0,01).

with esperado (indicador, categoria, valor) as (
    values
        ('pct_pessoas_ocupadas_por_orientacao', 'Heterossexual', 92.3),
        ('pct_pessoas_ocupadas_por_orientacao', 'Homossexual',   89.6),
        ('pct_pessoas_ocupadas_por_orientacao', 'Bissexual',     84.8),
        ('pct_renda_per_capita_por_orientacao', 'Homossexual / Mais de 5 salários mínimos',  11.989110),
        ('pct_renda_per_capita_por_orientacao', 'Heterossexual / Mais de 1 a 3 salários mínimos', 37.316496),
        ('pct_renda_per_capita_por_orientacao', 'Bissexual / Mais de 3 a 5 salários mínimos', 12.344347)
),

obtido as (
    select indicador, categoria, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where secao = '3' and nivel = 'nacional'
)

select e.indicador, e.categoria, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.indicador = e.indicador and o.categoria is not distinct from e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.01
