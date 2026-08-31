-- Valida a seção 7.0 (nível nacional, ano 2024) contra a planilha de cálculo
-- (Cálculo_LGBTQIA_Violência_Sinan: abas "Cálculo_Notificações_2015_2024",
-- "Cálculo_Interpessoal_Perfil", "Cálculo_Autoprovocada_Perfil",
-- "Cálculo_Identidade_Genero", "Cálculo_Orientação_Sexual").
-- Falha (retorna linhas) se algum valor divergir (tolerância 0,01).

with esperado (indicador, categoria, valor) as (
    values
        ('notificacoes_total_2024',                          null,          22906.0),
        ('pct_notificacoes_por_tipo_2024',                   'Interpessoal',        55.208242),
        ('pct_notificacoes_por_tipo_2024',                   'Autoprovocada',       42.285864),
        ('pct_notificacoes_por_tipo_2024',                   'Origem desconhecida',  2.505894),
        ('pct_municipios_com_notificacao_2024',             null,          47.558348),
        ('pct_viol_interpessoal_por_sexo',                  'Feminino',    66.036691),
        ('pct_viol_interpessoal_por_sexo',                  'Masculino',   33.710264),
        ('pct_viol_interpessoal_por_faixa_etaria',          'Até 29 anos', 57.456903),
        ('pct_viol_interpessoal_por_faixa_etaria',          'Crianças e adolescentes', 16.993516),
        ('pct_viol_interpessoal_por_raca_cor',              'Negra',       60.022595),
        ('pct_viol_autoprovocada_por_sexo',                'Feminino',    61.521784),
        ('pct_viol_autoprovocada_por_faixa_etaria',        'Até 29 anos', 70.834194),
        ('pct_viol_autoprovocada_por_raca_cor',            'Negra',       52.303293),
        ('pct_viol_interpessoal_por_orientacao_sexual',     'Homossexual', 52.269492),
        ('pct_viol_interpessoal_por_orientacao_sexual',     'Bissexual',   20.457062),
        ('pct_viol_autoprovocada_por_orientacao_sexual',   'Homossexual', 61.015899),
        ('pct_viol_interpessoal_por_identidade_genero',     'Travesti',           4.799937),
        ('pct_viol_interpessoal_por_identidade_genero',     'Transexual mulher', 25.620750),
        ('pct_viol_autoprovocada_por_identidade_genero',   'Travesti',           4.232913)
),

obtido as (
    select indicador, categoria, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where secao = '7.0' and nivel = 'nacional'
)

select e.indicador, e.categoria, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.indicador = e.indicador
   and o.categoria is not distinct from e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.01
