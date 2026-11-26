{{ config(materialized='table') }}

-- Intermediate: base municipal do PSR — uma linha por município com TODAS as
-- contagens do ano de referência (var psr_ano_referencia), já somadas por
-- município e em formato largo. É a única fonte dos níveis estadual e
-- nacional (int_psr_recortes soma estas linhas): os três níveis usam
-- exatamente os mesmos números.
--
-- Universo: os municípios da série histórica do CadÚnico (5.570) + a linha
-- "Ignorado" (municipio_codigo_ibge = 0), que só existe na planilha do ONDH
-- (denúncias sem município identificado). Ela entra apenas no total nacional
-- de denúncias.
--
-- Contagens ausentes viram 0. A população geral por cor do Censo tem duas
-- versões: qtd_pop_cor_<cor> (0 onde o IBGE suprimiu o dado com '-', usada
-- nas somas estadual/nacional) e qtd_pop_cor_<cor>_ou_nulo (NULL nesses
-- casos, usada no municipal: o percentual daquela cor fica "sem dado").
-- Na linha Ignorado tudo que não é ONDH fica NULL.

{% set ano = var('psr_ano_referencia') %}
{% set ano_ini = var('psr_ano_inicio_serie') %}
{% set ano_suas = var('psr_ano_censo_suas') %}

with universo as (
    select distinct municipio_codigo_ibge
    from {{ ref('stg_psr_serie_historica') }}
    union
    select 0
),

serie as (
    select municipio_codigo_ibge,
           sum(case when ano_referencia = {{ ano }} then qtd_psr end)     as qtd_psr_ano,
           sum(case when ano_referencia = {{ ano_ini }} then qtd_psr end) as qtd_psr_inicio
    from {{ ref('stg_psr_serie_historica') }}
    group by 1
),

distrib as (
    select municipio_codigo_ibge, sum(qtd_psr) as qtd_psr_distrib, sum(qtd_pop_total) as qtd_pop_total_ibge
    from {{ ref('stg_psr_distribuicao_territorial') }} group by 1
),

genero as (
    select municipio_codigo_ibge, sum(qtd_masculino) as qtd_masculino, sum(qtd_feminino) as qtd_feminino,
           sum(qtd_total_com_info) as qtd_genero_total
    from {{ ref('stg_psr_perfil_genero') }} group by 1
),

faixa as (
    select municipio_codigo_ibge,
           {%- for f in var('psr_faixas_etarias') %}
           sum(qtd_{{ f }}) as qtd_faixa_{{ f }},
           {%- endfor %}
           sum(qtd_total_com_info) as qtd_faixa_total
    from {{ ref('stg_psr_perfil_faixa_etaria') }} group by 1
),

raca as (
    select municipio_codigo_ibge,
           {%- for c in var('psr_racas') %}
           sum(qtd_psr_{{ c }}) as qtd_psr_cor_{{ c }},
           {%- endfor %}
           sum(qtd_psr_total_com_info) as qtd_psr_cor_total,
           {%- for c in var('psr_racas') %}
           sum(qtd_pop_{{ c }}) as qtd_pop_cor_{{ c }},
           {%- endfor %}
           sum(qtd_pop_total_com_info) as qtd_pop_cor_total
    from {{ ref('stg_psr_perfil_raca_cor') }} group by 1
),

deficiencia as (
    select e.municipio_codigo_ibge,
           sum(e.qtd_com_deficiencia) as qtd_com_deficiencia,
           sum(e.qtd_total_com_info)  as qtd_deficiencia_total
    from {{ ref('stg_psr_perfil_existencia_deficiencia') }} e group by 1
),

tipo_deficiencia as (
    select municipio_codigo_ibge,
           {%- for t in var('psr_tipos_deficiencia') %}
           sum(qtd_{{ t }}) as qtd_def_{{ t }}{{ ',' if not loop.last }}
           {%- endfor %}
    from {{ ref('stg_psr_perfil_tipo_deficiencia') }} group by 1
),

ondh as (
    select municipio_codigo_ibge, sum(qtd_denuncias) as qtd_denuncias
    from {{ ref('stg_psr_ondh_denuncias') }}
    where ano_referencia = {{ ano }} group by 1
),

