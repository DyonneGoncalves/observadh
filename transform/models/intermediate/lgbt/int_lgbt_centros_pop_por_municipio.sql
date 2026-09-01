-- Intermediate: % de Centros POP que atenderam pessoas LGBTQIA+, por
-- município.
-- Fórmula (calculo_nacional.md, 6.1): (Atenderam / Nº total de Centros Pop) x 100

select
    municipio_codigo_ibge,
    municipio_nome,
    uf_codigo,
    uf_sigla,
    ano_referencia,
    qtd_total_centros_pop,
    qtd_atenderam_lgbt,
    {{ calcula_percentual('qtd_atenderam_lgbt', 'qtd_total_centros_pop') }} as pct_centros_pop_atenderam_lgbt
from {{ ref('stg_lgbt_centros_pop') }}
