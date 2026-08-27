# TODO: dim_municipio.csv

Este seed ainda não foi criado propositalmente: a tabela de municípios do
IBGE tem ~5.570 linhas e precisa vir de uma fonte oficial (malha municipal /
tabela de códigos do IBGE), não deve ser digitada ou aproximada manualmente
— um código errado de município quebra silenciosamente qualquer agregação
municipal.

Colunas sugeridas, no mesmo padrão do dim_uf.csv:

    codigo_municipio,nome_municipio,codigo_uf,sigla_uf

Quando formos buscar os dados reais (via a base de códigos municipais do
IBGE), este arquivo substitui este TODO.
