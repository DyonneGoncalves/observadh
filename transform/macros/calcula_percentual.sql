{% macro calcula_percentual(numerador, denominador, casas_decimais=2, sem_denominador=0) %}
    -- Macro reutilizável entre todos os temas: percentual arredondado,
    -- protegido contra divisão por zero. Quando o denominador é nulo ou zero
    -- devolve `sem_denominador` (padrão 0 — "sem casos" lê-se como 0%). Para
    -- indicadores de variação/crescimento, passe sem_denominador='null', já
    -- que "variação a partir de zero" não é 0%.
    case
        when {{ denominador }} is null or {{ denominador }} = 0 then {{ sem_denominador }}
        else round(100.0 * {{ numerador }} / {{ denominador }}, {{ casas_decimais }})
    end
{% endmacro %}