sinan as (
    select municipio_codigo_ibge,
           sum(qtd_notificacoes) as qtd_notificacoes,
           sum(qtd_interpessoal) as qtd_interpessoal
    from {{ ref('stg_psr_sinan_notificacoes') }}
    where ano_referencia = {{ ano }} group by 1
),

vitimas_genero as (
    select municipio_codigo_ibge, sum(qtd_feminino) as qtd_vit_feminino, sum(qtd_masculino) as qtd_vit_masculino,
           sum(qtd_total_com_info) as qtd_vit_genero_total
    from {{ ref('stg_psr_sinan_interpessoal_genero') }} group by 1
),

vitimas_raca as (
    select municipio_codigo_ibge,
           {%- for c in var('psr_racas') %}
           sum(qtd_{{ c }}) as qtd_vit_cor_{{ c }},
           {%- endfor %}
           sum(qtd_total_com_info) as qtd_vit_cor_total
    from {{ ref('stg_psr_sinan_interpessoal_raca_cor') }} group by 1
),

tipo_violencia as (
    select municipio_codigo_ibge,
           {%- for t in var('psr_tipos_violencia') %}
           sum(qtd_{{ t }}) as qtd_viol_{{ t }},
           {%- endfor %}
           sum(qtd_total_com_resposta) as qtd_viol_tipo_total
    from {{ ref('stg_psr_sinan_interpessoal_tipo') }} group by 1
),

ocupadas as (
    select municipio_codigo_ibge, sum(qtd_ocupadas) as qtd_ocupadas, sum(qtd_nao_ocupadas) as qtd_nao_ocupadas
    from {{ ref('stg_psr_pessoas_ocupadas') }} group by 1
),

funcoes as (
    -- formal / informal conforme Cálculo Indicadores PSR_v2 (seção 4); empregador não entra em nenhum dos dois
    select municipio_codigo_ibge,
           sum(coalesce(qtd_empregado_com_carteira, 0) + coalesce(qtd_domestico_com_carteira, 0)
             + coalesce(qtd_militar_servidor, 0) + coalesce(qtd_estagiario, 0) + coalesce(qtd_aprendiz, 0)) as qtd_ocupacao_formal,
           sum(coalesce(qtd_conta_propria, 0) + coalesce(qtd_temporario_rural, 0) + coalesce(qtd_empregado_sem_carteira, 0)
             + coalesce(qtd_domestico_sem_carteira, 0) + coalesce(qtd_nao_remunerado, 0)) as qtd_ocupacao_informal
    from {{ ref('stg_psr_funcoes_ocupadas') }} group by 1
),

formas as (
    select municipio_codigo_ibge,
           {%- for f in var('psr_formas_renda') %}
           sum(qtd_{{ f }}) as qtd_forma_{{ f }},
           {%- endfor %}
           sum(qtd_total_com_info) as qtd_formas_total
    from {{ ref('stg_psr_formas_ganhar_dinheiro') }} group by 1
),

pobreza as (
    select municipio_codigo_ibge, sum(qtd_abaixo_linha_pobreza) as qtd_abaixo_linha_pobreza,
           sum(qtd_extrema_pobreza) as qtd_extrema_pobreza, sum(qtd_total_com_info) as qtd_renda_total
    from {{ ref('stg_psr_rendimento_pobreza') }} group by 1
),

ecr as (
    select municipio_codigo_ibge, sum(coalesce(qtd_ecr, 0)) as qtd_ecr
    from {{ ref('stg_psr_ecr') }} where ano_referencia = {{ ano }} group by 1
),

atend_ecr as (
    select municipio_codigo_ibge, sum(qtd_atendimentos) as qtd_atendimentos_ecr
    from {{ ref('stg_psr_atendimentos_ecr') }} where ano_referencia = {{ ano }} group by 1
),

centros_pop as (
    select municipio_codigo_ibge, sum(qtd_centros_pop) as qtd_centros_pop
    from {{ ref('stg_psr_centros_pop') }} where ano_referencia = {{ ano_suas }} group by 1
),

atendimento as (
    select municipio_codigo_ibge, sum(qtd_cras) as qtd_cras, sum(qtd_creas) as qtd_creas,
           sum(qtd_inst_governamental) as qtd_inst_governamental, sum(qtd_inst_nao_governamental) as qtd_inst_nao_governamental
    from {{ ref('stg_psr_atendimento_cadunico') }} group by 1
),

