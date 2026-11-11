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
--   pct_viol_{interpessoal,autoprovocada}_por_local           10 locais (denominador = soma dos 10)
--   local_predominante_viol_{autoprovocada,interpessoal}      local de maior % — expressão do texto
--                                                             em `categoria` (nome da planilha), valor = %
--   sexo_predominante_viol_{autoprovocada,interpessoal}       idem para sexo ("eram do sexo YYYY")
--   raca_cor_predominante_viol_{autoprovocada,interpessoal}   idem para raça/cor ("eram pessoas da
--                                                             raça/cor YYYY"; Negra = preta + parda)
--   agressor_principal_{1,2,3}_viol_interpessoal              1º/2º/3º maiores grupos de agressor
--                                                             ("X% eram YYYY" × 3), SEM "Pessoas
--                                                             desconhecidas ou outros"
--
-- Percentuais de perfil (e % por tipo) de um recorte SEM notificação = NULL
-- ("sem dado"), não 0 — 0/0 não é 0%. 0,0000 = houve notificação, nenhuma
-- naquela categoria.
--
-- "Heterossexual" não é coluna nas abas de orientação — é derivado
-- (total - bissexual - homossexual - não se aplica - ignorado), como na planilha.
--

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
    from {{ source('raw_lgbt', 'raw_lgbt_sinan_notificacoes') }}
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
           {{ calcula_percentual('tipo.q', 'a.t', sem_denominador='null') }}, 'percentual', 2024
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
               when 'estadual' then coalesce(round(100.0 * m.n / nullif(u.n_munis, 0), 6), 0)
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
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_interpessoal_sexo'),
        'pct_viol_interpessoal_por_sexo', 'total_com_info', sexo, sem_denominador='null') }}
),
brk_int_faixa as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_interpessoal_faixa_etaria'),
        'pct_viol_interpessoal_por_faixa_etaria', 'total_com_info', faixa_int, sem_denominador='null') }}
),
brk_int_raca as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_interpessoal_cor_raca'),
        'pct_viol_interpessoal_por_raca_cor', 'total_com_info', raca, sem_denominador='null') }}
),
brk_autop_sexo as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_autoprovocada_sexo'),
        'pct_viol_autoprovocada_por_sexo', 'total_com_info', sexo, sem_denominador='null') }}
),
brk_autop_faixa as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_autoprovocada_faixa_etaria'),
        'pct_viol_autoprovocada_por_faixa_etaria', 'total_com_indo',
        faixa_int + [['Mais de 100 anos', 's.mais_de_100']], sem_denominador='null') }}
),
brk_autop_raca as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_autoprovocada_cor_raca'),
        'pct_viol_autoprovocada_por_raca_cor', 'total_com_info', raca, sem_denominador='null') }}
),

-- origem da agressão x orientação sexual (Heterossexual é derivado do total)
brk_int_orient as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_violencias_orientacao_sexual'),
        'pct_viol_interpessoal_por_orientacao_sexual', 'total_de_viol_interpessoal', [
        ['Heterossexual', 's.total_de_viol_interpessoal - s.viol_interpes_bissexual - s.viol_interpes_homossexual - s.viol_interpes_nao_se_aplica - s.viol_interpes_ignorado'],
        ['Bissexual', 's.viol_interpes_bissexual'], ['Homossexual', 's.viol_interpes_homossexual'],
        ['Não se aplica', 's.viol_interpes_nao_se_aplica'], ['Ignorado', 's.viol_interpes_ignorado']
    ], sem_denominador='null') }}
),
brk_autop_orient as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_violencias_orientacao_sexual'),
        'pct_viol_autoprovocada_por_orientacao_sexual', 'total_viol_autoprovocada', [
        ['Heterossexual', 's.total_viol_autoprovocada - s.viol_autop_bissexual - s.viol_autop_homossexual - s.viol_autop_nao_se_aplica - s.viol_autop_ignorado'],
        ['Bissexual', 's.viol_autop_bissexual'], ['Homossexual', 's.viol_autop_homossexual'],
        ['Não se aplica', 's.viol_autop_nao_se_aplica'], ['Ignorado', 's.viol_autop_ignorado']
    ], sem_denominador='null') }}
),

