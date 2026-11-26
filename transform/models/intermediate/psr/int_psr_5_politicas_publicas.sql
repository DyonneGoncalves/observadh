-- Intermediate: seção 5 — Acesso a políticas públicas. Formato LONGO.
--
-- Indicadores (Cálculo Indicadores PSR_v2, seção 4 do doc = 5 do relatório):
--   5.1  qtd_ecr                           Equipes de Consultório na Rua (CNES, dez/<ano>)   N E M
--        qtd_municipios_com_ecr            municípios com 1+ eCR                             N E
--        qtd_atendimentos_ecr              atendimentos individuais das eCR (Sisab)          N E M
--   5.2  qtd_centros_pop                   Centros Pop cadastrados (Censo SUAS <ano SUAS>)   N E M
--        qtd_municipios_com_centros_pop    municípios com 1+ Centro Pop                      N E
--        qtd_psr_atendidas_por_servico     CRAS / CREAS / Instituição governamental /       N E M
--                                          Instituição não governamental (CadÚnico)
--        qtd_psr_elegiveis_bpc             beneficiárias + elegíveis sem benefício           N E M
--        pct_elegiveis_bpc_recebem         beneficiárias / elegíveis                         N E M
--        qtd_psr_elegiveis_bolsa_familia   beneficiárias + atenderiam ao critério de renda   N E M
--        pct_elegiveis_bolsa_familia_recebem  beneficiárias / elegíveis                      N E M
--   5.3  pct_psr_nao_sabem_ler_escrever    não sabem ler e escrever / total de PSR           N E M
--        taxa_analfabetismo_psr            PSR 15+ que não sabem ler e escrever / PSR 15+    N E M
--        taxa_analfabetismo_populacao      idem, população geral (Censo <ano Censo>)        N E M
--        pct_frequencia_escolar_por_faixa  frequentam escola / PSR da faixa — 0 a 5, 6 a 11, N E M
--                                          12 a 17 e 18 a 24 anos

{% set ano = var('psr_ano_referencia') %}
{% set ano_suas = var('psr_ano_censo_suas') %}

with r as (
    select * from {{ ref('int_psr_recortes') }}
),

linhas as (
    -- 5.1 — Saúde
    select nivel, recorte_codigo, '5.1' as secao, 'qtd_ecr' as indicador, null as categoria,
           qtd_ecr as valor, 'numero_absoluto' as valor_tipo, {{ ano }} as ano_referencia
    from r
    union all
    select nivel, recorte_codigo, '5.1', 'qtd_municipios_com_ecr', null, qtd_municipios_com_ecr, 'numero_absoluto', {{ ano }}
    from r where nivel <> 'municipal'
    union all
    select nivel, recorte_codigo, '5.1', 'qtd_atendimentos_ecr', null, qtd_atendimentos_ecr, 'numero_absoluto', {{ ano }}
    from r

    union all
    -- 5.2 — Assistência social
    select nivel, recorte_codigo, '5.2', 'qtd_centros_pop', null, qtd_centros_pop, 'numero_absoluto', {{ ano_suas }}
    from r
    union all
    select nivel, recorte_codigo, '5.2', 'qtd_municipios_com_centros_pop', null, qtd_municipios_com_centros_pop, 'numero_absoluto', {{ ano_suas }}
    from r where nivel <> 'municipal'
    union all
    select r.nivel, r.recorte_codigo, '5.2', 'qtd_psr_atendidas_por_servico', s.servico, s.qtd, 'numero_absoluto', {{ ano }}
    from r cross join lateral (values
        ('CRAS', r.qtd_cras),
        ('CREAS', r.qtd_creas),
        ('Instituição governamental', r.qtd_inst_governamental),
        ('Instituição não governamental', r.qtd_inst_nao_governamental)
    ) as s(servico, qtd)
    union all
    select nivel, recorte_codigo, '5.2', 'qtd_psr_elegiveis_bpc', null,
           qtd_bpc_beneficiarias + qtd_bpc_elegiveis_sem_beneficio, 'numero_absoluto', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '5.2', 'pct_elegiveis_bpc_recebem', null,
           {{ psr_pct('qtd_bpc_beneficiarias', 'qtd_bpc_beneficiarias + qtd_bpc_elegiveis_sem_beneficio') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '5.2', 'qtd_psr_elegiveis_bolsa_familia', null,
           qtd_pbf_beneficiarias + qtd_pbf_elegiveis_sem_beneficio, 'numero_absoluto', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '5.2', 'pct_elegiveis_bolsa_familia_recebem', null,
           {{ psr_pct('qtd_pbf_beneficiarias', 'qtd_pbf_beneficiarias + qtd_pbf_elegiveis_sem_beneficio') }}, 'percentual', {{ ano }}
    from r

    union all
    -- 5.3 — Educação
    select nivel, recorte_codigo, '5.3', 'pct_psr_nao_sabem_ler_escrever', null,
           {{ psr_pct('qtd_nao_sabem_ler', 'qtd_educ_psr') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '5.3', 'taxa_analfabetismo_psr', null,
           {{ psr_pct('qtd_psr_15_mais_analfabeta', 'qtd_psr_15_mais') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '5.3', 'taxa_analfabetismo_populacao', null,
           {{ psr_pct('qtd_pop_15_mais_analfabeta', 'qtd_pop_15_mais') }}, 'percentual', {{ var('psr_ano_censo_ibge') }}
    from r
    union all
    select r.nivel, r.recorte_codigo, '5.3', 'pct_frequencia_escolar_por_faixa', f.faixa,
           {{ psr_pct('f.freq', 'f.total') }}, 'percentual', {{ ano }}
    from r cross join lateral (values
        ('0 a 5 anos', r.qtd_freq_0_5, r.qtd_psr_0_5),
        ('6 a 11 anos', r.qtd_freq_6_11, r.qtd_psr_6_11),
        ('12 a 17 anos', r.qtd_freq_12_17, r.qtd_psr_12_17),
        ('18 a 24 anos', r.qtd_freq_18_24, r.qtd_psr_18_24)
    ) as f(faixa, freq, total)
)

{{ psr_secao({
    '5.1': 'Saúde',
    '5.2': 'Assistência social',
    '5.3': 'Educação'
}) }}