bpc as (
    select municipio_codigo_ibge, sum(qtd_beneficiarias) as qtd_bpc_beneficiarias,
           sum(qtd_elegiveis_sem_beneficio) as qtd_bpc_elegiveis_sem_beneficio, sum(qtd_psr) as qtd_bpc_psr
    from {{ ref('stg_psr_bpc') }} group by 1
),

bolsa as (
    select municipio_codigo_ibge, sum(qtd_beneficiarias) as qtd_pbf_beneficiarias,
           sum(qtd_elegiveis_sem_beneficio) as qtd_pbf_elegiveis_sem_beneficio, sum(qtd_psr) as qtd_pbf_psr
    from {{ ref('stg_psr_bolsa_familia') }} group by 1
),

educ as (
    select municipio_codigo_ibge, sum(qtd_nao_sabem_ler) as qtd_nao_sabem_ler, sum(qtd_psr) as qtd_educ_psr
    from {{ ref('stg_psr_nao_sabem_ler') }} group by 1
),

analfab as (
    select municipio_codigo_ibge, sum(qtd_psr_15_mais_analfabeta) as qtd_psr_15_mais_analfabeta,
           sum(qtd_psr_15_mais) as qtd_psr_15_mais, sum(qtd_pop_15_mais_analfabeta) as qtd_pop_15_mais_analfabeta,
           sum(qtd_pop_15_mais) as qtd_pop_15_mais
    from {{ ref('stg_psr_analfabetismo') }} group by 1
),

freq as (
    select municipio_codigo_ibge,
           {%- for f in ['0_5', '6_11', '12_17', '18_24'] %}
           sum(qtd_freq_{{ f }}) as qtd_freq_{{ f }}, sum(qtd_psr_{{ f }}) as qtd_psr_{{ f }}{{ ',' if not loop.last }}
           {%- endfor %}
    from {{ ref('stg_psr_frequencia_escolar') }} group by 1
),

