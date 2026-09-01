-- Intermediate: seção 4 (abertura) — Educação: nível de instrução por
-- orientação sexual (PNS 2019). Formato LONGO. Só nível NACIONAL.
--
-- Fórmula (Cálculo_Indicadores_LGBTQIA+_Nacional, 4):
--   pct_nivel_instrucao_por_orientacao = nível X da orientação Y /
--     total da orientação Y (soma dos 7 níveis) × 100

with base as (
    select {{ orientacao_canonica('orient_sexual') }} as orientacao, *
    from {{ source('raw_lgbt', 'raw_lgbt_nivel_instrucao') }}
    where coalesce(trim(orient_sexual), '') <> '' and orient_sexual not ilike 'total%'
),

linhas as (
    select
        'pct_nivel_instrucao_por_orientacao'::text as indicador,
        b.orientacao || ' / ' || v.nivel           as categoria,
        {{ calcula_percentual(
            'v.qtd',
            '(b.sem_instr + b.fund_incompl_ou_equivalente + b.fund_compl_ou_equivalente'
            ' + b.medio_incompl_ou_equivalente + b.medio_compl_ou_equivalente'
            ' + b.superior_incompl_ou_equivalente + b.superior_compl)::numeric') }} as valor
    from base b
    cross join lateral (values
        ('Sem instrução',                         b.sem_instr::numeric),
        ('Fundamental incompleto ou equivalente', b.fund_incompl_ou_equivalente::numeric),
        ('Fundamental completo ou equivalente',   b.fund_compl_ou_equivalente::numeric),
        ('Médio incompleto ou equivalente',       b.medio_incompl_ou_equivalente::numeric),
        ('Médio completo ou equivalente',         b.medio_compl_ou_equivalente::numeric),
        ('Superior incompleto ou equivalente',    b.superior_incompl_ou_equivalente::numeric),
        ('Superior completo',                     b.superior_compl::numeric)
    ) as v(nivel, qtd)
)

select
    'nacional'::text                     as nivel,
    null::int                            as recorte_codigo,
    'Brasil'::text                       as recorte_nome,
    '4'::text                            as secao,
    'Educação — Nível de instrução'::text as secao_nome,
    indicador, categoria, valor,
    'percentual'::text                   as valor_tipo,
    2019                                 as ano_referencia
from linhas
