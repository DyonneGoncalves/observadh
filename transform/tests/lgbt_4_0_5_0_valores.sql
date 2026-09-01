-- Valida as aberturas das seções 4 e 5 (nível nacional) contra o texto-base
-- do relatório e os % pré-calculados das abas de origem. Tolerância 0,05 p.p.

with esperado (indicador, categoria, valor) as (
    values
        -- 5.0 autoavaliação da saúde "muito boa e boa" (texto do relatório)
        ('pct_autoavaliacao_saude_por_orientacao', 'Homossexual / Muito boa e boa',   76.8),
        ('pct_autoavaliacao_saude_por_orientacao', 'Bissexual / Muito boa e boa',     67.3),
        ('pct_autoavaliacao_saude_por_orientacao', 'Heterossexual / Muito boa e boa', 66.1),
        -- 5.0 diagnóstico de depressão (texto do relatório)
        ('pct_depressao_por_orientacao', 'Bissexual / Já teve diagnóstico de depressão',     20.1),
        ('pct_depressao_por_orientacao', 'Homossexual / Já teve diagnóstico de depressão',   13.2),
        ('pct_depressao_por_orientacao', 'Heterossexual / Já teve diagnóstico de depressão', 10.1),
        -- 4.0 nível de instrução (% pré-calculado da aba, Heterossexual)
        ('pct_nivel_instrucao_por_orientacao', 'Heterossexual / Médio completo ou equivalente', 29.7),
        ('pct_nivel_instrucao_por_orientacao', 'Heterossexual / Superior completo',             15.9),
        ('pct_nivel_instrucao_por_orientacao', 'Heterossexual / Sem instrução',                  6.1)
),

obtido as (
    select indicador, categoria, valor
    from {{ ref('lgbt_indicadores') }}
    where nivel = 'nacional' and secao in ('4', '5')
)

select e.indicador, e.categoria, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.indicador = e.indicador and o.categoria is not distinct from e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.05
