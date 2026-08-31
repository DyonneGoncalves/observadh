-- Valida os indicadores "extras" (nível nacional) contra as planilhas de
-- cálculo da equipe: seção 6 (CRAS/Centros de Convivência), 7.0 (local de
-- ocorrência e perfil do agressor) e 7.1 (local e relação do suspeito).
-- Falha (retorna linhas) se algum valor divergir (tolerância 0,01).

with esperado (secao, indicador, categoria, valor) as (
    values
        -- seção 6 (cálculo direto do raw)
        ('6', 'pct_cras_abordaram_tema',                null,          43.0655),
        ('6', 'pct_centros_convivencia_abordaram_tema', null,          53.7751),
        -- 7.0 local de ocorrência
        ('7.0', 'pct_viol_interpessoal_por_local',  'Residência',  54.110869),
        ('7.0', 'pct_viol_interpessoal_por_local',  'Via pública', 20.928060),
        ('7.0', 'pct_viol_autoprovocada_por_local', 'Residência',  83.192236),
        -- 7.0 perfil do agressor
        ('7.0', 'pct_viol_interpessoal_por_agressor', 'Pai, mãe, padrasto, madrasta, irmão(ã) ou filho(a)', 16.859587),
        ('7.0', 'pct_viol_interpessoal_por_agressor', 'Cônjuges, namorados, ex-cônjuges ou ex-namorados',   32.905553),
        -- 7.1 ONDH local
        ('7.1', 'pct_denuncias_por_local', 'Casa da vítima',                          35.081927),
        ('7.1', 'pct_denuncias_por_local', 'Casa onde reside a vítima e o suspeito',  20.469552),
        -- 7.1 ONDH relação do suspeito
        ('7.1', 'pct_denuncias_por_relacao_suspeito', 'Outros',     24.384297),
        ('7.1', 'pct_denuncias_por_relacao_suspeito', 'Pai/mãe',    14.325774),
        ('7.1', 'pct_denuncias_por_relacao_suspeito', 'Vizinho(a)', 10.546208)
),

obtido as (
    select secao, indicador, categoria, valor
    from {{ ref('lgbtqia_plus_indicadores') }}
    where nivel = 'nacional' and secao in ('6', '7.0', '7.1')
)

select e.secao, e.indicador, e.categoria, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o
    on o.secao = e.secao and o.indicador = e.indicador
   and o.categoria is not distinct from e.categoria
where o.valor is null or abs(o.valor - e.valor) > 0.01
