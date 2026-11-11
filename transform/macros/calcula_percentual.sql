{% macro calcula_percentual(numerador, denominador, casas_decimais=4, sem_denominador=0) %}
    -- Macro reutilizável entre todos os temas: percentual arredondado,
    -- protegido contra divisão por zero. Quando o denominador é nulo ou zero
    -- devolve `sem_denominador` (padrão 0 — "sem casos" lê-se como 0%). Para
    -- indicadores de variação/crescimento, passe sem_denominador='null', já
    -- que "variação a partir de zero" não é 0%.
    --
    -- Precisão: grava 4 casas e NÃO arredonda para exibição. O arredondamento
    -- para 1 casa é feito uma única vez, na aplicação. Arredondar aqui para
    -- 2 casas causava arredondamento duplo (ex.: 16,7487 -> 16,75 -> 16,8,
    -- quando o correto é 16,7 — PNS 2019, "Recusou-se a responder / Rural").
    case
        when {{ denominador }} is null or {{ denominador }} = 0 then {{ sem_denominador }}
        else round(100.0 * {{ numerador }} / {{ denominador }}, {{ casas_decimais }})
    end
{% endmacro %}
