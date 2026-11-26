-- Intermediate: seção 4 — Renda das pessoas em situação de rua. Formato LONGO.
--
-- Indicadores (Cálculo Indicadores PSR_v2, seção 4; CadÚnico dez/<ano>):
--   pct_psr_por_ocupacao               'Ocupadas' / 'Não ocupadas' sobre (ocupadas + não)   N E M
--   pct_ocupadas_por_vinculo           'Com vínculo formal' / 'Sem vínculo formal', sobre   N E M
--                                      as ocupadas. Formal = empregado e doméstico com
--                                      carteira, militar/servidor, estagiário, aprendiz.
--                                      Sem vínculo = conta própria, temporário rural,
--                                      empregado e doméstico sem carteira, não remunerado.
--                                      (empregador não entra em nenhum dos dois)
--   pct_psr_por_forma_ganhar_dinheiro  8 formas, % sobre quem informou (uma pessoa pode    N E M
--                                      informar mais de uma)
--   forma_ganhar_dinheiro_principal    forma mais citada — categoria = rótulo, valor = %   N E M
--                                      Sem linha quando ninguém informou.
--   pct_psr_abaixo_linha_pobreza       renda familiar per capita < R$ 665                  N E M
--   pct_psr_extrema_pobreza            renda familiar per capita < R$ 209                  N E M

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

formas as (
    select r.nivel, r.recorte_codigo, f.ordem, f.slug, f.qtd, r.qtd_formas_total as total,
           row_number() over (partition by r.nivel, r.recorte_codigo order by f.qtd desc, f.ordem) as posicao
    from r cross join lateral (values
        {%- for f in var('psr_formas_renda') %}
        ({{ loop.index }}, '{{ f }}', r.qtd_forma_{{ f }}){{ ',' if not loop.last }}
        {%- endfor %}
    ) as f(ordem, slug, qtd)
),

linhas as (
    select nivel, recorte_codigo, '4' as secao, 'pct_psr_por_ocupacao' as indicador, 'Ocupadas' as categoria,
           {{ psr_pct('qtd_ocupadas', 'qtd_ocupadas + qtd_nao_ocupadas') }} as valor, 'percentual' as valor_tipo, {{ ano }} as ano_referencia
    from r
    union all
    select nivel, recorte_codigo, '4', 'pct_psr_por_ocupacao', 'Não ocupadas',
           {{ psr_pct('qtd_nao_ocupadas', 'qtd_ocupadas + qtd_nao_ocupadas') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '4', 'pct_ocupadas_por_vinculo', 'Com vínculo formal',
           {{ psr_pct('qtd_ocupacao_formal', 'qtd_ocupadas') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '4', 'pct_ocupadas_por_vinculo', 'Sem vínculo formal',
           {{ psr_pct('qtd_ocupacao_informal', 'qtd_ocupadas') }}, 'percentual', {{ ano }}
    from r
    union all
    select f.nivel, f.recorte_codigo, '4', 'pct_psr_por_forma_ganhar_dinheiro', o.rotulo,
           {{ psr_pct('f.qtd', 'f.total') }}, 'percentual', {{ ano }}
    from formas f join rotulos o using (slug)
    union all
    select f.nivel, f.recorte_codigo, '4', 'forma_ganhar_dinheiro_principal', o.rotulo,
           {{ psr_pct('f.qtd', 'f.total') }}, 'categoria_predominante', {{ ano }}
    from formas f join rotulos o using (slug)
    where f.posicao = 1 and f.qtd > 0
    union all
    select nivel, recorte_codigo, '4', 'pct_psr_abaixo_linha_pobreza', null,
           {{ psr_pct('qtd_abaixo_linha_pobreza', 'qtd_renda_total') }}, 'percentual', {{ ano }}
    from r
    union all
    select nivel, recorte_codigo, '4', 'pct_psr_extrema_pobreza', null,
           {{ psr_pct('qtd_extrema_pobreza', 'qtd_renda_total') }}, 'percentual', {{ ano }}
    from r
)

{{ psr_secao({'4': 'Renda das pessoas em situação de rua'}) }}
