-- Teste estrutural: cada (nivel, indice, ano_referencia) deve ter exatamente
-- 27 linhas no estadual (27 UFs) e 5.570 no municipal (municípios oficiais
-- do IBGE — ver catálogo, seção 3.2). Uma contagem fora disso indica
-- problema de join (dim_uf/dim_municipio) ou de origem. dbt falha o build
-- se esta query devolver alguma linha.

select nivel, indice, ano_referencia, count(*) as linhas
from {{ ref('ici_indicadores') }}
group by nivel, indice, ano_referencia
having
    (nivel = 'estadual'  and count(*) <> 27)
    or (nivel = 'municipal' and count(*) <> 5570)
