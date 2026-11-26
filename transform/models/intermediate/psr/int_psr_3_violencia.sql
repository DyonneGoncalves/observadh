-- Intermediate: seção 3 — Violência contra a população em situação de rua.
-- Formato LONGO. Fontes: ONDH (denúncias) e SINAN (notificações), ano <ano>.
--
-- Indicadores (Cálculo Indicadores PSR_v2, seção 3):
--   3    qtd_denuncias_ondh                 denúncias de violações de DH contra PSR          N E M
--                                           (o nacional inclui as denúncias sem município)
--        qtd_notificacoes_sinan             notificações de violência contra PSR              N E M
--        pct_notificacoes_viol_interpessoal violência interpessoal / total de notificações   N E M
--        tipo_violencia_principal           tipo de violência interpessoal mais notificado —  N E M
--                                           categoria = rótulo, valor = % (ver nota abaixo).
--                                           Sem linha quando não há notificação.
--   3.1  pct_vitimas_por_genero             Feminino / Masculino (vítimas de viol. interpessoal) N E M
--        pct_vitimas_por_raca_cor           5 cores                                          N E M
--        pct_vitimas_negras                 (preta + parda) / total com informação de cor    N E M
--        pct_psr_negras                     idem para a PSR (CadÚnico) — base da comparação  N E M
--                                           ("X% da PSR, Y% das vítimas"); o % de mulheres na
--                                           PSR é o pct_psr_por_genero da seção 2.1
--   3.2  pct_viol_interpessoal_por_tipo     10 tipos, % sobre as notificações com resposta   N E M
--                                           de tipo (fórmula do doc de cálculo)
--
-- Nota — % do tipo_violencia_principal: o denominador segue os relatórios
-- validados pela área, que usam bases diferentes por nível: estadual = total
-- de violência interpessoal; municipal e nacional = total de notificações
-- SINAN. Ver catálogo, seção 5.1 (pendente de confirmação da área).

{% set ano = var('psr_ano_referencia') %}
{% set rot = var('psr_rotulos') %}

with r as (
    select * from {{ ref('int_psr_recortes') }}
),

rotulos as (
    select * from (values
        {%- for k, v in rot.items() %}
        ('{{ k }}', '{{ v }}'){{ ',' if not loop.last }}
        {%- endfor %}
    ) as x(slug, rotulo)
),

tipos as (
    select r.nivel, r.recorte_codigo, t.ordem, t.slug, t.qtd,
           r.qtd_viol_tipo_total, r.qtd_interpessoal, r.qtd_notificacoes,
           row_number() over (partition by r.nivel, r.recorte_codigo order by t.qtd desc, t.ordem) as posicao
    from r cross join lateral (values
        {%- for t in var('psr_tipos_violencia') %}
        ({{ loop.index }}, '{{ t }}', r.qtd_viol_{{ t }}){{ ',' if not loop.last }}
        {%- endfor %}
    ) as t(ordem, slug, qtd)
),

cores_vitimas as (
    select r.nivel, r.recorte_codigo, c.slug, c.qtd, r.qtd_vit_cor_total as total
    from r cross join lateral (values
        {%- for c in var('psr_racas') %}
        ('{{ c }}', r.qtd_vit_cor_{{ c }}){{ ',' if not loop.last }}
        {%- endfor %}
    ) as c(slug, qtd)
),

linhas as (
    -- 3 — denúncias e notificações
    select nivel, recorte_codigo, '3' as secao, 'qtd_denuncias_ondh' as indicador, null as categoria,
           qtd_denuncias as valor, 'numero_absoluto' as valor_tipo, {{ ano }} as ano_referencia
    from r
    union all
    select nivel, recorte_codigo, '3', 'qtd_notificacoes_sinan', null, qtd_notificacoes, 'numero_absoluto', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '3', 'pct_notificacoes_viol_interpessoal', null,
           {{ psr_pct('qtd_interpessoal', 'qtd_notificacoes') }}, 'percentual', {{ ano }}
    from r
    union all
    select t.nivel, t.recorte_codigo, '3', 'tipo_violencia_principal', o.rotulo,
           case when t.nivel = 'estadual' then {{ psr_pct('t.qtd', 't.qtd_interpessoal') }}
                else {{ psr_pct('t.qtd', 't.qtd_notificacoes') }} end,
           'categoria_predominante', {{ ano }}
    from tipos t join rotulos o using (slug)
    where t.posicao = 1 and t.qtd > 0

    union all
    -- 3.1 — perfil das vítimas x perfil da PSR
    select nivel, recorte_codigo, '3.1', 'pct_vitimas_por_genero', 'Feminino',
           {{ psr_pct('qtd_vit_feminino', 'qtd_vit_genero_total') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '3.1', 'pct_vitimas_por_genero', 'Masculino',
           {{ psr_pct('qtd_vit_masculino', 'qtd_vit_genero_total') }}, 'percentual', {{ ano }}
    from r
    union all
    select c.nivel, c.recorte_codigo, '3.1', 'pct_vitimas_por_raca_cor', o.rotulo,
           {{ psr_pct('c.qtd', 'c.total') }}, 'percentual', {{ ano }}
    from cores_vitimas c join rotulos o using (slug)
    union all
    select nivel, recorte_codigo, '3.1', 'pct_vitimas_negras', null,
           {{ psr_pct('qtd_vit_cor_preta + qtd_vit_cor_parda', 'qtd_vit_cor_total') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '3.1', 'pct_psr_negras', null,
           {{ psr_pct('qtd_psr_cor_preta + qtd_psr_cor_parda', 'qtd_psr_cor_total') }}, 'percentual', {{ ano }}
    from r

    union all
    -- 3.2 — tipos de violência interpessoal
    select t.nivel, t.recorte_codigo, '3.2', 'pct_viol_interpessoal_por_tipo', o.rotulo,
           {{ psr_pct('t.qtd', 't.qtd_viol_tipo_total') }}, 'percentual', {{ ano }}
    from tipos t join rotulos o using (slug)
)

{{ psr_secao({
    '3': 'Violência contra a população em situação de rua',
    '3.1': 'Perfil das vítimas de violência interpessoal',
    '3.2': 'Principais dados sobre as violências interpessoais'
}) }}
