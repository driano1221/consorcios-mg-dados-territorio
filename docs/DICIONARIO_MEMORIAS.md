# Dicionario De Memorias - ideiaMides

Atualizado em: 2026-07-28

Este arquivo serve como indice rapido dos documentos de memoria e contexto do projeto.

## Arquivos Centrais

| Arquivo | Uso |
|---|---|
| `docs/MEMORIA_ideiaMides.md` | Estado consolidado do projeto, decisoes metodologicas, entregas e proximos passos. Comecar por aqui. |
| `docs/PROXIMOS_PASSOS.md` | Roteiro atual de proximas entregas, decisoes pendentes, itens pausados e frentes territoriais viaveis. |
| `docs/ATAS_REUNIOES.md` | Registro de reunioes e encaminhamentos discutidos com a equipe. |
| `docs/LINHA_DO_TEMPO.md` | Linha do tempo historica das etapas do projeto. |
| `docs/2026-05-14-HANDOFF.md` | Handoff historico do ciclo de maio; util para entender a origem do painel universal e da apresentacao. |
| `docs/METODOLOGIA_CLASSIFICACAO_ATUAL.md` | Leitura curta e atual da classificacao v0.5: taxonomia, fontes, inferencias, multifinalitarios, matriz/filial e limites. |
| `docs/ESTRUTURA_REPOSITORIO.md` | Mapa do repositorio Git, regras de versionamento e papeis das pastas. |

## Base 1 2015/2019

| Arquivo/Pasta | Uso |
|---|---|
| `analises/base_1_2015_2019/METODOLOGIA.md` | Metodologia da Base 1: MIDES, MUNIC e SICONFI. |
| `analises/base_1_2015_2019/outputs/` | Outputs da Base 1 e validacao SICONFI reconstruida. |
| `dashboards/base1_shiny/` | App Shiny publicado para consulta da Base 1 e MIDES completo. |

## Classificacao De Politicas Publicas

