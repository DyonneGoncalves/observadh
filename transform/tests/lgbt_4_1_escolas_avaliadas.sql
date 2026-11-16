-- Valida escolas_avaliadas_saeb (seção 4.1), chamado 27607 item 3.
-- Falha (retorna linhas) se algum recorte/ano que tem pct_escolas_com_projeto
-- não tiver o nº de escolas avaliadas correspondente, ou se ele for <= 0,
-- ou se a soma das UFs não bater com o Brasil.

with pct as (
    select nivel, recorte_codigo, categoria
    from {{ ref('lgbt_indicadores') }}
    where secao = '4.1' and indicador = 'pct_escolas_com_projeto'
),

esc as (
    select nivel, recorte_codigo, categoria, valor
    from {{ ref('lgbt_indicadores') }}
    where secao = '4.1' and indicador = 'escolas_avaliadas_saeb'
),

soma_uf as (
    select categoria, sum(valor) as soma from esc where nivel = 'estadual' group by categoria
)

select 'faltando_ou_zero' as problema, p.nivel, p.recorte_codigo, p.categoria, e.valor as obtido
from pct p
left join esc e
    on e.nivel = p.nivel
   and e.recorte_codigo is not distinct from p.recorte_codigo
   and e.categoria = p.categoria
where e.valor is null or e.valor <= 0

union all

select 'soma_ufs_difere_brasil', 'nacional', null, n.categoria, s.soma
from esc n
join soma_uf s on s.categoria = n.categoria
where n.nivel = 'nacional' and n.valor <> s.soma
