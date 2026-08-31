-- Intermediate: seção 7.0 — Violência contra pessoas LGBTQIA+ (notificações
-- SINAN 2015-2024; dados de perfil referentes a 2024). Formato LONGO. N/E/M.
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+ 7.0 + "Cálculo_*"):
--   notificacoes_por_ano                       série 2015..2024 (nº absoluto)
--   notificacoes_total_2024
--   pct_notificacoes_por_tipo_2024             Interpessoal / Autoprovocada / Origem desconhecida
--   pct_municipios_com_notificacao_2024        munis c/ notif 2024 / total de munis (N: /5570; E: /munis da UF)
--   pct_viol_{interpessoal,autoprovocada}_por_sexo            Fem / Masc / Indefinido
--   pct_viol_{interpessoal,autoprovocada}_por_faixa_etaria    até 29, crianças/adol, 18-29, 30-39...
--   pct_viol_{interpessoal,autoprovocada}_por_raca_cor        Negra (preta+parda) / Branca / Amarela / Indígena
--   pct_viol_{interpessoal,autoprovocada}_por_orientacao_sexual   Het / Bi / Homo / Ignorado / Não se aplica
--   pct_viol_{interpessoal,autoprovocada}_por_identidade_genero   Travesti / Trans mulher / Trans homem / ...
--
-- "Heterossexual" não é coluna nas abas de orientação — é derivado
-- (total - bissexual - homossexual - não se aplica - ignorado), como na planilha.
--
-- NÃO modelado ainda: local de ocorrência (Interpessoal/Autoprovocada_Local_
-- Ocorrencia) e perfil do agressor (Interpessoal_Perfil_Agressor).

with dim_uf as (
    select codigo_uf, nome_uf from {{ ref('dim_uf') }}
),
dim_mun as (
    select codigo_municipio, nome_municipio, codigo_uf from {{ ref('dim_municipio') }}
),
munis_por_uf as (
    select codigo_uf, count(*)::numeric as n_munis from dim_mun group by codigo_uf
),

notif as (
    select
        {{ codigo_num('cod_uf') }}      as uf_codigo,
        {{ codigo_num('cod_ibge7') }}   as municipio_codigo_ibge,
        ano_de_referencia::int          as ano,
        coalesce(viol_interpessoal, 0)::numeric              as v_interpessoal,
        coalesce(viol_autoprovocada, 0)::numeric             as v_autoprovocada,
        coalesce(nao_aplica, 0)::numeric
          + coalesce(ignorado, 0)::numeric
          + coalesce(missing, 0)::numeric                    as v_origem_desconhecida,
        coalesce(total_com_info_de_notificacao, 0)::numeric  as total_notif
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_sinan_notificacoes') }}
),

notif_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, ano,
           sum(total_notif) t, sum(v_interpessoal) vi, sum(v_autoprovocada) va, sum(v_origem_desconhecida) vd
    from notif group by ano
    union all
    select 'estadual', uf_codigo, ano, sum(total_notif), sum(v_interpessoal), sum(v_autoprovocada), sum(v_origem_desconhecida)
    from notif group by uf_codigo, ano
    union all
    select 'municipal', municipio_codigo_ibge, ano, sum(total_notif), sum(v_interpessoal), sum(v_autoprovocada), sum(v_origem_desconhecida)
    from notif group by municipio_codigo_ibge, ano
),

-- municípios com >=1 notificação em 2024, por recorte
munis_com_notif_2024 as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, count(*)::numeric as n
    from (select municipio_codigo_ibge from notif where ano = 2024 and total_notif > 0 group by 1) x
    union all
    select 'estadual', uf_codigo, count(*)::numeric
    from (select uf_codigo, municipio_codigo_ibge from notif where ano = 2024 and total_notif > 0 group by 1, 2) x
    group by uf_codigo
),

notif_ind as (
    -- série anual
    select nivel, recorte_codigo, 'notificacoes_por_ano'::text as indicador, ano::text as categoria,
           t as valor, 'numero_absoluto'::text as valor_tipo, ano as ano_referencia
    from notif_agg

    union all
    -- total 2024
    select nivel, recorte_codigo, 'notificacoes_total_2024', null, t, 'numero_absoluto', 2024
    from notif_agg where ano = 2024

    union all
    -- % por tipo em 2024
    select a.nivel, a.recorte_codigo, 'pct_notificacoes_por_tipo_2024', tipo.categoria,
           {{ calcula_percentual('tipo.q', 'a.t') }}, 'percentual', 2024
    from notif_agg a
    cross join lateral (values
        ('Interpessoal', a.vi), ('Autoprovocada', a.va), ('Origem desconhecida', a.vd)
    ) as tipo(categoria, q)
    where a.ano = 2024

    union all
    -- % de municípios com notificação em 2024
    select m.nivel, m.recorte_codigo, 'pct_municipios_com_notificacao_2024', null,
           case m.nivel
               when 'nacional' then round(100.0 * m.n / 5570, 6)
               when 'estadual' then round(100.0 * m.n / nullif(u.n_munis, 0), 6)
           end,
           'percentual', 2024
    from munis_com_notif_2024 m
    left join munis_por_uf u on m.nivel = 'estadual' and u.codigo_uf = m.recorte_codigo
),

