{% macro orientacao_canonica(col) -%}
-- Padroniza o rótulo de orientação sexual (as abas da PNS usam grafias
-- diferentes: "Heterosexual" vs "Heterossexual", "Homosexual" vs "Homossexual").
(case
    when lower({{ col }}) like 'hetero%'                                    then 'Heterossexual'
    when lower({{ col }}) like 'homo%' or lower({{ col }}) like 'gay%'      then 'Homossexual'
    when lower({{ col }}) like 'bi%'                                        then 'Bissexual'
    when lower({{ col }}) like 'outra%'                                     then 'Outra orientação'
    when lower({{ col }}) like 'n_o sabe%' or lower({{ col }}) like 'nao sabe%' then 'Não sabe'
    when lower({{ col }}) like 'recus%'                                     then 'Recusou-se a responder'
    else {{ col }}
end)
{%- endmacro %}
