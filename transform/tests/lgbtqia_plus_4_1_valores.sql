-- Valida a seção 4.1 contra a planilha de cálculo da equipe
-- (Cálculo_LGBTQIA_Educação_PNS_SAEB: abas "Cálculo Projetos homofobia 2019/2021"
-- e "Cálculo_homofobia_local 2021") e contra os % pré-calculados nas abas de origem.
-- Falha (retorna linhas) se algum valor divergir (tolerância 0,01 p.p.).

with esperado (nivel, recorte_codigo, indicador, categoria, valor) as (
    values
        -- nacional
        ('nacional', null, 'pct_escolas_com_projeto',                  '2019',   28.5169),
        ('nacional', null, 'pct_escolas_com_projeto',                  '2021',   22.1213),
        ('nacional', null, 'pct_escolas_com_projeto_localizacao_2021', 'Urbana', 24.4742),
        ('nacional', null, 'pct_escolas_com_projeto_localizacao_2021', 'Rural',  14.3574),
        ('nacional', null, 'pct_escolas_com_projeto_uf_maior',         'Rio Grande do Sul', 29.9386),
        ('nacional', null, 'pct_escolas_com_projeto_uf_menor',         'Roraima',            9.3851),
        -- estadual (% pré-calculado das abas de origem)
        ('estadual', 11, 'pct_escolas_com_projeto', '2019', 21.5569),
        ('estadual', 11, 'pct_escolas_com_projeto', '2021', 19.8887),
        ('estadual', 35, 'pct_escolas_com_projeto', '2019', 32.9133),
        ('estadual', 35, 'pct_escolas_com_projeto', '2021', 29.2817)
),

obtido as (
    select nivel, recorte_codigo, indicador, categoria, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where secao = '4.1'
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
