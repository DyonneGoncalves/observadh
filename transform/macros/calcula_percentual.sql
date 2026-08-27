{% macro calcula_percentual(numerador, denominador, casas_decimais=2) %}
    -- Macro reutilizável entre todos os temas: percentual arredondado,
    -- protegido contra divisão por zero (retorna null em vez de erro).
    case
        when {{ denominador }} is null or {{ denominador }} = 0 then null
        else round(100.0 * {{ numerador }} / {{ denominador }}, {{ casas_decimais }})
    end
{% endmacro %}
