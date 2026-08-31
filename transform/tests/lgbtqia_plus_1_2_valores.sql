-- Valida as seções 1 e 2 (nível nacional) contra a planilha de cálculo
-- (Cálculo_LGBTQIA_Quantas são: "Cálculo_orientaçãosexual_2019"; e os
-- exemplos do Cálculo_Indicadores_LGBTQIA+_Nacional) e o texto-base do relatório.
-- Falha (retorna linhas) se algum valor divergir (tolerância 0,01).

with esperado (secao, indicador, categoria, valor) as (
    values
        -- seção 1
        ('1', 'pct_populacao_lgbtqia_18_mais',       null, 1.891217),
        ('1', 'conjuges_mesmo_sexo_2010',            null, 60035.0),
        ('1', 'conjuges_mesmo_sexo_2022',            null, 391080.0),
        ('1', 'pessoas_uniao_mesmo_sexo_estimativa', null, 782160.0),
        -- seção 2.0 — % da população por orientação
        ('2', 'pct_populacao_por_orientacao', 'Heterossexual', 94.754400),
        ('2', 'pct_populacao_por_orientacao', 'Bissexual',      0.681500),
        ('2', 'pct_populacao_por_orientacao', 'Homossexual',    1.153200),
        -- seção 2.1 — % da orientação por sexo (texto: homossexual 43,1% mulheres / 56,9% homens)
        ('2', 'pct_orientacao_por_sexo', 'Homossexual / Mulheres', 43.064),
        ('2', 'pct_orientacao_por_sexo', 'Homossexual / Homens',   56.936),
        -- seção 2.2 — % da orientação por faixa etária (exemplo do doc: heterossexual 50-59 = 17,33)
        ('2', 'pct_orientacao_por_faixa_etaria', 'Heterossexual / 50 a 59 anos', 17.32883),
        -- seção 2.3 — % da orientação por cor/raça (exemplo do doc: bissexual parda = 43,24)
        ('2', 'pct_orientacao_por_raca_cor', 'Bissexual / Parda', 43.24071),
        -- seção 2.4 — % da orientação por localidade (texto: homossexual 94,2% urbana)
        ('2', 'pct_orientacao_por_localidade', 'Homossexual / Urbana', 94.2196)
),

obtido as (
    select secao, indicador, categoria, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where nivel = 'nacional' and secao in ('1', '2')
)

select e.secao, e.indicador, e.categoria, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.secao = e.secao and o.indicador = e.indicador
   and o.categoria is not distinct from e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.01
