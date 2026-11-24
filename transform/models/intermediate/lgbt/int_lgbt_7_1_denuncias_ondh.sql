-- Intermediate: seção 7.1 — Denúncias de violações de direitos humanos (ONDH
-- 2020-2024). Saída no FORMATO LONGO. Níveis NACIONAL / ESTADUAL / MUNICIPAL.
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+, 7.1 + "Cálculo ONDH *"):
--   denuncias_por_ano / violacoes_por_ano        série 2020..2024 (nº absoluto)
--   denuncias_total_2020_2024                    soma das denúncias no período
--   pct_participacao_denuncias_2024              denúncias do recorte / Brasil 2024 *100
--   pct_denuncias_por_sexo                       Fem/Intersexo/Masc (exclui não informado)
--   pct_denuncias_por_faixa_etaria               Até 29 / 30-39 / 40-49 / 50-59 / Idosos 60+
--   pct_denuncias_por_raca_cor                   Negra (parda+preta) / Branca / Amarela / Indígena
--   pct_denuncias_por_identidade_genero          8 categorias (inclui não informado)
--   pct_denuncias_por_orientacao_sexual          6 categorias (inclui não informado)
--   pct_denuncias_por_tipo_violacao              1 categoria por tipo
--   {faixa_etaria,raca_cor,local,tipo_violacao}_predominante_denuncias
--       categoria de MAIOR % — rótulo da planilha em `categoria`, valor = %
--       (texto: "X% tinham <até 29 anos>", "são pessoas <negras>", "no local
--       <casa da vítima>", "são de <tortura psíquica>"). N E M.
--   uf_maior_denuncias_{1,2,3}                   1º/2º/3º estados com mais
--       denúncias em 2024 — nome da UF em `categoria`, valor = % do Brasil. N.
--
-- NÃO modelados ainda (mesma mecânica, listas de colunas longas — ver catálogo):
--   local de ocorrência (ONDH_Local, 32 colunas) e relação do suspeito
--   (ONDH_Relação_Suspeito, 50 colunas).

with dim_uf as (
    select codigo_uf, nome_uf from {{ ref('dim_uf') }}
),
dim_mun as (
    select codigo_municipio, nome_municipio from {{ ref('dim_municipio') }}
),

-- ------------------------------------------------------------ SÉRIE HISTÓRICA
serie_long as (
    select s.cod_uf::int as uf_codigo, s.cod_ibge7::int as municipio_codigo_ibge,
           m.ano, m.metrica, coalesce(m.qtd, 0)::numeric as qtd
    from {{ source('raw_lgbt', 'raw_lgbt_ondh_serie_historica') }} s
    cross join lateral (values
        (2020, 'denuncias', s.qtd_denuncias_2020), (2020, 'violacoes', s.qtd_violacoes_2020),
        (2021, 'denuncias', s.qtd_denuncias_2021), (2021, 'violacoes', s.qtd_violacoes_2021),
        (2022, 'denuncias', s.qtd_denuncias_2022), (2022, 'violacoes', s.qtd_violacoes_2022),
        (2023, 'denuncias', s.qtd_denuncias_2023), (2023, 'violacoes', s.qtd_violacoes_2023),
        (2024, 'denuncias', s.qtd_denuncias_2024), (2024, 'violacoes', s.qtd_violacoes_2024)
    ) as m(ano, metrica, qtd)
),

serie_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, ano, metrica, sum(qtd) as q
    from serie_long group by ano, metrica
    union all
    select 'estadual', uf_codigo, ano, metrica, sum(qtd) from serie_long group by uf_codigo, ano, metrica
    union all
    select 'municipal', municipio_codigo_ibge, ano, metrica, sum(qtd) from serie_long group by municipio_codigo_ibge, ano, metrica
),

serie_ind as (
    select nivel, recorte_codigo,
           case metrica when 'denuncias' then 'denuncias_por_ano' else 'violacoes_por_ano' end as indicador,
           ano::text as categoria, q as valor, 'numero_absoluto'::text as valor_tipo, ano as ano_referencia
    from serie_agg

    union all
    select nivel, recorte_codigo, 'denuncias_total_2020_2024', null, sum(q), 'numero_absoluto', 2024
    from serie_agg where metrica = 'denuncias' group by nivel, recorte_codigo

    union all
    select nivel, recorte_codigo, 'pct_participacao_denuncias_2024', null,
           coalesce(round(100.0 * q / nullif(
               (select sum(q) from serie_agg where metrica = 'denuncias' and ano = 2024 and nivel = 'nacional'), 0), 4), 0),
           'percentual', 2024
    from serie_agg
    where metrica = 'denuncias' and ano = 2024 and nivel <> 'nacional'
),