| Arquivo/Pasta | Uso |
|---|---|
| `analises/classificacao_politicas/README.md` | Indice da taxonomia, fontes, regras e versoes da classificacao setorial. |
| `analises/classificacao_politicas/01_classificar_areas_politica.R` | Rotina reprocessavel que classifica os 223 CNPJs MG sem alterar as bases originais. |
| `analises/classificacao_politicas/inputs/revisao_documental_39_cnpjs_v0_2.csv` | Decisao, justificativa, confianca e fontes da revisao individual dos 39 alertas iniciais. |
| `analises/classificacao_politicas/AUDITORIA_DOCUMENTAL_39.md` | Leitura curta da auditoria: 29 casos resolvidos e 10 pendencias mantidas sem inferencia forte. |
| `analises/classificacao_politicas/REVISAO_COMPLEMENTAR_V0_3.md` | Complemento da v0.3: quatro casos MUNIC prioritarios resolvidos, quatro pendencias v0.2 encaminhadas e seis pendencias restantes. |
| `analises/classificacao_politicas/02_auditar_consolidacao_munic.R` | Rotina reprocessavel que verifica se os setores MUNIC podem ser unidos por CNPJ; nao altera a classificacao v0.2. |
| `analises/classificacao_politicas/04_gerar_amostra_validacao_munic.R` | Gera, com semente fixa, a amostra humana de 19 CNPJs para validar a regra MUNIC. |
| `analises/classificacao_politicas/05_preparar_caderno_decisao_classificacao.R` + `05_gerar_caderno_decisao_classificacao.mjs` | Pipeline reprocessavel que prepara os casos nao confirmados e gera o caderno Excel de decisao. |
| `analises/classificacao_politicas/06_consolidar_classificacao_v0_4.R` | Aplica as decisoes de 28/07 sobre cadastro, nome, inativos, matriz-filial e multifinalitarios sem alterar v0.3. |
| `analises/classificacao_politicas/07_consolidar_classificacao_v0_5.R` | Registra a decisao posterior de validar os 94 casos `provisoria_coerente` para uso analitico, preservando a trilha v0.4. |
| `analises/classificacao_politicas/AUDITORIA_CONSOLIDACAO_MUNIC.md` | Leitura metodologica da auditoria MUNIC e da regra segura para uso dos setores. |
| `analises/classificacao_politicas/METODOLOGIA_CLASSIFICACAO_V0_3.md` | Leitura recomendada: explica os tres campos analiticos, a precedencia de fontes e os limites da v0.3. |
| `analises/classificacao_politicas/03_consolidar_classificacao_v0_3.R` | Rotina que gera a camada analitica v0.3 sem sobrescrever v0.2. |
| `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_2.csv` | Classificacao completa final, preservando campos automaticos e adicionando campos apos revisao documental. |
| `analises/classificacao_politicas/outputs/revisao_classificacao_areas_politica_mg_v0_2.xlsx` | Planilha das 10 pendencias que ainda exigem estatuto, protocolo ou fonte institucional. |
| `analises/classificacao_politicas/outputs/auditoria_consolidacao_setores_munic_v0_1.xlsx` | Auditoria consultavel por CNPJ, com suporte por setor, ano e municipio, recomendacao metodologica e casos prioritarios. |
| `analises/classificacao_politicas/outputs/amostra_validacao_regra_MUNIC_v0_1.xlsx` | Amostra de 19 CNPJs: quatro prioritarios, cinco de setor unico, cinco multiarea coerentes e cinco heterogeneos; inclui aba de evidencia MUNIC e campos de parecer. |
| `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_3_analitica.xlsx` | Planilha curta para uso analitico: area final, fonte principal e status de validacao. |
| `analises/classificacao_politicas/outputs/caderno_decisao_v0_3/caderno_decisao_classificacao_v0_3.xlsx` | Caderno de leitura e decisao dos 188 casos sem confirmacao plena: 94 coerentes, 15 por cadastro, 48 por nome, 23 multifinalitarios, 6 sem area e 2 filiais sem classificacao tematica. A auditoria do dashboard tem universo maior de raizes matriz/filial. |
| `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_4_analitica_ativa.csv/.rds` | Camada ativa atual: 217 CNPJs; exclui somente seis inativos e incorpora as decisoes humanas de 28/07. |
| `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_analitica_ativa.csv/.rds` | Camada analitica ativa vigente: 217 CNPJs; incorpora tambem a validacao dos 94 casos coerentes. |

## Dashboard Shiny

| Arquivo | Uso |
|---|---|
| `dashboards/base1_shiny/app.R` | Codigo principal do dashboard. |
| `dashboards/base1_shiny/data/base_1_vinculos_2015_2019.csv` | Base 1 usada pelo app. |
| `dashboards/base1_shiny/data/base_1_vinculos_2015_2019.rds` | Versao RDS otimizada da Base 1 usada no app publicado. |
| `dashboards/base1_shiny/data/base_1_validacao_siconfi_reconstruido_2015_2019.csv` | Validacao SICONFI usada pelo app. |
| `dashboards/base1_shiny/data/base_1_validacao_siconfi_reconstruido_2015_2019.rds` | Versao RDS otimizada da validacao SICONFI usada no app publicado. |
| `dashboards/base1_shiny/data/painel_mg_anual.rds` | MIDES completo 2014-2021 usado na aba MIDES completo. |
| `dashboards/base1_shiny/data/cadastro_base.rds` | Cadastro de consorcios usado para enriquecer nomes, siglas e metadados. |
| `dashboards/base1_shiny/data/mides_municipios_lookup.csv` | Lookup de nomes municipais usado no MIDES completo. |
| `dashboards/base1_shiny/data/mides_municipios_lookup.rds` | Versao RDS otimizada do lookup municipal usada no app publicado. |
| `dashboards/base1_shiny/data/mg_municipios_sf_web.rds` | Geometria municipal simplificada para os mapas dinamicos do app. |
| `dashboards/base1_shiny/data/mg_contorno_sf_web.rds` | Contorno estadual de MG usado por cima dos mapas. |
| `dashboards/base1_shiny/deploy_app.R` | Script recomendado de deploy; usa `appFiles` explicito para nao empacotar arquivos desnecessarios. |