-- origem da agressão x identidade de gênero
brk_int_ident as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_violencias_identidade_genero'),
        'pct_viol_interpessoal_por_identidade_genero', 'total_viol_interpessoal', [
        ['Travesti', 's.viol_interpes_travesti'], ['Transexual mulher', 's.viol_interpes_transexual_mulher'],
        ['Transexual homem', 's.viol_interpes_transexual_homem'],
        ['Ignorado', 's.viol_interpes_ignorado'], ['Não se aplica', 's.viol_interpes_nao_se_aplica']
    ], sem_denominador='null') }}
),
brk_autop_ident as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_violencias_identidade_genero'),
        'pct_viol_autoprovocada_por_identidade_genero', 'total_viol_autoprovocada', [
        ['Travesti', 's.viol_autop_travesti'], ['Transexual mulher', 's.viol_autop_transexual_mulher'],
        ['Transexual homem', 's.viol_autop_transexual_homem'],
        ['Ignorado', 's.viol_autop_ignorado'], ['Não se aplica', 's.viol_autop_nao_se_aplica']
    ], sem_denominador='null') }}
),

-- local de ocorrência — denominador = SOMA das 10 categorias (a coluna
-- total_com_info_de_local_de_ocorrencia não bate com a planilha de cálculo).
{% set local_pairs = [
    ['Residência', 's.residencia'], ['Bar ou similar', 's.bar_ou_similar'], ['Outro', 's.outro'],
    ['Via pública', 's.via_publica'], ['Ignorado', 's.ignorado'], ['Escola', 's.escola'],
    ['Habitação coletiva', 's.habitacao_coletiva'], ['Comércio/Serviços', 's.comercio_servicos'],
    ['Indústrias/Construção', 's.industrias_construcao'], ['Local de prática esportiva', 's.local_de_pratica_esportiva']
] %}
brk_int_local as (
    {{ ondh_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_interpessoal_local_ocorrencia'),
        'pct_viol_interpessoal_por_local', local_pairs, sem_denominador='null') }}
),
brk_autop_local as (
    {{ ondh_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_autoprovocada_local_ocorrencia'),
        'pct_viol_autoprovocada_por_local', local_pairs, sem_denominador='null') }}
),

-- local predominante (Cálculo_Indicadores, 7: "Maior percentual de local onde
-- aconteceu a violência"). Texto: "<local> foi o local em que ocorreram X%
-- ...". `categoria` = nome do local EXATAMENTE como na planilha (ex.:
-- "Residência") — sem de-para, que nenhum documento define; `valor` = o %.
-- Só há linha quando o recorte tem ao menos uma notificação (valor > 0).
-- Empate: vence a ordem de local_pairs (Residência primeiro).
-- "Ignorado" e "Outro" entram na disputa, como na fórmula da equipe.
local_predominante as (
    select distinct on (b.nivel, b.recorte_codigo, b.indicador)
        b.nivel, b.recorte_codigo,
        case b.indicador
            when 'pct_viol_autoprovocada_por_local' then 'local_predominante_viol_autoprovocada'
            when 'pct_viol_interpessoal_por_local'  then 'local_predominante_viol_interpessoal'
        end                                         as indicador,
        b.categoria,
        b.valor,
        'categoria_predominante'::text              as valor_tipo,
        b.ano_referencia
    from (
        select * from brk_autop_local
        union all
        select * from brk_int_local
    ) b
    join (values
        {%- for p in local_pairs %}
        ('{{ p[0] }}', {{ loop.index }}){{ "," if not loop.last }}
        {%- endfor %}
    ) as ordem(categoria, pos) on ordem.categoria = b.categoria
    where b.valor > 0
    order by b.nivel, b.recorte_codigo, b.indicador, b.valor desc, ordem.pos
),