-- ------------------------------------------------------------- QUEBRAS (%)
brk_sexo as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbt', 'raw_lgbt_ondh_sexo'),
        'pct_denuncias_por_sexo',
        [['Feminino', 's.fem'], ['Intersexo', 's.intersexo'], ['Masculino', 's.masc']]
    ) }}
),

brk_faixa as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbt', 'raw_lgbt_ondh_faixa_etaria'),
        'pct_denuncias_por_faixa_etaria',
        [
            ['Até 29 anos', 's."00_a_04_anos" + s."05_a_11_anos" + s."12_a_17_anos" + s."18_a_29_anos"'],
            ['30 a 39 anos', 's."30_a_39_anos"'],
            ['40 a 49 anos', 's."40_a_49_anos"'],
            ['50 a 59 anos', 's."50_a_59_anos"'],
            ['Idosos (60 anos ou mais)', 's."60_a_69_anos" + s."70_a_79_anos" + s."80_anos_ou_mais"']
        ]
    ) }}
),

brk_raca as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbt', 'raw_lgbt_ondh_raca_cor'),
        'pct_denuncias_por_raca_cor',
        [['Negra', 's.parda + s.preta'], ['Branca', 's.branca'],
         ['Amarela', 's.amarela'], ['Indígena', 's.indigena']]
    ) }}
),

brk_identidade as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbt', 'raw_lgbt_ondh_identidade_genero'),
        'pct_denuncias_por_identidade_genero',
        [['Homem cis', 's.homem_cis'], ['Homem trans', 's.homem_trans'],
         ['Mulher cis', 's.mulher_cis'], ['Mulher trans', 's.mulher_trans'],
         ['Travesti', 's.travesti'], ['Outro', 's.outro'],
         ['Não informado', 's.nao_informado'], ['Não se aplica', 's.nao_se_aplica']]
    ) }}
),

brk_orientacao as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbt', 'raw_lgbt_ondh_orientacao_sexual'),
        'pct_denuncias_por_orientacao_sexual',
        [['Bissexual', 's.bissexual'], ['Heterossexual', 's.heterossexual'],
         ['Homossexual', 's.homossexual'], ['Outro', 's.outro'],
         ['Não informado', 's.nao_informado'], ['Não se aplica', 's.nao_se_aplica']]
    ) }}
),

brk_local as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbt', 'raw_lgbt_ondh_local'),
        'pct_denuncias_por_local',
        [['Ambiente de lazer/esporte/entretenimento', 's.ambiente_de_lazer_esporte_entretenimento'],
         ['Ambiente virtual (internet)', 's.ambiente_virtual_no_ambito_da_internet'],
         ['Berçário/Creche', 's.bercario_creche'], ['Casa da vítima', 's.casa_da_vitima'],
         ['Casa de familiares', 's.casa_de_familiares'], ['Casa de terceiro', 's.casa_de_terceiro'],
         ['Casa do suspeito', 's.casa_do_suspeito'],
         ['Casa onde reside a vítima e o suspeito', 's.casa_onde_reside_a_vitima_e_o_suspeito'],
         ['Centro de referência', 's.centro_de_referencia'], ['Delegacia de polícia', 's.delegacia_de_policia'],
         ['Estabelecimento comercial', 's.estabelecimento_comercial'], ['Estabelecimento de saúde', 's.estabelecimento_de_saude'],
         ['Evento público', 's.evento_publico'], ['Instituição de ensino', 's.instituicao_de_ensino'],
         ['Instituição de longa permanência de idoso (ILPI)', 's.instituicao_de_longa_permanencia_de_idoso_ilpi'],
         ['Instituição financeira', 's.instituicao_financeira'],
         ['Local de trabalho da vítima', 's.local_de_trab_da_vitima'],
         ['Local de trabalho do agressor', 's.local_de_trab_do_agressor'],
         ['Manicômio/Hospital psiquiátrico/Casa de saúde mental', 's.manicomio_hospital_psiquiatrico_casa_de_saude_mental'],
         ['Metrô/Trem', 's.metro_trem'], ['Não sabe informar', 's.nao_sabe_informar'], ['Outros', 's.outros'],
         ['Serviço de abrigamento', 's.servico_de_abrigamento'],
         ['Taxi/Transporte por aplicativo', 's.taxi_transporte_aplicativo'],
         ['Transporte aéreo', 's.transporte_aereo'], ['Transporte marítimo', 's.transporte_maritimo'],
         ['Unidade de medida socioeducativa', 's.unid_de_medida_socioeducativa'],
         ['Unidade prisional', 's.unid_prisional'], ['Via pública', 's.via_publica'],
         ['Órgãos públicos', 's.orgaos_publicos'], ['Ônibus', 's.onibus']]
    ) }}
),

