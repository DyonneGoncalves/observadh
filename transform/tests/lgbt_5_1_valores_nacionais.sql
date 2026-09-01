-- Valida a seção 5.1 (nível nacional) contra a planilha de cálculo da equipe:
-- Bases para cálculo 2/Cálculo_LGBTQIA_Saúde_PNS_Cnes_2019_2025.xlsx,
-- aba "Procedimento_Hospitalar_CNES" (tabela dinâmica no rodapé).
-- Falha (retorna linhas) se algum valor calculado divergir do esperado.

with esperado (indicador, categoria, valor) as (
    values
        ('estabelecimentos_total',               null,                      26),
        ('estabelecimentos_por_habilitacao',     'Ambulatorial',            16),
        ('estabelecimentos_por_habilitacao',     'Ambulatorial/Hospitalar',  7),
        ('estabelecimentos_por_habilitacao',     'Hospitalar',               3),
        ('estados_com_habilitacao_hospitalar',   null,                       8),
        ('estados_apenas_ambulatorial',          null,                       7),
        ('estados_sem_servico',                  null,                      12)
),

obtido as (
    select indicador, categoria, valor
    from {{ ref('lgbt_indicadores') }}
    where nivel = 'nacional' and secao = '5.1'
)

select e.indicador, e.categoria, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.indicador = e.indicador
   and o.categoria is not distinct from e.categoria
where o.valor is null or o.valor <> e.valor
