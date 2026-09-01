#!/usr/bin/env python3
"""Gera o dicionário de indicadores do relatório LGBTQIA+ (formato longo).

Uma linha por indicador. Junta o que está no banco (seção, níveis, tipo,
categorias, ano) com a descrição humana (mapa DESCRICOES abaixo). É o
"de-para" que o dev usa pra fazer bind: a chave do mapa dele é
`indicador` (indicador simples) ou `indicador|categoria` (com quebra).

Uso:
    python scripts/gera_dicionario_lgbt.py [ARQUIVO_SAIDA.csv]

Conexão: variáveis padrão do libpq (PGHOST/PGDATABASE/...) ou banco local
"observadh". Schema dos marts: OBSERVADH_MARTS_SCHEMA (padrão dev_marts).
"""
import csv
import os
import sys

import psycopg2

SCHEMA = os.environ.get("OBSERVADH_MARTS_SCHEMA", "dev_marts")
DB = os.environ.get("PGDATABASE", "observadh")
SAIDA = sys.argv[1] if len(sys.argv) > 1 else "docs/lgbt/dicionario-lgbt_indicadores.csv"

# unidade + descrição por indicador. unidade ∈ {%, contagem, variação %}.
DESCRICOES = {
    # 1 — População
    "pct_populacao_lgbt_18_mais": ("%", "% da população de 18+ que se declara LGBTQIA+ (homo + bi + outra orientação), PNS 2019."),
    "conjuges_mesmo_sexo_2010": ("contagem", "Nº de pessoas em união com cônjuge do mesmo sexo, Censo 2010."),
    "conjuges_mesmo_sexo_2022": ("contagem", "Nº de pessoas em união com cônjuge do mesmo sexo, Censo 2022."),
    "pessoas_uniao_mesmo_sexo_estimativa": ("contagem", "Estimativa de pessoas em união do mesmo sexo (cônjuges 2022 × 2)."),
    # 2 — Perfil (PNS 2019, só nacional)
    "pct_populacao_por_orientacao": ("%", "Composição da população 18+ por orientação sexual."),
    "pct_orientacao_por_sexo": ("%", "Dentro de cada orientação, distribuição por sexo (homens/mulheres)."),
    "pct_orientacao_por_faixa_etaria": ("%", "Dentro de cada orientação, distribuição por faixa etária."),
    "pct_orientacao_por_raca_cor": ("%", "Dentro de cada orientação, distribuição por raça/cor."),
    "pct_orientacao_por_localidade": ("%", "Dentro de cada orientação, distribuição urbana/rural."),
    # 2.5 — Casamentos e uniões
    "casamentos_mesmo_sexo_total_ano": ("contagem", "Série anual (2013–2023) do total de casamentos entre pessoas do mesmo sexo no recorte."),
    "variacao_casamentos_mesmo_sexo_13_23": ("variação %", "Variação % do total de casamentos do mesmo sexo entre 2013 e 2023."),
    "pct_casamentos_mesmo_sexo_por_genero_23": ("%", "Composição por gênero (entre homens / entre mulheres) dos casamentos do mesmo sexo em 2023."),
    "pct_casamentos_lesbohomoafetivos": ("%", "Casamentos lesbohomoafetivos como % dos casamentos entre cônjuges masc-fem (base 2022)."),
    "pct_estado_civil_por_orientacao": ("%", "Dentro de cada orientação, distribuição por estado civil (PNS 2019)."),
    "pct_natureza_juridica_por_orientacao": ("%", "Dentro de cada orientação, casamento civil vs união estável (PNS 2019)."),
    # 3 — Trabalho e renda (só nacional)
    "pct_pessoas_ocupadas_por_orientacao": ("%", "Taxa de ocupação por orientação sexual (PNS 2019)."),
    "pct_renda_per_capita_por_orientacao": ("%", "Dentro de cada orientação, distribuição por faixa de renda per capita (5 faixas de salário mínimo)."),
    # 4 — Educação
    "pct_nivel_instrucao_por_orientacao": ("%", "Dentro de cada orientação, distribuição por nível de instrução (7 níveis, PNS 2019). Só nacional."),
    "pct_escolas_com_projeto": ("%", "% de escolas com projeto de enfrentamento à LGBTQIAfobia, por ano (2019 / 2021)."),
    "pct_escolas_com_projeto_uf_maior": ("%", "UF com o maior % de escolas com projeto em 2021 (categoria = nome da UF). Só nacional."),
    "pct_escolas_com_projeto_uf_menor": ("%", "UF com o menor % de escolas com projeto em 2021 (categoria = nome da UF). Só nacional."),
    "pct_escolas_com_projeto_localizacao_2021": ("%", "% de escolas com projeto em 2021, por localização (urbana / rural)."),
    # 5 — Saúde
    "pct_autoavaliacao_saude_por_orientacao": ("%", "Dentro de cada orientação, autoavaliação de saúde (muito boa+boa / regular / muito ruim+ruim). Só nacional."),
    "pct_atividade_esportiva_por_orientacao": ("%", "Dentro de cada orientação, frequência de atividade esportiva (6 faixas). Só nacional."),
    "pct_depressao_por_orientacao": ("%", "Dentro de cada orientação, % com/sem diagnóstico de depressão. Só nacional."),
    "estabelecimentos_total": ("contagem", "Nº total de estabelecimentos de saúde habilitados para pessoas trans (CNES)."),
    "estabelecimentos_por_habilitacao": ("contagem", "Nº de estabelecimentos por tipo de habilitação (Ambulatorial / Hospitalar / Ambulatorial-Hospitalar)."),
    "estados_com_habilitacao_hospitalar": ("contagem", "Nº de UFs com pelo menos um estabelecimento de habilitação hospitalar. Só nacional."),
    "estados_com_habilitacao_ambulatorial": ("contagem", "Nº de UFs com pelo menos um estabelecimento de habilitação ambulatorial. Só nacional."),
    "estados_sem_servico": ("contagem", "Nº de UFs sem nenhum estabelecimento habilitado. Só nacional."),
    # 6 — Assistência social
    "pct_cras_abordaram_tema": ("%", "% de CRAS que abordaram o tema LGBTQIA+ (entre os que ofertavam SCFV)."),
    "pct_centros_convivencia_abordaram_tema": ("%", "% de Centros de Convivência que abordaram o tema LGBTQIA+."),
    # 6.1 — Proteção social especial
    "vitimas_paefi": ("contagem", "Nº de pessoas vítimas de discriminação por orientação sexual acompanhadas pelo PAEFI (2024; série 2017–2024 no municipal)."),
    "creas_total": ("contagem", "Nº total de CREAS."),
    "creas_nao_atende_orientacao": ("contagem", "Nº de CREAS que não registram atendimento a discriminação por orientação sexual."),
    "pct_creas_nao_atende_orientacao": ("%", "creas_nao_atende_orientacao / creas_total ×100."),
    "creas_nao_atende_identidade": ("contagem", "Nº de CREAS que não registram atendimento a discriminação por identidade de gênero."),
    "pct_creas_nao_atende_identidade": ("%", "creas_nao_atende_identidade / creas_total ×100."),
    "centros_pop_total": ("contagem", "Nº total de Centros POP."),
    "pct_centros_pop_atenderam_lgbt": ("%", "% de Centros POP que atenderam pessoas LGBTQIA+."),
    "unidades_acolhimento_total": ("contagem", "Nº total de unidades de acolhimento (após remoção de linhas duplicadas na base)."),
    "pct_unidades_acolhimento_com_pessoas_trans": ("%", "% de unidades de acolhimento com pessoas trans/travestis acolhidas."),
    "pessoas_acolhidas_total": ("contagem", "Nº total de pessoas acolhidas (todas)."),
    "pessoas_trans_acolhidas_total": ("contagem", "Nº de pessoas trans/travestis acolhidas."),
    # 7.0 — SINAN
    "notificacoes_por_ano": ("contagem", "Série anual (2015–2024) de notificações de violência (SINAN) contra pop. LGBTQIA+."),
    "notificacoes_total_2024": ("contagem", "Nº de notificações de violência (SINAN) em 2024."),
    "pct_notificacoes_por_tipo_2024": ("%", "Composição das notificações de 2024 por tipo (interpessoal / autoprovocada / origem desconhecida)."),
    "pct_municipios_com_notificacao_2024": ("%", "% de municípios com ao menos uma notificação em 2024 (nacional ÷5.570; estadual ÷ municípios da UF)."),
    "pct_viol_interpessoal_por_sexo": ("%", "Violência interpessoal (SINAN 2024): distribuição das vítimas por sexo."),
    "pct_viol_interpessoal_por_faixa_etaria": ("%", "Violência interpessoal (SINAN 2024): distribuição das vítimas por faixa etária."),
    "pct_viol_interpessoal_por_raca_cor": ("%", "Violência interpessoal (SINAN 2024): distribuição das vítimas por raça/cor."),
    "pct_viol_interpessoal_por_orientacao_sexual": ("%", "Violência interpessoal (SINAN 2024): distribuição das vítimas por orientação sexual (heterossexual é derivado)."),
    "pct_viol_interpessoal_por_identidade_genero": ("%", "Violência interpessoal (SINAN 2024): distribuição das vítimas por identidade de gênero."),
    "pct_viol_interpessoal_por_local": ("%", "Violência interpessoal (SINAN 2024): distribuição por local de ocorrência (10 grupos; denominador = soma das 10)."),
    "pct_viol_interpessoal_por_agressor": ("%", "Violência interpessoal (SINAN 2024): distribuição por vínculo do agressor (6 grupos)."),
    "pct_viol_autoprovocada_por_sexo": ("%", "Violência autoprovocada (SINAN 2024): distribuição por sexo."),
    "pct_viol_autoprovocada_por_faixa_etaria": ("%", "Violência autoprovocada (SINAN 2024): distribuição por faixa etária."),
    "pct_viol_autoprovocada_por_raca_cor": ("%", "Violência autoprovocada (SINAN 2024): distribuição por raça/cor."),
    "pct_viol_autoprovocada_por_orientacao_sexual": ("%", "Violência autoprovocada (SINAN 2024): distribuição por orientação sexual (heterossexual é derivado)."),
    "pct_viol_autoprovocada_por_identidade_genero": ("%", "Violência autoprovocada (SINAN 2024): distribuição por identidade de gênero."),
    "pct_viol_autoprovocada_por_local": ("%", "Violência autoprovocada (SINAN 2024): distribuição por local de ocorrência (10 grupos; denominador = soma das 10)."),
    # 7.1 — ONDH / Disque 100
    "denuncias_por_ano": ("contagem", "Série anual (2020–2024) de denúncias de violações de direitos humanos (Disque 100 / ONDH) da pop. LGBTQIA+."),
    "violacoes_por_ano": ("contagem", "Série anual (2020–2024) de violações (uma denúncia pode ter várias violações)."),
    "denuncias_total_2020_2024": ("contagem", "Total de denúncias acumuladas 2020–2024."),
    "pct_participacao_denuncias_2024": ("%", "Participação do recorte no total nacional de denúncias de 2024 (recorte / 8.176 ×100). Só estadual e municipal."),
    "pct_denuncias_por_sexo": ("%", "Denúncias 2024: distribuição por sexo (denominador exclui 'não informado')."),
    "pct_denuncias_por_faixa_etaria": ("%", "Denúncias 2024: distribuição por faixa etária (denominador = soma das faixas)."),
    "pct_denuncias_por_raca_cor": ("%", "Denúncias 2024: distribuição por raça/cor."),
    "pct_denuncias_por_identidade_genero": ("%", "Denúncias 2024: distribuição por identidade de gênero (8 categorias)."),
    "pct_denuncias_por_orientacao_sexual": ("%", "Denúncias 2024: distribuição por orientação sexual (6 categorias)."),
    "pct_denuncias_por_tipo_violacao": ("%", "Denúncias 2024: % de denúncias que citam cada tipo de violação (~103 tipos; uma denúncia pode citar vários)."),
    "pct_denuncias_por_local": ("%", "Denúncias 2024: distribuição por local da violação (~31 categorias)."),
    "pct_denuncias_por_relacao_suspeito": ("%", "Denúncias 2024: distribuição pelo vínculo do suspeito com a vítima (~46 categorias)."),
}