-- sexo e raça/cor predominantes — mesma regra do local: maior %, rótulo da
-- planilha em `categoria`, empate resolvido pela ordem das listas `sexo` e
-- `raca`; sem linha quando o recorte não tem notificação. Raça: o Cálculo_
-- Indicadores pede "Maior Percentual ... por Raça/Cor" (negras = pretas +
-- pardas); sexo: os textos estadual/municipal têm "eram do sexo YYYY".
{% set perfil_predominante = [
    ['brk_autop_sexo', 'sexo_predominante_viol_autoprovocada',     sexo],
    ['brk_int_sexo',   'sexo_predominante_viol_interpessoal',      sexo],
    ['brk_autop_raca', 'raca_cor_predominante_viol_autoprovocada', raca],
    ['brk_int_raca',   'raca_cor_predominante_viol_interpessoal',  raca]
] %}
perfil_predominante as (
    {% for cte, ind, pares in perfil_predominante %}
    select * from (
        select distinct on (b.nivel, b.recorte_codigo)
            b.nivel, b.recorte_codigo,
            '{{ ind }}'::text                 as indicador,
            b.categoria,
            b.valor,
            'categoria_predominante'::text    as valor_tipo,
            b.ano_referencia
        from {{ cte }} b
        join (values
            {%- for p in pares %}
            ('{{ p[0] }}', {{ loop.index }}){{ "," if not loop.last }}
            {%- endfor %}
        ) as ordem(categoria, pos) on ordem.categoria = b.categoria
        where b.valor > 0
        order by b.nivel, b.recorte_codigo, b.valor desc, ordem.pos
    ) x
    {{ "union all" if not loop.last }}
    {% endfor %}
),

-- perfil do agressor (categorias agregadas do relatório; denominador = total_viol)
brk_int_agressor as (
    {{ sinan_breakdown_percentual(source('raw_lgbt','raw_lgbt_sinan_interpessoal_perfil_agressor'),
        'pct_viol_interpessoal_por_agressor', 'total_viol', [
        ['Pai, mãe, padrasto, madrasta, irmão(ã) ou filho(a)', 's.pai + s.mae + s.padrasto + s.madrasta + s.irmao + s.filho'],
        ['Pessoas conhecidas ou amigas', 's.conhecido'],
        ['Cônjuges, namorados, ex-cônjuges ou ex-namorados', 's.conjuge + s.namorado + s.exconjuge + s.exnamorado'],
        ['Cuidadores(as) ou patrões(as)', 's.cuidador + s.patrao'],
        ['Polícias ou institucionais', 's.policial + s.institucional'],
        ['Pessoas desconhecidas ou outros', 's.desconhecido + s.outros']
    ], sem_denominador='null') }}
),

-- ranking dos 3 principais agressores (Cálculo_Indicadores, 7: "maiores
-- Percentuais de Tipo X de principal agressor"). Regra confirmada com a área
-- (validação CGTI, nov/2026): "Pessoas desconhecidas ou outros" fica FORA do
-- ranking — é o texto original do template (alteração de 18/08/2026 que o
-- trocou não foi aceita). Nacional 2024: cônjuges 32,9 · conhecidas 20,3 ·
-- familiares 16,9. Um indicador por posição; `categoria` = rótulo do grupo,
-- `valor` = %. Só entram grupos com valor > 0 (posição sem grupo = sem linha).
-- Empate: ordem da lista do perfil do agressor.
agressor_ranking as (
    select nivel, recorte_codigo,
           'agressor_principal_' || posicao || '_viol_interpessoal' as indicador,
           categoria, valor,
           'categoria_predominante'::text as valor_tipo,
           ano_referencia
    from (
        select b.*,
               row_number() over (partition by b.nivel, b.recorte_codigo
                                  order by b.valor desc, ordem.pos) as posicao
        from brk_int_agressor b
        join (values
            ('Cônjuges, namorados, ex-cônjuges ou ex-namorados', 1),
            ('Pessoas conhecidas ou amigas', 2),
            ('Pai, mãe, padrasto, madrasta, irmão(ã) ou filho(a)', 3),
            ('Polícias ou institucionais', 4),
            ('Cuidadores(as) ou patrões(as)', 5)
        ) as ordem(categoria, pos) on ordem.categoria = b.categoria
        where b.valor > 0
    ) r
    where posicao <= 3
),

todos as (
    select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from notif_ind
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from local_predominante
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from perfil_predominante
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from agressor_ranking
    {% for c in ['brk_int_sexo','brk_int_faixa','brk_int_raca','brk_autop_sexo','brk_autop_faixa','brk_autop_raca',
                 'brk_int_orient','brk_autop_orient','brk_int_ident','brk_autop_ident',
                 'brk_int_local','brk_autop_local','brk_int_agressor'] %}
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
