-- Intermediate: PAEFI por município (já vem nessa granularidade — sem
-- agregação necessária aqui, só um ponto de nomeação estável para os marts).

select
    municipio_codigo_ibge,
    municipio_nome,
    uf_codigo,
    uf_sigla,
    ano_referencia,
    qtd_vitimas_paefi
from {{ ref('stg_lgbtqia_plus_paefi') }}
