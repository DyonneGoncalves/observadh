-- Intermediate: seção 2 — Perfil das pessoas em situação de rua. Formato LONGO.
--
-- Indicadores (Cálculo Indicadores PSR_v2, seção 2; CadÚnico dez/<ano>):
--   2.1  pct_psr_por_genero             Masculino / Feminino sobre o total com informação     N E M
--   2.2  qtd_psr_por_faixa_etaria       12 faixas (0 a 5 anos ... 100 anos ou mais)            N E M
--        pct_psr_por_faixa_etaria       idem, % sobre o total com informação de idade          N E M
--   2.3  pct_psr_por_raca_cor           5 cores, % sobre a PSR com informação de cor           N E M
--        pct_populacao_por_raca_cor     5 cores, % da população geral (Censo <ano Censo>)     N E M
--                                       (NULL no município onde o IBGE suprimiu a cor)
--   2.4  pct_psr_com_deficiencia        com deficiência / total com informação                 N E M
--        pct_psr_por_tipo_deficiencia   8 tipos, % sobre o total com informação                N E M
--        tipo_deficiencia_principal_{1,2,3}  tipo mais/2º/3º mais frequente — categoria =     N E M
--                                       rótulo, valor = %. Sem linha quando não há casos.
--                                       Empate → ordem das colunas da planilha.

{% set ano = var('psr_ano_referencia') %}
{% set rot = var('psr_rotulos') %}

with r as (
    select * from {{ ref('int_psr_recortes') }}
),

faixas as (
    select r.nivel, r.recorte_codigo, f.slug, f.qtd, r.qtd_faixa_total as total
    from r cross join lateral (values
        {%- for f in var('psr_faixas_etarias') %}
        ('{{ f }}', r.qtd_faixa_{{ f }}){{ ',' if not loop.last }}
        {%- endfor %}
    ) as f(slug, qtd)
),

cores as (
    select r.nivel, r.recorte_codigo, c.slug,
           c.qtd_psr, r.qtd_psr_cor_total as total_psr,
           case when r.nivel = 'municipal' then c.qtd_pop_ou_nulo else c.qtd_pop end as qtd_pop,
           r.qtd_pop_cor_total as total_pop
    from r cross join lateral (values
        {%- for c in var('psr_racas') %}
        ('{{ c }}', r.qtd_psr_cor_{{ c }}, r.qtd_pop_cor_{{ c }}, r.qtd_pop_cor_{{ c }}_ou_nulo){{ ',' if not loop.last }}
        {%- endfor %}
    ) as c(slug, qtd_psr, qtd_pop, qtd_pop_ou_nulo)
),

tipos as (
    select r.nivel, r.recorte_codigo, t.ordem, t.slug, t.qtd, r.qtd_deficiencia_total as total,
           row_number() over (partition by r.nivel, r.recorte_codigo order by t.qtd desc, t.ordem) as posicao
    from r cross join lateral (values
        {%- for t in var('psr_tipos_deficiencia') %}
        ({{ loop.index }}, '{{ t }}', r.qtd_def_{{ t }}){{ ',' if not loop.last }}
        {%- endfor %}
    ) as t(ordem, slug, qtd)
),

rotulos as (
    select * from (values
        {%- for k, v in rot.items() %}
        ('{{ k }}', '{{ v }}'){{ ',' if not loop.last }}
        {%- endfor %}
    ) as x(slug, rotulo)
),

linhas as (
    -- 2.1 — gênero
    select nivel, recorte_codigo, '2.1' as secao, 'pct_psr_por_genero' as indicador, 'Masculino' as categoria,
           {{ psr_pct('qtd_masculino', 'qtd_genero_total') }} as valor, 'percentual' as valor_tipo, {{ ano }} as ano_referencia
    from r
    union all
    select nivel, recorte_codigo, '2.1', 'pct_psr_por_genero', 'Feminino',
           {{ psr_pct('qtd_feminino', 'qtd_genero_total') }}, 'percentual', {{ ano }}
    from r

    union all
    -- 2.2 — faixa etária (nº e %)
    select f.nivel, f.recorte_codigo, '2.2', 'qtd_psr_por_faixa_etaria', o.rotulo, f.qtd, 'numero_absoluto', {{ ano }}
    from faixas f join rotulos o using (slug)
    union all
    select f.nivel, f.recorte_codigo, '2.2', 'pct_psr_por_faixa_etaria', o.rotulo,
           {{ psr_pct('f.qtd', 'f.total') }}, 'percentual', {{ ano }}
    from faixas f join rotulos o using (slug)

    union all
    -- 2.3 — cor/raça: PSR x população geral
    select c.nivel, c.recorte_codigo, '2.3', 'pct_psr_por_raca_cor', o.rotulo,
           {{ psr_pct('c.qtd_psr', 'c.total_psr') }}, 'percentual', {{ ano }}
    from cores c join rotulos o using (slug)
    union all
    select c.nivel, c.recorte_codigo, '2.3', 'pct_populacao_por_raca_cor', o.rotulo,
           case when c.qtd_pop is not null then {{ psr_pct('c.qtd_pop', 'c.total_pop') }} end,
           'percentual', {{ var('psr_ano_censo_ibge') }}
    from cores c join rotulos o using (slug)

    union all
    -- 2.4 — deficiência
    select nivel, recorte_codigo, '2.4', 'pct_psr_com_deficiencia', null,
           {{ psr_pct('qtd_com_deficiencia', 'qtd_deficiencia_total') }}, 'percentual', {{ ano }}
    from r
    union all
    select t.nivel, t.recorte_codigo, '2.4', 'pct_psr_por_tipo_deficiencia', o.rotulo,
           {{ psr_pct('t.qtd', 't.total') }}, 'percentual', {{ ano }}
    from tipos t join rotulos o using (slug)
    union all
    select t.nivel, t.recorte_codigo, '2.4', 'tipo_deficiencia_principal_' || t.posicao, o.rotulo,
           {{ psr_pct('t.qtd', 't.total') }}, 'categoria_predominante', {{ ano }}
    from tipos t join rotulos o using (slug)
    where t.posicao <= 3 and t.qtd > 0
)

{{ psr_secao({
    '2.1': 'Gênero',
    '2.2': 'Faixa etária',
    '2.3': 'Raça e cor',
    '2.4': 'Deficiência'
}) }}