brk_relacao as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbt', 'raw_lgbt_ondh_relacao_suspeito'),
        'pct_denuncias_por_relacao_suspeito',
        [['Aluno(a)', 's.aluno_a'], ['Amigo(a)', 's.amigo_a'], ['Amigo(a) de família', 's.amigo_a_de_familia'],
         ['Avô(ó)', 's.avo_o'], ['Colega de trabalho (mesmo nível)', 's.colega_de_trab_mesmo_nivel_hierarquico'],
         ['Companheiro(a)', 's.companheiro_a'], ['Companheiro(a) de mãe/do pai', 's.companheiro_a_de_mae_do_pai'],
         ['Cuidador(a)', 's.cuidador_a'], ['Cunhado(a)', 's.cunhado_a'], ['Desconhecido(a)', 's.desconhecido_a'],
         ['Diretor(a) de escola', 's.diretor_a_de_escola'], ['Diretor(a) de unidade prisional', 's.diretor_a_de_unid_prisional'],
         ['Diretor/gestor de instituição', 's.diretor_gestor_de_instituicao'],
         ['Empregado(a) doméstico', 's.empregado_a_domestico'],
         ['Empregado (hierarquicamente inferior)', 's.empregado_hierarquicamente_inferior'],
         ['Empregador/patrão (hierarquicamente superior)', 's.empregador_patrao_hierarquicamente_superior'],
         ['Enteado(a)', 's.enteado_a'], ['Esposa(o)', 's.esposa_o'], ['Ex-companheiro(a)', 's.ex_companheiro_a'],
         ['Ex-esposa(o)', 's.ex_esposa_o'], ['Ex-namorado(a)', 's.ex_namorado_a'], ['Filho(a)', 's.filho_a'],
         ['Funcionário/voluntário/prestador de serviço para instituição', 's.funcionario_voluntario_ou_prestador_de_servico_para_ins'],
         ['Genro/nora', 's.genro_nora'], ['Irmão(ã)', 's.irmao_a'], ['Líder religioso(a)', 's.lider_religioso_a'],
         ['Morou/mora na mesma residência (não familiar)', 's.morou_mora_na_mesma_residencia_nao_familiar'],
         ['Namorado(a)', 's.namorado_a'], ['Neto(a)', 's.neto_a'], ['Não informado', 's.nao_informado'],
         ['Não se aplica', 's.nao_se_aplica'], ['Outros', 's.outros'], ['Outros familiares', 's.outros_familiares'],
         ['Outros profissionais de educação', 's.outros_profissionais_de_educ'],
         ['Padrasto/madrasta', 's.padrasto_madrasta'], ['Padrinho/madrinha', 's.padrinho_madrinha'],
         ['Pai/mãe', 's.pai_mae'],
         ['Pessoa com quem mantém/manteve convivência familiar', 's.pessoa_com_quem_mantem_manteve_convivencia_familiar'],
         ['Prestador(a) de serviço', 's.prestador_a_de_servico'], ['Primo(a)', 's.primo_a'],
         ['Professor(a)', 's.professor_a'], ['Profissional de saúde', 's.profissional_de_saude'],
         ['Sobrinho(a)', 's.sobrinho_a'], ['Sogro(a)', 's.sogro_a'], ['Tio(a)', 's.tio_a'], ['Vizinho(a)', 's.vizinho_a']]
    ) }}
),

-- --------------------------------------------------------- TIPO DE VIOLAÇÃO
tv_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, tipo_de_violacao as categoria,
           sum(total_com_info) as q
    from {{ source('raw_lgbt', 'raw_lgbt_ondh_tipo_de_violacao') }}
    group by tipo_de_violacao
    union all
    select 'estadual', cod_uf::int, tipo_de_violacao, sum(total_com_info)
    from {{ source('raw_lgbt', 'raw_lgbt_ondh_tipo_de_violacao') }}
    group by cod_uf, tipo_de_violacao
    union all
    select 'municipal', cod_ibge7::int, tipo_de_violacao, sum(total_com_info)
    from {{ source('raw_lgbt', 'raw_lgbt_ondh_tipo_de_violacao') }}
    group by cod_ibge7, tipo_de_violacao
),

