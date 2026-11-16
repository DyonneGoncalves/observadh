-- Valida a seção 2.0 ESTADUAL (pct_populacao_por_orientacao), chamado 27607 item 1.
-- Falha (retorna linhas) se:
--   (a) alguma UF não tiver exatamente as 6 categorias de orientação;
--   (b) a soma das 6 categorias de uma UF fugir de 100% (tolerância 0,5 p.p.);
--   (c) Alagoas divergir dos valores informados pela área (CGTI, 29/09/2026),
--       publicados com 1 casa decimal (tolerância 0,05 p.p.).

with obtido as (
    select recorte_codigo, recorte_nome, categoria, valor
    from {{ ref('lgbt_indicadores') }}
    where nivel = 'estadual' and secao = '2' and indicador = 'pct_populacao_por_orientacao'
),

por_uf as (
    select recorte_codigo, count(*) as n_categorias, sum(valor) as soma
    from obtido
    group by recorte_codigo
),

esperado_al (categoria, valor) as (
    values
        ('Bissexual',              0.5),
        ('Homossexual',            1.4),
        ('Heterossexual',         96.6),
        ('Outra orientação',       0.0),
        ('Não sabe',               0.7),
        ('Recusou-se a responder', 0.8)
)

select 'ufs_sem_dado' as problema, null::int as recorte_codigo, null::text as categoria,
       27::numeric as esperado, (select count(*) from por_uf)::numeric as obtido
where (select count(*) from por_uf) <> 27

union all
select 'categorias_por_uf', recorte_codigo, null, 6, n_categorias
from por_uf where n_categorias <> 6

union all
select 'soma_100', recorte_codigo, null, 100, soma
from por_uf where abs(soma - 100) > 0.5

union all
select 'valor_alagoas', 27, e.categoria, e.valor, o.valor
from esperado_al e
left join obtido o on o.recorte_codigo = 27 and o.categoria = e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.05
