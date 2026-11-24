-- Valida o indicador conjuges_mesmo_sexo_2010 no nível MUNICIPAL
-- (aba Censo_2010_Munic). Falha (retorna linhas) se:
--   1) a soma dos municípios não bater com o total nacional (60.035); ou
--   2) algum município de referência divergir da planilha.

with mun as (
    select recorte_codigo, valor
    from {{ ref('lgbt_indicadores') }}
    where nivel = 'municipal' and indicador = 'conjuges_mesmo_sexo_2010'
),

nac as (
    select valor
    from {{ ref('lgbt_indicadores') }}
    where nivel = 'nacional' and indicador = 'conjuges_mesmo_sexo_2010'
),

esperado (recorte_codigo, valor) as (
    values
        (2700409, 6.0),   -- Atalaia (AL)
        (1100023, 10.0),  -- Ariquemes (RO)
        (1100031, 0.0)    -- Cabixi (RO) — "-" na origem
)

select 'soma_municipios' as checagem, null::int as recorte_codigo,
       (select valor from nac) as valor_esperado, sum(valor) as valor_obtido
from mun
having abs(coalesce(sum(valor), 0) - (select valor from nac)) > 0.01

union all

select 'municipio', e.recorte_codigo, e.valor, m.valor
from esperado e
left join mun m on m.recorte_codigo = e.recorte_codigo
where m.valor is null or abs(m.valor - e.valor) > 0.01