tv_ind as (
    select nivel, recorte_codigo, 'pct_denuncias_por_tipo_violacao'::text as indicador,
           categoria,
           coalesce(round(100.0 * q / nullif(sum(q) over (partition by nivel, recorte_codigo), 0), 4), 0) as valor,
           'percentual'::text as valor_tipo, 2024 as ano_referencia
    from tv_agg
),

-- --------------------------------------------------- PREDOMINANTES / RANKING
-- Mesma regra do SINAN (7.0): maior %, rótulo da planilha em `categoria`, só
-- recortes com casos (valor > 0). Empate: ordem alfabética da categoria.
-- Raça e local: o Cálculo_Indicadores pede "maior percentual"; faixa etária e
-- tipo de violação: o texto cita a categoria de maior %. "Não sabe informar"
-- e "Outros" (local) entram na disputa, como no SINAN.
{% set predominantes_ondh = [
    ['brk_faixa', 'faixa_etaria_predominante_denuncias'],
    ['brk_raca',  'raca_cor_predominante_denuncias'],
    ['brk_local', 'local_predominante_denuncias'],
    ['tv_ind',    'tipo_violacao_predominante_denuncias']
] %}
predominante as (
    {% for cte, ind in predominantes_ondh %}
    select * from (
        select distinct on (nivel, recorte_codigo)
            nivel, recorte_codigo, '{{ ind }}'::text as indicador, categoria, valor,
            'categoria_predominante'::text as valor_tipo, ano_referencia
        from {{ cte }}
        where valor > 0
        -- empate no maior valor: desempata pela categoria em ordem alfabética do
        -- português (ICU pt-BR), fixada aqui para o resultado não depender da
        -- collation padrão do banco (Mac x Docker x produção)
        order by nivel, recorte_codigo, valor desc, categoria collate "pt-BR-x-icu"
    ) x
    {{ "union all" if not loop.last }}
    {% endfor %}
),

-- ranking dos estados com mais denúncias em 2024 (Cálculo_Indicadores: "estado
-- X com maior número de denúncias" / total Brasil). Só nacional.
uf_ranking as (
    select 'nacional'::text as nivel, null::int as recorte_codigo,
           'uf_maior_denuncias_' || posicao as indicador,
           u.nome_uf as categoria, r.valor,
           'categoria_predominante'::text as valor_tipo, 2024 as ano_referencia
    from (
        select recorte_codigo, valor,
               row_number() over (order by valor desc, recorte_codigo) as posicao
        from serie_ind
        where indicador = 'pct_participacao_denuncias_2024' and nivel = 'estadual' and valor > 0
    ) r
    join dim_uf u on u.codigo_uf = r.recorte_codigo
    where posicao <= 3
),

-- ------------------------------------------------------------------ UNIÃO
todos as (
    select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from serie_ind
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_sexo
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_faixa
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_raca
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_identidade
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_orientacao
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_local
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_relacao
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from tv_ind
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from predominante
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from uf_ranking
)

select
    t.nivel,
    t.recorte_codigo,
    case t.nivel
        when 'nacional'  then 'Brasil'
        when 'estadual'  then u.nome_uf
        when 'municipal' then m.nome_municipio
    end                                                     as recorte_nome,
    '7.1'::text                                             as secao,
    'Violência — Denúncias de violações de DH (ONDH)'::text  as secao_nome,
    t.indicador,
    t.categoria,
    t.valor,
    t.valor_tipo,
    t.ano_referencia
from todos t
left join dim_uf  u on t.nivel = 'estadual'  and u.codigo_uf = t.recorte_codigo
left join dim_mun m on t.nivel = 'municipal' and m.codigo_municipio = t.recorte_codigo
-- descarta recortes sem correspondência nas dimensões (cod_uf/cod_ibge inválidos
-- na origem, ex.: "Não se aplica"). O total nacional acima já os contabiliza.
where t.nivel = 'nacional'
   or (t.nivel = 'estadual'  and u.codigo_uf is not null)
   or (t.nivel = 'municipal' and m.codigo_municipio is not null)