{#- colunas de contagem (coalesce 0 nos municípios; NULL na linha Ignorado) #}
{% set contagens = [
    'serie.qtd_psr_ano', 'serie.qtd_psr_inicio', 'distrib.qtd_psr_distrib', 'distrib.qtd_pop_total_ibge',
    'genero.qtd_masculino', 'genero.qtd_feminino', 'genero.qtd_genero_total',
    'deficiencia.qtd_com_deficiencia', 'deficiencia.qtd_deficiencia_total',
    'sinan.qtd_notificacoes', 'sinan.qtd_interpessoal',
    'vitimas_genero.qtd_vit_feminino', 'vitimas_genero.qtd_vit_masculino', 'vitimas_genero.qtd_vit_genero_total',
    'vitimas_raca.qtd_vit_cor_total', 'tipo_violencia.qtd_viol_tipo_total',
    'ocupadas.qtd_ocupadas', 'ocupadas.qtd_nao_ocupadas',
    'funcoes.qtd_ocupacao_formal', 'funcoes.qtd_ocupacao_informal', 'formas.qtd_formas_total',
    'pobreza.qtd_abaixo_linha_pobreza', 'pobreza.qtd_extrema_pobreza', 'pobreza.qtd_renda_total',
    'ecr.qtd_ecr', 'atend_ecr.qtd_atendimentos_ecr', 'centros_pop.qtd_centros_pop',
    'atendimento.qtd_cras', 'atendimento.qtd_creas', 'atendimento.qtd_inst_governamental', 'atendimento.qtd_inst_nao_governamental',
    'bpc.qtd_bpc_beneficiarias', 'bpc.qtd_bpc_elegiveis_sem_beneficio', 'bpc.qtd_bpc_psr',
    'bolsa.qtd_pbf_beneficiarias', 'bolsa.qtd_pbf_elegiveis_sem_beneficio', 'bolsa.qtd_pbf_psr',
    'educ.qtd_nao_sabem_ler', 'educ.qtd_educ_psr',
    'analfab.qtd_psr_15_mais_analfabeta', 'analfab.qtd_psr_15_mais', 'analfab.qtd_pop_15_mais_analfabeta', 'analfab.qtd_pop_15_mais',
    'faixa.qtd_faixa_total', 'raca.qtd_psr_cor_total', 'raca.qtd_pop_cor_total'
] %}
{% for f in var('psr_faixas_etarias') %}{% do contagens.append('faixa.qtd_faixa_' ~ f) %}{% endfor %}
{% for c in var('psr_racas') %}{% do contagens.append('raca.qtd_psr_cor_' ~ c) %}{% do contagens.append('raca.qtd_pop_cor_' ~ c) %}{% do contagens.append('vitimas_raca.qtd_vit_cor_' ~ c) %}{% endfor %}
{% for t in var('psr_tipos_deficiencia') %}{% do contagens.append('tipo_deficiencia.qtd_def_' ~ t) %}{% endfor %}
{% for t in var('psr_tipos_violencia') %}{% do contagens.append('tipo_violencia.qtd_viol_' ~ t) %}{% endfor %}
{% for f in var('psr_formas_renda') %}{% do contagens.append('formas.qtd_forma_' ~ f) %}{% endfor %}
{% for f in ['0_5', '6_11', '12_17', '18_24'] %}{% do contagens.append('freq.qtd_freq_' ~ f) %}{% do contagens.append('freq.qtd_psr_' ~ f) %}{% endfor %}

final as (
    select
        u.municipio_codigo_ibge,
        (u.municipio_codigo_ibge = 0) as is_ignorado,
        {%- for c in contagens %}
        case when u.municipio_codigo_ibge = 0 then null else coalesce({{ c }}, 0) end::numeric as {{ c.split('.')[1] }},
        {%- endfor %}
        {#- população geral por cor: NULL onde o IBGE suprimiu ('-') #}
        {%- for c in var('psr_racas') %}
        raca.qtd_pop_cor_{{ c }}::numeric as qtd_pop_cor_{{ c }}_ou_nulo,
        {%- endfor %}
        coalesce(ondh.qtd_denuncias, 0)::numeric as qtd_denuncias
    from universo u
    left join serie            on serie.municipio_codigo_ibge            = u.municipio_codigo_ibge
    left join distrib          on distrib.municipio_codigo_ibge          = u.municipio_codigo_ibge
    left join genero           on genero.municipio_codigo_ibge           = u.municipio_codigo_ibge
    left join faixa            on faixa.municipio_codigo_ibge            = u.municipio_codigo_ibge
    left join raca             on raca.municipio_codigo_ibge             = u.municipio_codigo_ibge
    left join deficiencia      on deficiencia.municipio_codigo_ibge      = u.municipio_codigo_ibge
    left join tipo_deficiencia on tipo_deficiencia.municipio_codigo_ibge = u.municipio_codigo_ibge
    left join ondh             on ondh.municipio_codigo_ibge             = u.municipio_codigo_ibge
    left join sinan            on sinan.municipio_codigo_ibge            = u.municipio_codigo_ibge
    left join vitimas_genero   on vitimas_genero.municipio_codigo_ibge   = u.municipio_codigo_ibge
    left join vitimas_raca     on vitimas_raca.municipio_codigo_ibge     = u.municipio_codigo_ibge
    left join tipo_violencia   on tipo_violencia.municipio_codigo_ibge   = u.municipio_codigo_ibge
    left join ocupadas         on ocupadas.municipio_codigo_ibge         = u.municipio_codigo_ibge
    left join funcoes          on funcoes.municipio_codigo_ibge          = u.municipio_codigo_ibge
    left join formas           on formas.municipio_codigo_ibge           = u.municipio_codigo_ibge
    left join pobreza          on pobreza.municipio_codigo_ibge          = u.municipio_codigo_ibge
    left join ecr              on ecr.municipio_codigo_ibge              = u.municipio_codigo_ibge
    left join atend_ecr        on atend_ecr.municipio_codigo_ibge        = u.municipio_codigo_ibge
    left join centros_pop      on centros_pop.municipio_codigo_ibge      = u.municipio_codigo_ibge
    left join atendimento      on atendimento.municipio_codigo_ibge      = u.municipio_codigo_ibge
    left join bpc              on bpc.municipio_codigo_ibge              = u.municipio_codigo_ibge
    left join bolsa            on bolsa.municipio_codigo_ibge            = u.municipio_codigo_ibge
    left join educ             on educ.municipio_codigo_ibge             = u.municipio_codigo_ibge
    left join analfab          on analfab.municipio_codigo_ibge          = u.municipio_codigo_ibge
    left join freq             on freq.municipio_codigo_ibge             = u.municipio_codigo_ibge
)

select * from final