-- --------------------------------------------------------- QUEBRAS DE PERFIL
{% set faixa_int = [
    ['Até 29 anos', 's."7_a_11" + s."12_a_17" + s."18_a_29"'],
    ['Crianças e adolescentes', 's."7_a_11" + s."12_a_17"'],
    ['18 a 29 anos', 's."18_a_29"'],
    ['30 a 39 anos', 's."30_a_39"'], ['40 a 49 anos', 's."40_a_49"'],
    ['50 a 59 anos', 's."50_a_59"'], ['60 a 69 anos', 's."60_a_69"'],
    ['70 a 79 anos', 's."70_a_79"'], ['80 a 89 anos', 's."80_a_89"'],
    ['90 a 99 anos', 's."90_a_99"']
] %}
{% set raca = [
    ['Negra', 's.preta + s.parda'], ['Branca', 's.branca'],
    ['Amarela', 's.amarela'], ['Indígena', 's.indigena']
] %}
{% set sexo = [
    ['Feminino', 's.sexo_fem'], ['Masculino', 's.sexo_masc'], ['Indefinido', 's.sexo_indefinido']
] %}

brk_int_sexo as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_interpessoal_sexo'),
        'pct_viol_interpessoal_por_sexo', 'total_com_info', sexo) }}
),
brk_int_faixa as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_interpessoal_faixa_etaria'),
        'pct_viol_interpessoal_por_faixa_etaria', 'total_com_info', faixa_int) }}
),
brk_int_raca as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_interpessoal_cor_raca'),
        'pct_viol_interpessoal_por_raca_cor', 'total_com_info', raca) }}
),
brk_autop_sexo as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_autoprovocada_sexo'),
        'pct_viol_autoprovocada_por_sexo', 'total_com_info', sexo) }}
),
brk_autop_faixa as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_autoprovocada_faixa_etaria'),
        'pct_viol_autoprovocada_por_faixa_etaria', 'total_com_indo',
        faixa_int + [['Mais de 100 anos', 's.mais_de_100']]) }}
),
brk_autop_raca as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_autoprovocada_cor_raca'),
        'pct_viol_autoprovocada_por_raca_cor', 'total_com_info', raca) }}
),

-- origem da agressão x orientação sexual (Heterossexual é derivado do total)
brk_int_orient as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_violencias_orientacao_sexual'),
        'pct_viol_interpessoal_por_orientacao_sexual', 'total_de_viol_interpessoal', [
        ['Heterossexual', 's.total_de_viol_interpessoal - s.viol_interpes_bissexual - s.viol_interpes_homossexual - s.viol_interpes_nao_se_aplica - s.viol_interpes_ignorado'],
        ['Bissexual', 's.viol_interpes_bissexual'], ['Homossexual', 's.viol_interpes_homossexual'],
        ['Não se aplica', 's.viol_interpes_nao_se_aplica'], ['Ignorado', 's.viol_interpes_ignorado']
    ]) }}
),
brk_autop_orient as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_violencias_orientacao_sexual'),
        'pct_viol_autoprovocada_por_orientacao_sexual', 'total_viol_autoprovocada', [
        ['Heterossexual', 's.total_viol_autoprovocada - s.viol_autop_bissexual - s.viol_autop_homossexual - s.viol_autop_nao_se_aplica - s.viol_autop_ignorado'],
        ['Bissexual', 's.viol_autop_bissexual'], ['Homossexual', 's.viol_autop_homossexual'],
        ['Não se aplica', 's.viol_autop_nao_se_aplica'], ['Ignorado', 's.viol_autop_ignorado']
    ]) }}
),

-- origem da agressão x identidade de gênero
brk_int_ident as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_violencias_identidade_genero'),
        'pct_viol_interpessoal_por_identidade_genero', 'total_viol_interpessoal', [
        ['Travesti', 's.viol_interpes_travesti'], ['Transexual mulher', 's.viol_interpes_transexual_mulher'],
        ['Transexual homem', 's.viol_interpes_transexual_homem'],
        ['Ignorado', 's.viol_interpes_ignorado'], ['Não se aplica', 's.viol_interpes_nao_se_aplica']
    ]) }}
),
brk_autop_ident as (
    {{ sinan_breakdown_percentual(source('raw_lgbtqia_plus','raw_lgbtqia_plus_sinan_violencias_identidade_genero'),
        'pct_viol_autoprovocada_por_identidade_genero', 'total_viol_autoprovocada', [
        ['Travesti', 's.viol_autop_travesti'], ['Transexual mulher', 's.viol_autop_transexual_mulher'],
        ['Transexual homem', 's.viol_autop_transexual_homem'],
        ['Ignorado', 's.viol_autop_ignorado'], ['Não se aplica', 's.viol_autop_nao_se_aplica']
    ]) }}
),

todos as (
    select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from notif_ind
    {% for c in ['brk_int_sexo','brk_int_faixa','brk_int_raca','brk_autop_sexo','brk_autop_faixa','brk_autop_raca',
                 'brk_int_orient','brk_autop_orient','brk_int_ident','brk_autop_ident'] %}
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from {{ c }}
    {% endfor %}
)

select
    t.nivel,
    t.recorte_codigo,
    case t.nivel
        when 'nacional'  then 'Brasil'
        when 'estadual'  then u.nome_uf
        when 'municipal' then m.nome_municipio
    end                                                      as recorte_nome,
    '7.0'::text                                              as secao,
    'Violência — Notificações de violência (SINAN)'::text     as secao_nome,
    t.indicador, t.categoria, t.valor, t.valor_tipo, t.ano_referencia
from todos t
left join dim_uf  u on t.nivel = 'estadual'  and u.codigo_uf = t.recorte_codigo
left join dim_mun m on t.nivel = 'municipal' and m.codigo_municipio = t.recorte_codigo
where t.nivel = 'nacional'
   or (t.nivel = 'estadual'  and u.codigo_uf is not null)
   or (t.nivel = 'municipal' and m.codigo_municipio is not null)
