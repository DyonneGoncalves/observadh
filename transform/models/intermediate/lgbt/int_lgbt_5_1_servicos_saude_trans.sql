-- Intermediate: seção 5.1 — Serviços de saúde para pessoas trans (CNES 2025).
--
-- Saída no FORMATO LONGO — contrato de indicadores do tema LGBTQIA+. Uma linha
-- por (nivel, recorte_codigo, secao, indicador, categoria):
--   nivel           'nacional' | 'estadual' | 'municipal'
--   recorte_codigo   null (nacional) | codigo_uf (estadual) | cod_ibge (municipal)
--   recorte_nome     'Brasil' | nome da UF | nome do município
--   secao/secao_nome número e nome da (sub)seção no relatório
--   indicador        slug estável
--   categoria        quebra dentro do indicador (null se não houver)
--   valor            numérico
--   valor_tipo       'numero_absoluto' | 'percentual' | 'variacao_pp'
--   ano_referencia
--
-- 5.1 existe só nos níveis NACIONAL e ESTADUAL (Saúde = "Sem dados municipais").
--
-- Fórmulas (Cálculo_Indicadores_LGBTQIA+_{Nacional,Estadual}_V2.docx, 5.1):
--   - contagem de estabelecimentos (total e por tipo de habilitação)
--   - contagem de UFs com habilitação hospitalar / só ambulatorial / sem serviço
-- Tipos de habilitação são mutuamente exclusivos: 'Ambulatorial',
-- 'Hospitalar', 'Ambulatorial/Hospitalar' (16 + 3 + 7 = 26, ver test).

with estab as (
    select * from {{ ref('stg_lgbt_estabelecimentos_saude_trans') }}
),

com_servico as (
    select * from estab where possui_servico
),

ufs as (
    select codigo_uf, nome_uf from {{ ref('dim_uf') }}
),

ano as (
    select max(ano_referencia) as ano_referencia from estab
),

-- 1 linha por UF que tem pelo menos um estabelecimento
uf_capacidade as (
    select
        uf_codigo,
        count(*)                                                                              as qtd_estab,
        count(*) filter (where tipo_habilitacao in ('Hospitalar', 'Ambulatorial/Hospitalar')) as qtd_hospitalar
    from com_servico
    group by 1
),

-- ------------------------------------------------------------------ NACIONAL
nacional as (

    select 'estabelecimentos_total'::text as indicador,
           null::text                     as categoria,
           (select count(*) from com_servico)::numeric as valor

    union all
    select 'estabelecimentos_por_habilitacao', tipo_habilitacao, count(*)::numeric
    from com_servico
    group by tipo_habilitacao

    union all
    select 'estados_com_habilitacao_hospitalar', null,
           (select count(*) from uf_capacidade where qtd_hospitalar > 0)::numeric

    union all
    select 'estados_apenas_ambulatorial', null,
           (select count(*) from uf_capacidade where qtd_hospitalar = 0)::numeric

    union all
    select 'estados_sem_servico', null,
           ((select count(*) from ufs) - (select count(*) from uf_capacidade))::numeric
),

-- ------------------------------------------------------------------ ESTADUAL
est_total as (
    select
        u.codigo_uf, u.nome_uf,
        'estabelecimentos_total'::text   as indicador,
        null::text                       as categoria,
        coalesce(c.qtd_estab, 0)::numeric as valor
    from ufs u
    left join uf_capacidade c on c.uf_codigo = u.codigo_uf
),

est_por_hab as (
    select
        u.codigo_uf, u.nome_uf,
        'estabelecimentos_por_habilitacao'::text as indicador,
        s.tipo_habilitacao                       as categoria,
        count(*)::numeric                        as valor
    from com_servico s
    join ufs u on u.codigo_uf = s.uf_codigo
    group by u.codigo_uf, u.nome_uf, s.tipo_habilitacao
),

estadual as (
    select codigo_uf, nome_uf, indicador, categoria, valor from est_total
    union all
    select codigo_uf, nome_uf, indicador, categoria, valor from est_por_hab
)

select
    'nacional'::text                                       as nivel,
    null::int                                              as recorte_codigo,
    'Brasil'::text                                         as recorte_nome,
    '5.1'::text                                            as secao,
    'Saúde — Serviços de saúde para pessoas trans'::text   as secao_nome,
    indicador,
    categoria,
    valor,
    'numero_absoluto'::text                                as valor_tipo,
    (select ano_referencia from ano)                       as ano_referencia
from nacional

union all

select
    'estadual',
    codigo_uf,
    nome_uf,
    '5.1',
    'Saúde — Serviços de saúde para pessoas trans',
    indicador,
    categoria,
    valor,
    'numero_absoluto',
    (select ano_referencia from ano)
from estadual