SQL = f"""
select
    i.secao, i.secao_nome, i.indicador, i.valor_tipo,
    string_agg(distinct i.nivel, '/' order by i.nivel)                       as niveis,
    count(distinct i.categoria) filter (where i.categoria is not null)       as n_categorias,
    string_agg(distinct i.categoria, ' | ' order by i.categoria)             as categorias,
    min(i.ano_referencia) as ano_min, max(i.ano_referencia) as ano_max
from {SCHEMA}.lgbt_indicadores i
group by i.secao, i.secao_nome, i.indicador, i.valor_tipo
order by
    (regexp_replace(i.secao, '\\D.*$', ''))::int,
    i.secao, i.indicador
"""

NIV = {"nacional": "N", "estadual": "E", "municipal": "M"}


def sigla_niveis(s):
    return "".join(NIV[x] for x in ["nacional", "estadual", "municipal"] if x in s.split("/"))


def main():
    conn = psycopg2.connect(dbname=DB)
    rows = []
    with conn.cursor() as cur:
        cur.execute(SQL)
        for (secao, secao_nome, indicador, valor_tipo, niveis, n_cat,
             categorias, ano_min, ano_max) in cur.fetchall():
            unidade, descricao = DESCRICOES.get(indicador, ("", ""))
            tem_quebra = (n_cat or 0) > 0
            chave = f"{indicador}|<categoria>" if tem_quebra else indicador
            ano = str(ano_min) if ano_min == ano_max else f"{ano_min}–{ano_max}"
            rows.append({
                "secao": secao,
                "secao_nome": secao_nome,
                "indicador": indicador,
                "chave_bind": chave,
                "tem_quebra_categoria": "sim" if tem_quebra else "nao",
                "categorias": categorias or "",
                "valor_tipo": valor_tipo,
                "unidade": unidade,
                "niveis": sigla_niveis(niveis),
                "ano_referencia": ano,
                "descricao": descricao,
            })
    conn.close()

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    campos = ["secao", "secao_nome", "indicador", "chave_bind",
              "tem_quebra_categoria", "categorias", "valor_tipo", "unidade",
              "niveis", "ano_referencia", "descricao"]
    with open(SAIDA, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=campos)
        w.writeheader()
        w.writerows(rows)

    sem_desc = [r["indicador"] for r in rows if not r["descricao"]]
    print(f"{len(rows)} indicadores -> {SAIDA}")
    if sem_desc:
        print(f"SEM DESCRIÇÃO ({len(sem_desc)}): {', '.join(sem_desc)}")


if __name__ == "__main__":
    main()
