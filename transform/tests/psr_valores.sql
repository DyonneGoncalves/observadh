-- Valida o PSR contra os relatórios validados pela área (docs/psr/referencia:
-- nacional, Acre e município de São Paulo — PDFs do relatório e doc de
-- cálculo). Percentuais: o relatório mostra 1 casa (2 no "% do total
-- nacional") — tolerância de 0,06 p.p. (0,006 nos de 2 casas). Quantidades:
-- exatas. Nos indicadores 'categoria_predominante' a categoria também precisa
-- bater. Falha (retorna linhas) se algum valor divergir ou faltar.

with esperado (nivel, recorte_codigo, indicador, categoria, valor, tolerancia) as (
    values
        -- Nacional
        ('nacional', null::int, 'qtd_psr',                              null,                        327925.0, 0.0),
        ('nacional', null, 'qtd_psr_por_ano',                           '2015',                       50301.0, 0.0),
        ('nacional', null, 'qtd_municipios_com_psr',                    '2015',                        1215.0, 0.0),
        ('nacional', null, 'qtd_municipios_com_psr',                    '2024',                        2683.0, 0.0),
        ('nacional', null, 'uf_maior_concentracao_psr_1',               'São Paulo',                     42.6, 0.06),
        ('nacional', null, 'uf_maior_concentracao_psr_2',               'Rio de Janeiro',                 9.4, 0.06),
        ('nacional', null, 'uf_maior_concentracao_psr_3',               'Minas Gerais',                   9.2, 0.06),
        ('nacional', null, 'uf_maior_proporcao_psr',                    'Roraima',                        1.0, 0.06),
        ('nacional', null, 'pct_psr_por_genero',                        'Masculino',                     84.2, 0.06),
        ('nacional', null, 'qtd_psr_por_faixa_etaria',                  '30 a 39 anos',               89078.0, 0.0),
        ('nacional', null, 'pct_psr_por_faixa_etaria',                  '40 a 49 anos',                  28.6, 0.06),
        ('nacional', null, 'pct_psr_por_raca_cor',                      'Preta',                         19.4, 0.06),
        ('nacional', null, 'pct_populacao_por_raca_cor',                'Branca',                        43.5, 0.06),
        ('nacional', null, 'pct_psr_com_deficiencia',                   null,                            13.8, 0.06),
        ('nacional', null, 'tipo_deficiencia_principal_1',              'Física',                         7.3, 0.06),
        ('nacional', null, 'tipo_deficiencia_principal_2',              'Transtorno mental',              2.9, 0.06),
        ('nacional', null, 'tipo_deficiencia_principal_3',              'Intelectual',                    2.0, 0.06),
        ('nacional', null, 'qtd_denuncias_ondh',                        null,                          3389.0, 0.0),
        ('nacional', null, 'qtd_notificacoes_sinan',                    null,                          6381.0, 0.0),
        ('nacional', null, 'pct_notificacoes_viol_interpessoal',        null,                            87.3, 0.06),
        ('nacional', null, 'pct_vitimas_por_genero',                    'Feminino',                      39.3, 0.06),
        ('nacional', null, 'pct_psr_negras',                            null,                            69.4, 0.06),
        ('nacional', null, 'pct_vitimas_negras',                        null,                            72.6, 0.06),
        ('nacional', null, 'pct_viol_interpessoal_por_tipo',            'Sexual',                         4.7, 0.06),
        ('nacional', null, 'pct_viol_interpessoal_por_tipo',            'Tortura',                        3.5, 0.06),
        ('nacional', null, 'pct_psr_por_ocupacao',                      'Ocupadas',                      22.8, 0.06),
        ('nacional', null, 'pct_ocupadas_por_vinculo',                  'Com vínculo formal',            41.6, 0.06),
        ('nacional', null, 'forma_ganhar_dinheiro_principal',           'Outra forma',                   35.6, 0.06),
        ('nacional', null, 'pct_psr_abaixo_linha_pobreza',              null,                            89.6, 0.06),
        ('nacional', null, 'pct_psr_extrema_pobreza',                   null,                            85.6, 0.06),
        ('nacional', null, 'qtd_ecr',                                   null,                           366.0, 0.0),
        ('nacional', null, 'qtd_municipios_com_ecr',                    null,                           210.0, 0.0),
        ('nacional', null, 'qtd_atendimentos_ecr',                      null,                       1480750.0, 0.0),
        ('nacional', null, 'qtd_centros_pop',                           null,                           258.0, 0.0),
        ('nacional', null, 'qtd_municipios_com_centros_pop',            null,                           228.0, 0.0),
        ('nacional', null, 'qtd_psr_atendidas_por_servico',             'CRAS',                       61550.0, 0.0),
        ('nacional', null, 'qtd_psr_elegiveis_bpc',                     null,                         55164.0, 0.0),
        ('nacional', null, 'pct_elegiveis_bpc_recebem',                 null,                            32.0, 0.06),
        ('nacional', null, 'qtd_psr_elegiveis_bolsa_familia',           null,                        290572.0, 0.0),
        ('nacional', null, 'pct_elegiveis_bolsa_familia_recebem',       null,                            84.7, 0.06),
        ('nacional', null, 'pct_psr_nao_sabem_ler_escrever',            null,                            10.9, 0.06),
        ('nacional', null, 'taxa_analfabetismo_psr',                    null,                             9.5, 0.06),
        ('nacional', null, 'taxa_analfabetismo_populacao',              null,                             5.8, 0.06),
        ('nacional', null, 'pct_frequencia_escolar_por_faixa',          '0 a 5 anos',                    18.3, 0.06),
        -- Acre (UF 12)
        ('estadual', 12, 'qtd_psr',                                     null,                           468.0, 0.0),
        ('estadual', 12, 'qtd_psr_por_ano',                             '2015',                          27.0, 0.0),
        ('estadual', 12, 'pct_psr_sobre_total_nacional',                null,                            0.14, 0.006),
        ('estadual', 12, 'pct_psr_por_genero',                          'Masculino',                     87.4, 0.06),
        ('estadual', 12, 'tipo_deficiencia_principal_1',                'Física',                         8.5, 0.06),
        ('estadual', 12, 'qtd_denuncias_ondh',                          null,                             5.0, 0.0),
        ('estadual', 12, 'tipo_violencia_principal',                    'Física',                       100.0, 0.06),
        ('estadual', 12, 'pct_vitimas_por_genero',                      'Feminino',                      57.1, 0.06),
        ('estadual', 12, 'forma_ganhar_dinheiro_principal',             'Serviços gerais',               44.1, 0.06),
        ('estadual', 12, 'qtd_atendimentos_ecr',                        null,                          2519.0, 0.0),
        ('estadual', 12, 'pct_elegiveis_bpc_recebem',                   null,                            21.8, 0.06),
        ('estadual', 12, 'taxa_analfabetismo_populacao',                null,                             9.9, 0.06),
        -- São Paulo (município 3550308)
        ('municipal', 3550308, 'qtd_psr',                               null,                         92556.0, 0.0),
        ('municipal', 3550308, 'pct_psr_sobre_total_nacional',          null,                           28.22, 0.006),
        ('municipal', 3550308, 'tipo_violencia_principal',              'Física',                        82.0, 0.06),
        ('municipal', 3550308, 'forma_ganhar_dinheiro_principal',       'Outra forma',                   49.4, 0.06),
        ('municipal', 3550308, 'qtd_psr_atendidas_por_servico',         'Instituição governamental',  48216.0, 0.0),
        ('municipal', 3550308, 'pct_frequencia_escolar_por_faixa',      '0 a 5 anos',                    33.0, 0.06)
),

obtido as (
    select nivel, recorte_codigo, indicador, categoria, valor
    from {{ ref('psr_indicadores') }}
)

select e.nivel, e.recorte_codigo, e.indicador, e.categoria, e.valor as esperado, o.valor as obtido
from esperado e
left join obtido o
  on  o.nivel = e.nivel
  and coalesce(o.recorte_codigo, -1) = coalesce(e.recorte_codigo, -1)
  and o.indicador = e.indicador
  and coalesce(o.categoria, '') = coalesce(e.categoria, '')
where o.valor is null or abs(o.valor - e.valor) > e.tolerancia
