-- Intermediate: seção 6 (abertura) — CRAS e Centros de Convivência: discussão
-- do tema orientação sexual / identidade de gênero. Formato LONGO. N/E/M.
--
-- Fórmulas (Cálculo_Indicadores_LGBTQIA+, 6):
--   pct_cras_abordaram_tema                 CRAS que abordaram / CRAS que ofertavam SCFV × 100
--   pct_centros_convivencia_abordaram_tema  Centros que abordaram / total de Centros × 100
-- Censo SUAS 2024. Percentuais recalculados a partir dos totais agregados por nível.

with cras as (
    select
        {{ codigo_num('cod_uf') }}     as uf_codigo,
        {{ codigo_num('cod_ibge_7') }} as municipio_codigo_ibge,
        abordaram_frequentemente_o_tema_de_orient_sexual_e_iden::numeric   as abordaram,
        ofertavam_servico_de_convivencia_e_fortalecimento_de_vi::numeric   as ofertavam_scfv
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_cras_temas_abordados') }}
),
centros as (
    select
        {{ codigo_num('cod_uf') }}     as uf_codigo,
        {{ codigo_num('cod_ibge_7') }} as municipio_codigo_ibge,
        abordaram_frequentemente_o_tema_de_orient_sexual_e_iden::numeric as abordaram,
        num_total_de_centros_de_convivencia::numeric                     as total_centros
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_centros_convivencia_temas') }}
),

cras_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, sum(abordaram) as ab, sum(ofertavam_scfv) as den from cras
    union all select 'estadual', uf_codigo, sum(abordaram), sum(ofertavam_scfv) from cras group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(abordaram), sum(ofertavam_scfv) from cras group by municipio_codigo_ibge
),
centros_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, sum(abordaram) as ab, sum(total_centros) as den from centros
    union all select 'estadual', uf_codigo, sum(abordaram), sum(total_centros) from centros group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(abordaram), sum(total_centros) from centros group by municipio_codigo_ibge
),

dim_uf  as ( select codigo_uf, nome_uf from {{ ref('dim_uf') }} ),
dim_mun as ( select codigo_municipio, nome_municipio from {{ ref('dim_municipio') }} ),

linhas as (
    select nivel, recorte_codigo, 'pct_cras_abordaram_tema'::text as indicador,
           {{ calcula_percentual('ab', 'den') }} as valor from cras_agg
    union all
    select nivel, recorte_codigo, 'pct_centros_convivencia_abordaram_tema',
           {{ calcula_percentual('ab', 'den') }} from centros_agg
)

select
    l.nivel,
    l.recorte_codigo,
    case l.nivel when 'nacional' then 'Brasil' when 'estadual' then u.nome_uf when 'municipal' then m.nome_municipio end as recorte_nome,
    '6'::text                                                as secao,
    'Assistência social — CRAS e Centros de Convivência'::text as secao_nome,
    l.indicador,
    null::text                                               as categoria,
    l.valor,
    'percentual'::text                                       as valor_tipo,
    2024                                                     as ano_referencia
from linhas l
left join dim_uf  u on l.nivel = 'estadual'  and u.codigo_uf = l.recorte_codigo
left join dim_mun m on l.nivel = 'municipal' and m.codigo_municipio = l.recorte_codigo
where l.nivel = 'nacional'
   or (l.nivel = 'estadual'  and u.codigo_uf is not null)
   or (l.nivel = 'municipal' and m.codigo_municipio is not null)
