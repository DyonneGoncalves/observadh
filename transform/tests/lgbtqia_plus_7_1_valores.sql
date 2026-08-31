-- Valida a seção 7.1 (nível nacional) contra a planilha de cálculo da equipe
-- (Cálculo_LGBTQIA_Violência_ONDH: abas "Cálculo ONDH Serie Historica",
-- "Cálculo ONDH Perfil Vítimas", "Cálculo Identidade de Gênero",
-- "Cálculo Orientação Sexual", "Cálculo Tipo de Violação").
-- Falha (retorna linhas) se algum valor divergir (tolerância 0,01).

with esperado (indicador, categoria, valor) as (
    values
        ('denuncias_por_ano',                  '2020',  1797.0),
        ('denuncias_por_ano',                  '2024',  8176.0),
        ('violacoes_por_ano',                  '2024', 48599.0),
        ('denuncias_total_2020_2024',           null,  21672.0),
        ('pct_denuncias_por_sexo',             'Feminino',  44.692104),
        ('pct_denuncias_por_sexo',             'Masculino', 54.363430),
        ('pct_denuncias_por_faixa_etaria',     'Até 29 anos',              48.033050),
        ('pct_denuncias_por_faixa_etaria',     'Idosos (60 anos ou mais)',  4.044888),
        ('pct_denuncias_por_raca_cor',         'Negra',   54.980919),
        ('pct_denuncias_por_raca_cor',         'Branca',  43.374128),
        ('pct_denuncias_por_identidade_genero','Homem trans',   6.854001),
        ('pct_denuncias_por_identidade_genero','Mulher trans', 10.946854),
        ('pct_denuncias_por_orientacao_sexual','Homossexual',  54.970689),
        ('pct_denuncias_por_orientacao_sexual','Bissexual',    14.509038),
        ('pct_denuncias_por_tipo_violacao',    'Tortura Psíquica', 12.476490),
        ('pct_denuncias_por_tipo_violacao',    'Constrangimento',  10.988779)
),

obtido as (
    select indicador, categoria, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where secao = '7.1' and nivel = 'nacional'
)

select e.indicador, e.categoria, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.indicador = e.indicador
   and o.categoria is not distinct from e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.01
