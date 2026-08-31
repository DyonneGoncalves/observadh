-- Valida a seção 2.5 contra a planilha de cálculo da equipe
-- (Cálculo_LGBTQIA_Perfil... aba "Cálculo_Casamento_Sexo_Ano").
-- Falha (retorna linhas) se algum valor divergir do esperado (tolerância 0,01).

with esperado (nivel, recorte_codigo, indicador, categoria, valor) as (
    values
        -- Maranhão (cod_uf 21): total 2013 = 16, total 2023 = 78
        ('estadual', 21, 'casamentos_mesmo_sexo_total_ano',        '2013', 16.0),
        ('estadual', 21, 'casamentos_mesmo_sexo_total_ano',        '2023', 78.0),
        ('estadual', 21, 'variacao_casamentos_mesmo_sexo_13_23',   null,   387.5),
        ('estadual', 21, 'pct_casamentos_mesmo_sexo_por_genero_23', 'Casamentos entre mulheres', 64.102564),
        ('estadual', 21, 'pct_casamentos_mesmo_sexo_por_genero_23', 'Casamentos entre homens',   35.897436),
        -- Brasil
        ('nacional', null, 'casamentos_mesmo_sexo_total_ano',       '2013', 3700.0),
        ('nacional', null, 'casamentos_mesmo_sexo_total_ano',       '2023', 11198.0),
        ('nacional', null, 'pct_casamentos_lesbohomoafetivos',      null,   1.204603),
        -- % lesbohomoafetivos por UF (AC 12, SP 35)
        ('estadual', 12, 'pct_casamentos_lesbohomoafetivos',        null,   0.440367),
        ('estadual', 35, 'pct_casamentos_lesbohomoafetivos',        null,   1.848139)
),

obtido as (
    select nivel, recorte_codigo, indicador, categoria, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where secao = '2.5'
)

select e.nivel, e.recorte_codigo, e.indicador, e.categoria,
       e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.nivel = e.nivel
   and o.recorte_codigo is not distinct from e.recorte_codigo
   and o.indicador = e.indicador
   and o.categoria is not distinct from e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.01
