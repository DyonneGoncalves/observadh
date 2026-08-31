# Catálogo de indicadores — LGBTQIA+

Guia de trabalho que liga cada **seção do relatório** à sua **fórmula**, à **aba do Excel** de
origem, à **tabela `raw`** já ingerida e ao **modelo dbt** que a produz (ou "a fazer").

Fonte de verdade: os 6 documentos nesta pasta.

| Documento | Papel |
|---|---|
| `Cálculo_Indicadores_LGBTQIA+_Nacional_V2.docx` | Especificação dos cálculos — nível **Nacional** (Brasil) |
| `Cálculo_Indicadores_LGBTQIA+_Estadual_V2.docx` | Especificação dos cálculos — nível **Estadual** (por UF) |
| `Cálculo_Indicadores_LGBTQIA+_Municipal_V2.docx` | Especificação dos cálculos — nível **Municipal** |
| `LGBTQIA - TEXTO BASE_FILTRO NACIONAL_V3.docx` | Template da narrativa do relatório (prosa com lacunas) — Nacional |
| `LGBTQIA - TEXTO BASE_FILTRO ESTADUAL_V3.docx` | Idem — Estadual |
| `LGBTQIA - TEXTO BASE_FILTRO MUNICIPAL_V3.docx` | Idem — Municipal |

Os números **`X` / `X.Y`** são o **sumário do relatório**: `X` = seção, `X.Y` = subseção.
O relatório é gerado nos 3 níveis geográficos; nem toda seção existe em todos (ver coluna N/E/M
abaixo — **N**acional, **E**stadual, **M**unicipal).

---

## 1. Mapa de fontes — aba do Excel → tabela `raw`

Nome da tabela = `lgbt_<planilha>_<aba>`, onde `<planilha>` é a abreviação definida em
`ingestion/temas/lgbtqia_plus_config.yml` (`prefixos_planilha`) e `<aba>` é o nome **inteiro**
da aba, só normalizado. Reconferir após nova carga com
`python ingestion/ingest.py --tema lgbtqia_plus --ano <ano> --dry-run`.

