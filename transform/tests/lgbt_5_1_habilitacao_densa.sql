-- Valida estabelecimentos_por_habilitacao (seção 5.1), chamado 27607 item 4.
-- Falha (retorna linhas) se:
--   (a) algum recorte (Brasil ou UF) não tiver as 3 categorias;
--   (b) a soma das 3 categorias diferir de estabelecimentos_total do recorte
--       (pega tipo de habilitação com grafia nova que ficaria de fora);
--   (c) Alagoas (27) não vier com as 3 categorias = 0, como no relatório.

with ind as (
    select nivel, recorte_codigo, indicador, categoria, valor
    from {{ ref('lgbt_indicadores') }}
    where secao = '5.1' and nivel in ('nacional', 'estadual')
),

por_hab as (
    select nivel, recorte_codigo, count(*) as n_categorias, sum(valor) as soma
    from ind where indicador = 'estabelecimentos_por_habilitacao'
    group by nivel, recorte_codigo
),

total as (
    select nivel, recorte_codigo, valor
    from ind where indicador = 'estabelecimentos_total'
)

select 'categorias' as problema, t.nivel, t.recorte_codigo, null::text as categoria,
       3::numeric as esperado, coalesce(h.n_categorias, 0)::numeric as obtido
from total t
left join por_hab h on h.nivel = t.nivel and h.recorte_codigo is not distinct from t.recorte_codigo
where coalesce(h.n_categorias, 0) <> 3

union all
select 'soma_difere_total', t.nivel, t.recorte_codigo, null, t.valor, h.soma
from total t
join por_hab h on h.nivel = t.nivel and h.recorte_codigo is not distinct from t.recorte_codigo
where h.soma <> t.valor

union all
select 'alagoas_nao_zero', nivel, recorte_codigo, categoria, 0, valor
from ind
where nivel = 'estadual' and recorte_codigo = 27
  and indicador = 'estabelecimentos_por_habilitacao' and valor <> 0
