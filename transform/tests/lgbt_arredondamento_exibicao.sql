-- Regressão do arredondamento duplo (macro calcula_percentual).
-- A aplicação exibe 1 casa decimal. Antes, o banco gravava 2 casas (16,75)
-- e a aplicação arredondava de novo (16,8). O valor real é 16,7487 -> 16,7.
-- Fonte: PNS 2019, aba Pessoas_Area_Localidade (606.566 / 3.621.580).
-- Falha (retorna linhas) se o valor exibido (1 casa) divergir do esperado.

with esperado (categoria, valor_exibido) as (
    values
        ('Recusou-se a responder / Rural',  16.7),
        ('Recusou-se a responder / Urbana', 83.3)
),

obtido as (
    select categoria, valor
    from {{ ref('lgbt_indicadores') }}
    where nivel = 'nacional' and indicador = 'pct_orientacao_por_localidade'
)

select e.categoria, e.valor_exibido as esperado, o.valor as valor_banco,
       round(o.valor, 1) as exibido
from esperado e
left join obtido o on o.categoria = e.categoria
where o.valor is null or round(o.valor, 1) <> e.valor_exibido