Link publicado:

`https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/`

Status em 2026-07-08:

- App publicado e funcional.
- Base 1 e MIDES completo estao no mesmo app, mas em abas separadas.
- Mapas dinamicos implementados com `ggiraph` nas abas MIDES completo, Recorte 2015/2019 e 2015 vs 2019.
- Aba `MIDES completo` agora tem a subaba `Entradas/saidas`, com pequenos multiplos 2014-2021 para movimento anual dos pares municipio-consorcio.
- Nessa subaba, 2014 e tratado como base inicial; de 2015 em diante cada ano e comparado contra o ano anterior.
- A tabela de detalhe da subaba `Entradas/saidas` aparece somente com 1 a 4 consorcios selecionados e usa `+` para abrir municipios que entraram ou sairam.
- Mapas acompanham automaticamente filtros de municipio, consorcio e busca livre; nao ha mais botao manual de atualizacao.
- Cache fica apenas nos reativos de dados, nao nos outputs `renderGirafe()`, para evitar mapa antigo apos filtro novo.
- Camada visual dos mapas usa `geom_sf()` vetorial direto; a camada transparente `geom_sf_interactive()` preserva tooltip/hover.
- Aba `2015 vs 2019` separa mapa e tabela em subabas.
- Aba `Auditoria` agora tem a subaba `Raiz CNPJ`, que identifica matriz/filiais pela raiz de 8 digitos do CNPJ usando o cadastro completo.
- Em 2026-07-08, a auditoria por raiz encontrou 23 raizes com multiplos CNPJs no cadastro; 12 aparecem na Base 1.
- Otimizacao aplicada: selects server-side, tabelas DT sem CDN, dados RDS e bundle reduzido via `deploy_app.R`.
- `deploy_app.R` monta bundle temporario ASCII para contornar problemas do `rsconnect` com o caminho local acentuado.

## Pesquisas E Frentes Futuras

| Arquivo | Uso |
|---|---|
| `docs/2026-06-10-pesquisa-recortes-territoriais.md` | Pesquisa sobre regioes de saude, bacias hidrograficas, associacoes microrregionais e votos de deputados. |
| `docs/PROXIMOS_PASSOS.md` | Sintese operacional da pesquisa territorial, com prioridades e itens que nao devem ser implementados ainda. |
| `docs/2026-05-14-boas-praticas-slides-dataviz.md` | Referencias historicas de visualizacao e slides. |

## Apresentacoes E Mapas

| Arquivo/Pasta | Uso |
|---|---|
| `slides/` | Apresentacoes HTML e assets usados nas reunioes. |
| `slides/scripts_viz.R` | Script que gerou graficos e o mapa CODAP com `geobr`, `sf`, `ggplot2` e `patchwork`. |
| `slides/assets/codap_map.png` | Mapa estatico CODAP usado como exemplo visual. |
| `outputs/mapas/` | HTML/PDF/RDS com mapas de consorcios MG gerados anteriormente. |

## Regras De Leitura

- SICONFI nao identifica CNPJ de destino; usar como validacao financeira municipio-ano.
- MIDES completo 2014-2021 deve ser tratado como consulta separada da Base 1.
- Base 1 e o recorte comparavel de 2015/2019 entre MIDES e MUNIC, com SICONFI como validacao.
- CNM nao entra na Base 1.
- Mapas ja estao implementados no dashboard e devem ser testados sempre que houver mudanca de filtros/cache.
- Para matriz/filial, usar a raiz de 8 digitos do CNPJ como regra de auditoria. A consolidacao de valores por matriz ainda nao foi aplicada.
- A classificacao setorial vigente e a v0.5. Filiais herdam apenas tipo e area; valores e movimentos seguem sem consolidacao por raiz.
- Para entradas/saidas no MIDES completo, a unidade e o par municipio-consorcio-ano; a leitura nao usa MUNIC nem SICONFI.
