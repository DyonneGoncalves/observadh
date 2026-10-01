{% macro classifica_ici(valor_coluna) %}
    -- Reproduz a fórmula Excel da aba "Classificação valores ICI"
    -- (V1_ICI_Estadual_RelatoriosObservaDH.xlsx):
    --   =SE(E(F2>=0;F2<=0,59);"Baixa capacidade institucional";
    --      SE(E(F2>=0,6;F2<=0,79);"Moderada capacidade institucional";
    --      SE(F2>=0,8;"Alta capacidade institucional";"Fora do intervalo")))
    --
    -- Única fonte da regra no repositório: nem a planilha estadual (grafia
    -- inconsistente, ver catálogo Problema 7) nem nenhuma planilha municipal
    -- (não tem a coluna) são usadas — todo indicador é classificado a partir
    -- do valor numérico por esta macro.
    case
        when {{ valor_coluna }} is null then null
        when {{ valor_coluna }} >= 0   and {{ valor_coluna }} <= 0.59 then 'Baixa capacidade institucional'
        when {{ valor_coluna }} >= 0.6 and {{ valor_coluna }} <= 0.79 then 'Moderada capacidade institucional'
        when {{ valor_coluna }} >= 0.8 then 'Alta capacidade institucional'
        else 'Fora do intervalo'
    end
{% endmacro %}