### Assistência social — `lgbt_assist_social_*`
(`LGBTQIA_Assistência social_RMA_Censo SUAS_2017_2024.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| CRAS - Temas abordados | `lgbt_assist_social_cras_temas_abordados` |
| Centros de Convivência - Temas | `lgbt_assist_social_centros_de_convivencia_temas` |
| Série atendimentos PAEFI | `lgbt_assist_social_serie_atendimentos_paefi` |
| Atendim CREAS discri orient sex | `lgbt_assist_social_atendim_creas_discri_orient_sex` |
| Atendim CREAS discri ident gên | `lgbt_assist_social_atendim_creas_discri_ident_gen` |
| Centros Pop | `lgbt_assist_social_centros_pop` |
| Unidades de Acolhimento 2024 | `lgbt_assist_social_unidades_de_acolhimento_2024` |
| dLocalizacao | *(não ingerida — vira seed `dim_municipio`)* |

### Perfil / Registro Civil — `lgbt_perfil_pns_est_reg_civil_*`
(`LGBTQIA_Perfil_PNS_Estatísticas Registro Civil_2019_2013_2023_V2.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Pessoas_Orientacao_Sexo_Total | `lgbt_perfil_pns_est_reg_civil_pessoas_orientacao_sexo_total` |
| Pessoas_Faixa_Etaria | `lgbt_perfil_pns_est_reg_civil_pessoas_faixa_etaria` |
| Pessoas_Cor_ou_Raça | `lgbt_perfil_pns_est_reg_civil_pessoas_cor_ou_raca` |
| Pessoas_Area_Localidade | `lgbt_perfil_pns_est_reg_civil_pessoas_area_localidade` |
| Pessoas_Estado_civil | `lgbt_perfil_pns_est_reg_civil_pessoas_estado_civil` |
| Natureza_Jurídica_União | `lgbt_perfil_pns_est_reg_civil_natureza_juridica_uniao` |
| Casamento_Mesmo_Sexo_Ano | `lgbt_perfil_pns_est_reg_civil_casamento_mesmo_sexo_ano` |
| Total_Casamentos_UF | `lgbt_perfil_pns_est_reg_civil_total_casamentos_uf` |
| Orientação sexual por UF | `lgbt_perfil_pns_est_reg_civil_orientacao_sexual_por_uf` |

### Quantas são — `lgbt_quantas_sao_pns_censo_*`
(`LGBTQIA_Quantas são_PNS_2019_Censo_2010_2022.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Orientação sexual 2019 | `lgbt_quantas_sao_pns_censo_orientacao_sexual_2019` |
| Cônjuges do mesmo sexo 2022 | `lgbt_quantas_sao_pns_censo_conjuges_do_mesmo_sexo_2022` |
| Censo_2010_Munic | `lgbt_quantas_sao_pns_censo_censo_2010_munic` |
| Censo_2010_UF | `lgbt_quantas_sao_pns_censo_censo_2010_uf` |
| Censo_2010_Reg | `lgbt_quantas_sao_pns_censo_censo_2010_reg` |

### Trabalho — `lgbt_trab_pns_*`
(`LGBTQIA_Trabalho_PNS_2019.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Taxa de ocupação por orient sex | `lgbt_trab_pns_taxa_de_ocupacao_por_orient_sex` |
| Renda per capta | `lgbt_trab_pns_renda_per_capta` |

### Educação — `lgbt_educ_pns_saeb_*`
(`LGBTQIA_Educação_PNS_SAEB_2019_2021.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Nível de instrução | `lgbt_educ_pns_saeb_nivel_de_instrucao` |
| Projetos contra homofobia 2019 | `lgbt_educ_pns_saeb_projetos_contra_homofobia_2019` |
| Projetos contra homofobia 2021 | `lgbt_educ_pns_saeb_projetos_contra_homofobia_2021` |
| projeto_homofobia_local 2021 | `lgbt_educ_pns_saeb_projeto_homofobia_local_2021` |

### Saúde / CNES — `lgbt_saude_pns_cnes_*`
(`LGBTQIA_Saúde_PNS_Cnes_2019_2025_V2.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Autoavaliacao_saude_PNS | `lgbt_saude_pns_cnes_autoavaliacao_saude_pns` |
| Atividade_Esportiva_PNS | `lgbt_saude_pns_cnes_atividade_esportiva_pns` |
| Taxa_Depressao_PNS | `lgbt_saude_pns_cnes_taxa_depressao_pns` |
| Estabelecimento_CNES | `lgbt_saude_pns_cnes_estabelecimento_cnes` |

### Violência / ONDH — `lgbt_viol_ondh_*`
(`LGBTQIA_Violência_ONDH_2020_2024.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| ONDH_Serie_Historica_2020_2024 | `lgbt_viol_ondh_ondh_serie_historica_2020_2024` |
| ONDH_Sexo | `lgbt_viol_ondh_ondh_sexo` |
| ONDH_Faixa_Etária | `lgbt_viol_ondh_ondh_faixa_etaria` |
| ONDH_Raca_Cor | `lgbt_viol_ondh_ondh_raca_cor` |
| ONDH_Local | `lgbt_viol_ondh_ondh_local` |
| ONDH_Relação_Suspeito | `lgbt_viol_ondh_ondh_relacao_suspeito` |
| ONDH_Tipo_de_Violação | `lgbt_viol_ondh_ondh_tipo_de_violacao` |
| ONDH_Identidade_Genero | `lgbt_viol_ondh_ondh_identidade_genero` |
| ONDH_Orientacao_Sexual | `lgbt_viol_ondh_ondh_orientacao_sexual` |

### Violência / SINAN — `lgbt_viol_sinan_*`
(`LGBTQIA_Violências_Sinan_2015_2024.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Notificações_2015_2024_SINAN | `lgbt_viol_sinan_notificacoes_2015_2024_sinan` |
| Interpessoal_Local_Ocorrencia | `lgbt_viol_sinan_interpessoal_local_ocorrencia` |
| Autoprovocada_Local_Ocorrencia | `lgbt_viol_sinan_autoprovocada_local_ocorrencia` |
| Violências_Orientacao_Sexual | `lgbt_viol_sinan_violencias_orientacao_sexual` |
| Violencias_Identidade_Genero | `lgbt_viol_sinan_violencias_identidade_genero` |
| Interpessoal_Sexo_SINAN | `lgbt_viol_sinan_interpessoal_sexo_sinan` |
| Interpessoal_Faixa_Etária_SINAN | `lgbt_viol_sinan_interpessoal_faixa_etaria_sinan` |
| Interpessoal_Cor_ou_Raça | `lgbt_viol_sinan_interpessoal_cor_ou_raca` |
| Interpessoal-Tipos de violência | `lgbt_viol_sinan_interpessoal_tipos_de_violencia` |
| Autoprovocada_Sexo_SINAN | `lgbt_viol_sinan_autoprovocada_sexo_sinan` |
| Autoprovocada_Faixa_Etária | `lgbt_viol_sinan_autoprovocada_faixa_etaria` |
| Autoprovocada_Cor_ou_Raça | `lgbt_viol_sinan_autoprovocada_cor_ou_raca` |
| Interpessoal_Perfil_Agressor | `lgbt_viol_sinan_interpessoal_perfil_agressor` |
| ONDH - Identidade de gênero *(cópia dentro do arquivo SINAN)* | `lgbt_viol_sinan_ondh_identidade_de_genero` |

---

## 2. Catálogo por seção

Legenda **N/E/M**: níveis em que a subseção existe (**N**acional, **E**stadual, **M**unicipal).
"Modelo dbt" = "—" significa **a fazer**.

### 1. População LGBTQIA+ no Brasil — `N E M`

| Indicador (resumo) | Aba Excel | Tabela `raw` | Modelo dbt |
|---|---|---|---|
| % de 18+ com orientação LGBTQIA+ = (homossexual + bissexual + outra) / pop. 18+ ×100 *(N e E; sem versão M)* | Orientação sexual 2019 | `lgbt_quantas_sao_pns_censo_orientacao_sexual_2019` | — |
| Nº absoluto de cônjuges/companheiros(as) do mesmo sexo — Censo 2010 | Censo_2010_Reg (N) / Censo_2010_UF (E) / Censo_2010_Munic (M) | `lgbt_quantas_sao_pns_censo_censo_2010_reg` / `_uf` / `_munic` | — |
| Nº absoluto de cônjuges do mesmo sexo — 2022 | Cônjuges do mesmo sexo 2022 | `lgbt_quantas_sao_pns_censo_conjuges_do_mesmo_sexo_2022` | — |
| Estimativa "ao menos N mil pessoas" = soma 2010 (×2) + 2022 | Cônjuges do mesmo sexo 2022 | idem | — |

### 2. Perfil das pessoas LGBTQIA+ — `N E M`

**2.0 (abre a seção)** — % do total da população por orientação sexual X = total da orientação X / total com info de orientação ×100
· aba `Pessoas_Orientacao_Sexo_Total` → `lgbt_perfil_pns_est_reg_civil_pessoas_orientacao_sexo_total` *(N)*.
No **E**: "Número percentual por tipo X de orientação sexual" · aba `Orientação sexual por UF` → `lgbt_perfil_pns_est_reg_civil_orientacao_sexual_por_uf`.

| Sub | Indicador (resumo) | Aba Excel | Tabela `raw` | N/E/M | Modelo dbt |
|---|---|---|---|---|---|
| 2.1 | % de pessoas da orientação X que são do sexo Y = total orient. X / total do sexo Y na mesma orient. ×100 | Pessoas_Orientacao_Sexo_Total | `..._pessoas_orientacao_sexo_total` | N | — |
| 2.2 | % por faixa etária Y, dentro da orientação X | Pessoas_Faixa_Etaria | `..._pessoas_faixa_etaria` | N | — |
| 2.3 | % por cor/raça Y, dentro da orientação X | Pessoas_Cor_ou_Raça | `..._pessoas_cor_ou_raca` | N | — |
| 2.4 | % por área (urbana/rural) Y, dentro da orientação X | Pessoas_Area_Localidade | `..._pessoas_area_localidade` | N | — |
| 2.5 | % por estado civil X, dentro da orientação Y | Pessoas_Estado_civil | `..._pessoas_estado_civil` | N | — |
| 2.5 | % por natureza jurídica da união X, dentro da orientação Y | Natureza_Jurídica_União | `..._natureza_juridica_uniao` | N | — |
| 2.5 | Nº absoluto de casamentos entre pessoas do mesmo sexo por ano (2013, 2023); total lesbohomoafetivo = entre mulheres + entre homens | Casamento_Mesmo_Sexo_Ano | `..._casamento_mesmo_sexo_ano` | N E M | — |
| 2.5 | % de variação 2013→2023 = (uniões 2023 − uniões 2013) / uniões 2013 ×100 | Casamento_Mesmo_Sexo_Ano | idem | N E M | — |
| 2.5 | % de casamentos por gênero em 2023 = casamentos do gênero X / total geral lesbohomoafetivos 2023 ×100 | Casamento_Mesmo_Sexo_Ano | idem | N E M | — |
| 2.5 | % de casamentos do mesmo sexo por estado = registros do mesmo sexo na UF X / total geral de matrimônios na UF X ×100 | Casamento_Mesmo_Sexo_Ano | idem | N | — |
| 2.5 | % de casamentos lesbohomoafetivos por UF = lesbohomoafetivos na UF X / total de casamentos entre cônjuges na mesma UF ×100 | Total_Casamentos_UF | `..._total_casamentos_uf` | N | — |
| 2.6 | **População Trans** — percentuais fixos no texto, **sem base de dados** ("Sinalização CGTI") | — | — | N | n/a |

> `..._` = prefixo `lgbt_perfil_pns_est_reg_civil_`.
> No corpo dos docs Estadual e Municipal essa subseção aparece renumerada como **"2.1. Casamentos e uniões"** (o índice mantém 2.5). É a mesma coisa.

### 3. Trabalho e renda — `N` apenas (E e M = "Sem dados")

| Sub | Indicador (resumo) | Aba Excel | Tabela `raw` | Modelo dbt |
|---|---|---|---|---|
| 3.0 | % total Brasil por orientação sexual, 18+ | Taxa de ocupação por orient sex | `lgbt_trab_pns_taxa_de_ocupacao_por_orient_sex` | — |
| 3.0 | % 18+ por orientação sexual com renda per capita > 5 salários mínimos | Renda per capta | `lgbt_trab_pns_renda_per_capta` | — |
| 3.1 | **Pessoas Trans** — destaque de estudo do Ipea (2025), **sem base de dados** ("Sinalização CGTI") | — | — | n/a |

### 4. Educação — `N E` (M = "Sem dados")

| Sub | Indicador (resumo) | Aba Excel | Tabela `raw` | N/E | Modelo dbt |
|---|---|---|---|---|---|
| 4.0 | % por orientação sexual e nível de instrução | Nível de instrução | `lgbt_educ_pns_saeb_nivel_de_instrucao` | N | — |
| 4.0 | "O Censo Trans" — destaque **sem base de dados** ("Sinalização CGTI") | — | — | N | n/a |
| 4.1 | % de escolas com projeto contra LGBTQIAfobia = possui projeto / total (2021) ou / total com informação (2019) ×100 | Projetos contra homofobia 2021 / 2019 | `lgbt_educ_pns_saeb_projetos_contra_homofobia_2021` / `_2019` | N E | — |
| 4.1 | maior/menor % de escolas com projeto, por desagregação | Projetos contra homofobia 2021 | `lgbt_educ_pns_saeb_projetos_contra_homofobia_2021` | N | — |
| 4.1 | % de escolas com projeto por localização (urbana/rural) = escolas com projeto / total com info ×100 | projeto_homofobia_local 2021 | `lgbt_educ_pns_saeb_projeto_homofobia_local_2021` | N | — |

### 5. Saúde — `N E` (M = "Sem dados")

| Sub | Indicador (resumo) | Aba Excel | Tabela `raw` | N/E | Modelo dbt |
|---|---|---|---|---|---|
| 5.0 | % por tipo de autoavaliação da saúde, por orientação sexual (junta "muito boa+boa", "muito ruim+ruim") | Autoavaliacao_saude_PNS | `lgbt_saude_pns_cnes_autoavaliacao_saude_pns` | N | — |
| 5.0 | % por autoavaliação x atividade esportiva, por orientação sexual | Atividade_Esportiva_PNS | `lgbt_saude_pns_cnes_atividade_esportiva_pns` | N | — |
| 5.0 | % com/sem diagnóstico de depressão, por orientação sexual | Taxa_Depressao_PNS | `lgbt_saude_pns_cnes_taxa_depressao_pns` | N | — |

**5.1. Serviços de saúde para pessoas trans** — `N E` — ✅ **MODELADA (formato longo)**

| Indicador | `indicador` (slug) | `categoria` | N/E | Valor esperado (nacional) |
|---|---|---|---|---|
| Nº total de estabelecimentos | `estabelecimentos_total` | — | N E | 26 |
| Nº de estabelecimentos por tipo de habilitação | `estabelecimentos_por_habilitacao` | `Ambulatorial` / `Hospitalar` / `Ambulatorial/Hospitalar` | N E | 16 / 3 / 7 |
| Nº de UFs com habilitação hospitalar (Hospitalar ou Ambulatorial/Hospitalar) | `estados_com_habilitacao_hospitalar` | — | N | 8 |
| Nº de UFs só com habilitação ambulatorial | `estados_apenas_ambulatorial` | — | N | 7 |
| Nº de UFs sem nenhum serviço | `estados_sem_servico` | — | N | 12 |

Aba `Estabelecimento_CNES` → `lgbt_saude_pns_cnes_estabelecimento_cnes` →
`stg_lgbtqia_plus_estabelecimentos_saude_trans` →
`int_lgbtqia_plus_5_1_servicos_saude_trans` → mart `lgbtqia_plus_indicadores`.
Validação: `tests/lgbtqia_plus_5_1_valores_nacionais.sql` (contra a planilha de cálculo da equipe).

### 6. Assistência social — `N E M`

**6.0 (abre a seção)** — cobertura de CRAS e Centros de Convivência (Serviço de Convivência):

| Indicador (resumo) | Aba Excel | Tabela `raw` | N/E/M | Modelo dbt |
|---|---|---|---|---|
| % de CRAS que abordaram frequentemente orientação sexual/identidade de gênero = abordaram / ofertavam SCFV ×100 (também por UF) | CRAS - Temas abordados | `lgbt_assist_social_cras_temas_abordados` | N E | — |
| % de Centros de Convivência que abordaram o tema = abordaram / total de Centros ×100 (também por UF) | Centros de Convivência - Temas | `lgbt_assist_social_centros_de_convivencia_temas` | N E | — |

**6.1. Proteção social especial** — `N E M` — ✅ **PILOTO IMPLEMENTADO**

| Indicador (resumo) | Aba Excel | Tabela `raw` | Modelo dbt |
|---|---|---|---|
| Nº de vítimas de discriminação por orientação sexual que ingressaram no PAEFI (soma; série 2017–2024 no M) | Série atendimentos PAEFI | `lgbt_assist_social_serie_atendimentos_paefi` | `stg_lgbtqia_plus_paefi` → `int_lgbtqia_plus_paefi_por_municipio` |
| Nº total de CREAS | Atendim CREAS discri orient sex | `lgbt_assist_social_atendim_creas_discri_orient_sex` | `stg_lgbtqia_plus_creas_discriminacao_orientacao` |
| % de CREAS que **não** atendem discriminação por orientação sexual = não atende / total de CREAS ×100 | Atendim CREAS discri orient sex | idem | `int_lgbtqia_plus_creas_orientacao_por_municipio` (valida contra o % da planilha em `tests/`) |
| % de CREAS que **não** atendem discriminação por identidade de gênero = não atende / total de CREAS ×100 | Atendim CREAS discri ident gên | `lgbt_assist_social_atendim_creas_discri_ident_gen` | `int_lgbtqia_plus_creas_identidade_por_municipio` (idem) |
| Nº total de Centros POP | Centros Pop | `lgbt_assist_social_centros_pop` | `stg_lgbtqia_plus_centros_pop` |
| % de Centros POP que atenderam LGBTQIA+ = atenderam / total ×100 | Centros Pop | idem | `int_lgbtqia_plus_centros_pop_por_municipio` |
| % de unidades de acolhimento com pessoas trans/travestis = "possui (Sim)" / "possui (Sim + Não)" ×100 | Unidades de Acolhimento 2024 | `lgbt_assist_social_unidades_de_acolhimento_2024` | `int_lgbtqia_plus_acolhimento_por_municipio` |
| Nº de pessoas trans/travestis acolhidas (soma) | Unidades de Acolhimento 2024 | idem | idem |

Marts: `lgbtqia_plus_relatorio_nacional` / `_estadual` / `_municipal`.

### 7. Violência contra pessoas LGBTQIA+ — `N E M`

**7.0 (abre a seção — base SINAN)**:

| Indicador (resumo) | Aba Excel | Tabela `raw` | Modelo dbt |
|---|---|---|---|
| Soma de denúncias 2024 (`qtd_denuncias_2024`) | Notificações_2015_2024_SINAN | `lgbt_viol_sinan_notificacoes_2015_2024_sinan` | — |
| % de notificações por tipo (interpessoal / autoprovocada / origem desconhecida) sobre o total com info, 2024 | Notificações_2015_2024_SINAN | idem | — |
| Série do total de notificações por ano (2015–2024) | Notificações_2015_2024_SINAN | idem | — |
| % de municípios com ≥1 notificação em 2024 (÷ 5570 no N; ÷ total do estado no E/M) | Notificações_2015_2024_SINAN | idem | — |
| Maior % de local de ocorrência (interpessoal / autoprovocada) | Interpessoal_Local_Ocorrencia / Autoprovocada_Local_Ocorrencia | `lgbt_viol_sinan_interpessoal_local_ocorrencia` / `..._autoprovocada_local_ocorrencia` | — |
| % de notificações por origem da agressão × orientação sexual | Violências_Orientacao_Sexual | `lgbt_viol_sinan_violencias_orientacao_sexual` | — |
| % de notificações por origem da agressão × identidade de gênero | Violencias_Identidade_Genero | `lgbt_viol_sinan_violencias_identidade_genero` | — |
| Perfil das vítimas (interpessoal): sexo / faixa etária / raça-cor | Interpessoal_Sexo_SINAN · Interpessoal_Faixa_Etária_SINAN · Interpessoal_Cor_ou_Raça | `lgbt_viol_sinan_interpessoal_sexo_sinan` · `..._interpessoal_faixa_etaria_sinan` · `..._interpessoal_cor_ou_raca` | — |
| Perfil das vítimas (autoprovocada): sexo / faixa etária / raça-cor | Autoprovocada_Sexo_SINAN · Autoprovocada_Faixa_Etária · Autoprovocada_Cor_ou_Raça | `lgbt_viol_sinan_autoprovocada_sexo_sinan` · `..._autoprovocada_faixa_etaria` · `..._autoprovocada_cor_ou_raca` | — |
| 10 maiores % de tipo de agressor (interpessoal) | Interpessoal_Perfil_Agressor | `lgbt_viol_sinan_interpessoal_perfil_agressor` | — |
| *(aba ingerida, sem indicador citado)* tipos de violência interpessoal | Interpessoal-Tipos de violência | `lgbt_viol_sinan_interpessoal_tipos_de_violencia` | — |

**7.1. Denúncias de violações de direitos humanos (ONDH)** — `N E M`:

| Indicador (resumo) | Aba Excel | Tabela `raw` | Modelo dbt |
|---|---|---|---|
| Total de denúncias 2020–2024 (soma `qtd_denuncias_2020..2024`) | ONDH_Serie_Historica_2020_2024 | `lgbt_viol_ondh_ondh_serie_historica_2020_2024` | — |
| Nº absoluto de denúncias e de violações, por ano | ONDH_Serie_Historica_2020_2024 | idem | — |
| % de estados por maior nº de denúncias em 2024 | ONDH_Serie_Historica_2020_2024 | idem | — |
| % de denúncias por sexo X | ONDH_Sexo | `lgbt_viol_ondh_ondh_sexo` | — |
| % de denúncias por faixa etária X (junta "até 29" e "idosos") | ONDH_Faixa_Etária | `lgbt_viol_ondh_ondh_faixa_etaria` | — |
| % de denúncias por raça/cor (junta pretas + pardas = negras) | ONDH_Raca_Cor | `lgbt_viol_ondh_ondh_raca_cor` | — |
| % de local de ocorrência das violações | ONDH_Local | `lgbt_viol_ondh_ondh_local` | — |
| 10 maiores % por tipo de relação do suspeito | ONDH_Relação_Suspeito | `lgbt_viol_ondh_ondh_relacao_suspeito` | — |
| % por tipo de violação X | ONDH_Tipo_de_Violação | `lgbt_viol_ondh_ondh_tipo_de_violacao` | — |
| % por tipo de identidade de gênero X | ONDH_Identidade_Genero | `lgbt_viol_ondh_ondh_identidade_genero` | — |
| % por tipo de orientação sexual X | ONDH_Orientacao_Sexual | `lgbt_viol_ondh_ondh_orientacao_sexual` | — |

---

## 3. Situação atual

- ✅ **6.1 Proteção social especial** — modelada nos 3 níveis (piloto). **Formato largo** (`lgbtqia_plus_relatorio_nacional/_estadual/_municipal`, uma coluna por indicador). A migrar para o formato longo.
- ✅ **5.1 Serviços de saúde para pessoas trans** — modelada (N e E) no **formato longo**.
- ⬜ Demais seções — dado bruto **já está no schema `raw`** (54 tabelas), falta modelar.

### Formato longo — `lgbtqia_plus_indicadores`

Mart único, uma linha por `(nivel, recorte_codigo, secao, indicador, categoria)`:

| coluna | conteúdo |
|---|---|
| `nivel` | `nacional` / `estadual` / `municipal` |
| `recorte_codigo` / `recorte_nome` | `null`/`Brasil` · `codigo_uf`/nome · `cod_ibge`/nome |
| `secao` / `secao_nome` | ex. `5.1` / `Saúde — Serviços de saúde para pessoas trans` |
| `indicador` | slug estável (ex. `estabelecimentos_total`) |
| `categoria` | quebra dentro do indicador (`null` se não houver) |
| `valor` / `valor_tipo` | numérico · `numero_absoluto` / `percentual` / `variacao_pp` |
| `ano_referencia` | |

Views de conveniência: `lgbtqia_plus_indicadores_{nacional,estadual,municipal}`.
Cada (sub)seção é um `int_lgbtqia_plus_<secao>_*` que já devolve nesse formato; o mart só faz `union all`.

## 4. Observações e inconsistências

- **"Sinalização CGTI"** = indicador que fica no relatório como texto fixo, **sem cálculo nem base de dados** (2.6 População Trans; 3.1 Pessoas Trans; "O Censo Trans" em 4). Não vira modelo dbt.
- **Renumeração 2.5 ↔ 2.1**: nos docs Estadual/Municipal a subseção "Casamentos e uniões" aparece como "2.1" no corpo, mas "2.5" no índice. É a mesma subseção.
- **"7. Violência contra pessoas idosas"**: título no índice/corpo dos docs Estadual e Municipal — resíduo de copiar do relatório de Pessoa Idosa. O conteúdo é de LGBTQIA+.
- **Aba "ONDH - Identidade de gênero" dentro do arquivo SINAN**: duplica parte do arquivo ONDH separado. Ingerida como `lgbt_viol_sinan_ondh_identidade_de_genero`. Confirmar com a equipe se é intencional.
- **Nomes de aba divergentes entre "V2" e o citado nos docs**: ex. doc diz "Unidade de Acolhimento 2024" (singular) e "Unidades de Acolhimento 2024" (plural) na mesma página; "Conjuges" vs "Cônjuges". Usar sempre o nome real da aba no arquivo `.xlsx`.
- **Ano de referência**: alguns docs dizem "2024" onde a planilha traz série histórica (PAEFI 2017–2024). O piloto 6.1 usa o ano mais recente por município e deixou TODO para a equipe confirmar se o relatório quer o valor pontual ou a série.
- As 11 inconsistências mencionadas no README vêm deste conjunto de observações + do catálogo original da equipe.
