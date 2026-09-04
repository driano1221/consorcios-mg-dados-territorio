# Dicionario Tecnico - Modelo Gravitacional De Saude

Este documento e o inventario oficial da pasta. Ele responde quatro perguntas:

1. qual arquivo executa cada passo;
2. quais dados entram e de onde vieram;
3. qual produto deve ser aberto;
4. qual teste comprova que o passo fechou corretamente.

O `README.md` continua sendo a porta de entrada. A evolucao substantiva dos
passos esta em `LINHA_DO_TEMPO_PASSOS.md`.

## Numeracao

Ha sete passos cientificos e nove scripts. O passo 2 usa dois scripts porque a
comparacao quantitativa e a revisao documental sao operacoes diferentes.

| Passo cientifico | Script tecnico | Conteudo |
|---:|---|---|
| 1 | `01` | universo de saude e identidade matriz/filial |
| 2 | `02` e `03` | cotejamento MIDES-MUNIC e revisao documental |
| 3 | `04` | polo ou rede assistencial diretamente vinculada |
| 4 | `05` | capacidade assistencial atual no CNES |
| 5 | `06` | tempo rodoviario ate a oferta fixa |
| 6 | `07` | painel municipio-entidade-ano e eventos |

## Mapa Da Pasta

| Local | O que contem | Regra de uso |
|---|---|---|
| `README.md` | estado atual e ordem de leitura | abrir primeiro |
| `DICIONARIO_TECNICO.md` | arquivos, fontes, extracoes e produtos | consultar para localizar ou reproduzir |
| `LINHA_DO_TEMPO_PASSOS.md` | evolucao dos passos e exemplo real | consultar para explicar o projeto |
| `METODOLOGIA_GERAL.md` | metodologia unica dos passos 1 a 7 e da auditoria complementar | consultar para defender decisoes |
| `01...08...R` | scripts reprocessaveis | executar na ordem numerica |
| `tests/` | testes de chaves, contagens e invariantes | executar depois do respectivo script |
| `checks/` | resultados quantitativos validados | consultar numeros sem abrir bases |
| `evidencias/` | fontes da revisao humana | auditar decisoes documentais do passo 2 |
| `outputs/` | dados derivados, snapshots e caches | uso analitico local; nao versionado no Git |

## Scripts, Entradas E Saidas

### Passo 1 - Universo De Saude

| Arquivo | Funcao |
|---|---|
| `01_fechar_universo_saude_mg.R` | seleciona areas de saude, consolida matriz/filiais e liga o universo ao MIDES |
| `tests/01_validar_universo_saude_mg.R` | valida 100 CNPJs, 84 entidades, identidade e conservacao financeira |
| `checks/VALIDACAO_UNIVERSO_SAUDE_MG.md` | registra contagens, alertas e amostras |

Entradas:

| Arquivo local | Papel |
|---|---|
| `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_completa.csv` | informa area, macrogrupo, perfil e validacao |
| `analises/base_nacional/outputs/crosswalk_cnpj_matriz_filial_nacional.rds` | fornece raiz, matriz canonica e filiais |
| `dados/processado/painel_mg_anual.rds` | informa pagamentos MIDES anuais de 2014 a 2021 |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `universo_saude_mg_estabelecimentos.rds` | CNPJ original | auditar matriz e filial sem perder identidade |
| `universo_saude_mg_entidades.rds` | raiz de oito digitos | universo canonico das 84 entidades |
| `casos_revisao_universo_saude_mg.csv` | entidade com alerta | revisao humana de escopo ou situacao |
| `resumo_universo_saude_mg.csv` | indicador | consulta rapida das contagens |

### Passo 2 - Vinculos E Evidencias

| Arquivo | Funcao |
|---|---|
| `02_cotejar_mides_munic_saude_2019.R` | compara pagamento MIDES e declaracao MUNIC em 2019 |
| `03_revisar_divergencias_documentais_2019.R` | qualifica documentalmente os 50 casos priorizados |
| `tests/02_validar_cotejamento_mides_munic_saude_2019.R` | valida uniao, grupos e valores |
| `tests/03_validar_revisao_documental_2019.R` | valida cobertura do catalogo e regras temporais |
| `checks/VALIDACAO_COTEJAMENTO_MIDES_MUNIC_SAUDE_2019.md` | resultados do cotejamento |
| `checks/VALIDACAO_DOCUMENTAL_DIVERGENCIAS_2019.md` | resultados da revisao humana |

Entradas adicionais:

| Arquivo local | Papel |
|---|---|
| `dashboards/base1_shiny/data/base_1_vinculos_2015_2019.rds` | preserva MIDES e MUNIC separadamente em 2019 |
| `dashboards/base1_shiny/data/cadastro_base.rds` | nomes e contexto cadastral |
| `evidencias/catalogo_revisao_documental_2019.csv` | URL, ano, alcance e interpretacao de cada evidencia |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `cotejamento_mides_munic_saude_mg_2019.rds` | municipio x entidade | distinguir `MIDES+MUNIC`, somente fonte e divergencia |
| `resumo_entidades_mides_munic_saude_mg_2019.rds` | entidade | cobertura por consorcio |
| `divergencias_mides_munic_saude_mg_2019.csv` | par divergente | auditoria completa |
| `amostra_revisao_mides_munic_saude_mg_2019.csv` | par priorizado | 23 somente MUNIC e 27 maiores somente MIDES |
| `revisao_documental_divergencias_saude_mg_2019.csv` | par priorizado | decisao estrita, ampliada ou nao confirmada |

### Passo 3 - Polo Ou Rede Assistencial

| Arquivo | Funcao |
|---|---|
| `04_definir_polos_atracao_saude.R` | consulta CNPJ mantenedor e CNPJ proprio no CNES e separa sede, polo unico, rede, movel ou sem unidade |
| `tests/04_validar_polos_atracao_saude.R` | valida 84 entidades e 670 unidades |
| `checks/VALIDACAO_POLOS_ATRACAO_SAUDE_MG.md` | registra cobertura e decisoes territoriais |
| `METODOLOGIA_GERAL.md` | explica a regra de polo/rede no passo 3 |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `consultas_cnes_polo_saude_mg.csv` | CNPJ consultado | auditoria da consulta por matriz e filial |
| `consultas_cnes_cnpj_proprio_saude_mg.csv` | CNPJ consultado | auditoria da busca complementar pelo CNPJ proprio do estabelecimento |
| `unidades_cnes_vinculadas_saude_mg.csv` | unidade CNES | lista de estabelecimentos mantidos pelo CNPJ |
| `polos_atracao_saude_mg.rds` | entidade | decisao de polo, rede ou ausencia de unidade direta |
| arquivos com sufixo `2026_09_03` | snapshot datado | preservar a fotografia usada na analise |

### Passo 4 - Capacidade Assistencial

| Arquivo | Funcao |
|---|---|
| `05_construir_capacidade_assistencial_saude.R` | consulta ficha, leitos, atendimento e profissionais das unidades CNES |
| `tests/05_validar_capacidade_assistencial_saude.R` | valida cobertura, tipos, zeros e ausencias |
| `checks/VALIDACAO_CAPACIDADE_ASSISTENCIAL_SAUDE_MG.md` | registra EDA e exemplos auditados |
| `METODOLOGIA_GERAL.md` | explica capacidade e por que leitos nao sao massa unica no passo 4 |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `capacidade_unidades_cnes_saude_mg.csv` | unidade fixa ou movel | camada primaria da oferta direta |
| `capacidade_entidades_saude_mg.rds` | entidade | agregacao das unidades fixas diretamente vinculadas |
| `cache_cnes_capacidade/` | unidade CNES | evitar nova consulta integral e recuperar falhas seletivamente |
| arquivos com sufixo `2026_09_03` | snapshot datado | preservar a coleta utilizada |

### Passo 5 - Tempo Rodoviario

| Arquivo | Funcao |
|---|---|
| `06_integrar_tempo_rodoviario_saude.R` | liga os 853 municipios as unidades fixas por OSRM/OpenStreetMap |
| `tests/06_validar_tempo_rodoviario_saude.R` | valida cobertura, diagonal, simetria e ausencia de rotas faltantes |
| `checks/VALIDACAO_TEMPO_RODOVIARIO_SAUDE_MG.md` | registra EDA, velocidades implicitas e limites |
| `METODOLOGIA_GERAL.md` | explica origem, agregacao e interpretacao do tempo no passo 5 |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `tempo_rodoviario_municipio_destino_saude_mg.rds` | municipio x municipio de oferta | grade territorial basica |
| `tempo_rodoviario_municipio_unidade_saude_mg.rds` | municipio x unidade fixa | camada primaria de impedancia |
| `tempo_rodoviario_municipio_entidade_saude_mg.rds` | municipio x entidade | minimo, mediana e maximo para EDA/sensibilidade |

### Passo 6 - Painel Analitico

| Arquivo | Funcao |
|---|---|
| `07_montar_painel_analitico_saude.R` | consolida pagamentos e cria a grade municipio-entidade-ano |
| `tests/07_validar_painel_analitico_saude.R` | valida 573.216 chaves, eventos e valor conservado |
| `checks/VALIDACAO_PAINEL_ANALITICO_SAUDE_MG.md` | registra eventos e universos preliminares |
| `METODOLOGIA_GERAL.md` | explica censura, eventos e limites do painel no passo 6 |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `painel_analitico_saude_mg.rds` | municipio x entidade x ano | fonte analitica completa, inclusive zeros |
| `mides_saude_mg_consolidado_entidade_ano.rds` | observacao MIDES consolidada | auditar matriz/filiais e valores |
| `painel_analitico_saude_mg_eventos.csv` | linha com presenca ou transicao | inspecao dos eventos |
| `painel_analitico_saude_mg_resumo_par.rds` | municipio x entidade | trajetoria e recorrencia |
| `painel_analitico_saude_mg_resumo_ano.csv` | ano | resumo temporal |
| `painel_analitico_saude_mg_resumo_entidade.csv` | entidade | resumo institucional |
| `DICIONARIO_PAINEL_ANALITICO_SAUDE_MG.csv` | variavel | definicoes das colunas centrais do painel |

### Complemento - Cobertura Assistencial

| Arquivo | Funcao |
|---|---|
| `08_completar_cobertura_assistencial_saude.R` | consolida cobertura direta, indireta, movel, historica ou insuficiente |
| `tests/08_validar_cobertura_assistencial_saude.R` | valida 84 entidades, os 38 casos originais e os 7 alertas |
| `checks/VALIDACAO_COBERTURA_ASSISTENCIAL_COMPLEMENTAR_SAUDE_MG.md` | registra antes/depois, contagens e casos sentinela |
| `evidencias/catalogo_cobertura_assistencial_indireta.csv` | preserva fonte e decisao das redes sem polo fixo unico |
| `evidencias/decisoes_alertas_universo_saude.csv` | registra a resolucao operacional dos sete alertas |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `cobertura_assistencial_entidades_saude_mg.rds` | entidade | sintese final da cobertura e uso permitido no modelo |
| `auditoria_38_casos_cobertura_assistencial_saude_mg.csv` | entidade originalmente pendente | comparar classificacao antes/depois |
| `auditoria_alertas_universo_saude_mg.csv` | alerta | consultar decisao de escopo, situacao ou macrogrupo |
| `baseline_capacidade_entidades_saude_mg_antes_cnpj_proprio_2026_09_03.csv` | entidade | preservar o retrato anterior a correcao da busca CNES |

### Passo 7 - CNES Historico

| Arquivo | Funcao |
|---|---|
| `09_temporalizar_cnes_historico_saude.py` | baixa, converte, filtra e agrega os arquivos historicos CNES |
| `requirements_cnes_historico.txt` | declara `dbc-reader` e `dbfread`; no Windows o conversor usa WSL |
| `tests/09_validar_cnes_historico_saude.py` | valida chaves, meses, fontes, leitos, territorio e privacidade |
| `checks/VALIDACAO_CNES_HISTORICO_SAUDE_MG.md` | registra resultados, EDA, exemplos e limites |

Produtos principais:

| Produto | Unidade | Uso |
|---|---|---|
| `cnes_historico_unidades_saude_mg_2014_2021.csv` | entidade x ano x CNES em dezembro | capacidade anual diretamente vinculada |
| `cnes_historico_entidades_saude_mg_2014_2021.csv` | entidade x ano | 672 linhas prontas para ligar ao painel |
| `cnes_historico_presenca_mensal_saude_mg_2014_2021.csv` | entidade x ano x CNES | sensibilidade de presenca em qualquer mes |
| `resumo_cnes_historico_saude_mg.csv` | ano | cobertura e capacidade agregadas para EDA |
| `manifesto_cnes_historico_saude_mg.csv` | arquivo-fonte | URL, competencia, tamanho e SHA-256 de 120 DBCs |
| `cache_cnes_historico/` | arquivo DBC bruto | cache local reprocessavel; ignorado pelo Git |

Ligacoes e medidas:

| Tabela oficial | Chave | Campos usados |
|---|---|---|
| `ST` | CNPJ proprio/mantenedor -> CNES | municipio, tipo, SUS, competencia e presenca |
| `LT` | CNES | leitos existentes, SUS e tipo de leito |
| `SR` | CNES | servico, classificacao e atendimento SUS |
| `PF` | CNES | profissional distinto, CBO, SUS e carga horaria; identificadores nao sao gravados |

## Fontes E Proveniencia

| Fonte | Origem ou link | Arquivo local utilizado | Periodo/data | Passos | Leitura correta |
|---|---|---|---|---:|---|
| Cadastro/classificacao IPEA v0.5 | pipeline interno versionado | `classificacao_areas_politica_mg_v0_5_completa.csv` | versao vigente em 03/09/2026 | 1 | identifica area e perfil; nao prova vinculo municipal |
| Identidade matriz/filial | pipeline nacional interno | `crosswalk_cnpj_matriz_filial_nacional.rds` | fotografia cadastral anterior ao recorte de saude | 1 | raiz comum define entidade analitica, preservando CNPJs originais |
| MIDES | [Base dos Dados](https://basedosdados.org/dataset/d3874769-bcbd-4ece-a38a-157ba1021514?table=14c5d05b-9830-4710-b7ac-7e0ca1bf9d8b), tabela `world_wb_mides.pagamento` | `dados/processado/painel_mg_anual.rds` | 2014-2021; data da extracao nao e registrada nesta trilha | 1, 2 e 6 | pagamento observado, nao filiacao juridica |
| MUNIC/IBGE | [Pesquisa MUNIC](https://www.ibge.gov.br/estatisticas/sociais/saude/10586-pesquisa-de-informacoes-basicas-municipais.html) | `base_1_vinculos_2015_2019.rds` | recorte de 2019 no passo 2 | 2 | declaracao pontual, nao painel anual |
| Cadastro auxiliar | pipeline do dashboard | `cadastro_base.rds` | fotografia processada vigente | 2 | nomes e contexto, nao evidencia temporal isolada |
| Evidencias documentais | URLs por linha em `evidencias/catalogo_revisao_documental_2019.csv` | catalogo CSV versionado | documentos de anos distintos | 2 | fonte posterior nao retroage automaticamente para 2019 |
| CNES/DATASUS | [portal atual](https://cnes.datasus.gov.br/) e [portal legado](https://cnes2.datasus.gov.br/) | snapshots e cache em `outputs/` | coletado em 03/09/2026 | 3, 4 e complemento | fotografia atual por CNPJ proprio e mantenedor |
| CNES/DATASUS historico | `ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/` | `cache_cnes_historico/` e manifesto local | 2014-2021 | 7 | `ST` mensal; `LT`, `SR` e `PF` de dezembro |
| Distbrasil | [pagina metodologica](https://rfsaldanha.github.io/data-projects/brazil_road_distances.html), [Zenodo 11400243](https://zenodo.org/records/11400243), [codigo](https://github.com/rfsaldanha/distbrasil) | `dados/bruto/externo/distbrasil/dist_brasil_zenodo_11400243.rds` | publicado em 31/05/2024; integrado em 03/09/2026 | 5 | rota estatica e simetrica entre sedes municipais |
| Malha municipal MG | produto cartografico local do dashboard | `dashboards/base1_shiny/data/mg_municipios_sf_web.rds` | referencia municipal usada no projeto | 5 | nomes/codigos e geometria; nao produz o tempo rodoviario |

### Endpoints CNES Consultados

| Endpoint relativo | Conteudo aproveitado |
|---|---|
| `Listar_Mantidas.asp?VCnpj=...&VEstado=31` | unidades diretamente registradas sob matriz ou filial |
| `/services/estabelecimentos?cnpj=...&estado=31` | estabelecimentos cujo CNPJ proprio coincide com o consorcio |
| `Exibe_Ficha_Estabelecimento.asp?VCo_Unidade=...` | municipio, codigo IBGE, tipo e dependencia |
| `Mod_Hospitalar.asp?VCo_Unidade=...` | leitos existentes e SUS |
| `Mod_Bas_Atendimento.asp?VCo_Unidade=...` | ambulatorio, internacao e SADT SUS |
| `Mod_Profissional.asp?VCo_Unidade=...` | contagens de vinculos e CBOs SUS ativos |

Nomes e CNS de profissionais nao sao retidos. Apenas contagens agregadas ficam
nos produtos.

## O Que Nao Entrou

- A CNM nao altera os passos 1 a 7: ela e fotografia cadastral atual e ainda
  nao foi materializada como composicao historica da tabela de saude.
- SICONFI nao identifica o CNPJ destinatario e nao entra como vinculo do par.
- Populacao, RCL, regiao de saude, bacia e mandato aguardam fontes anuais
  validadas.
- Vinte e tres entidades continuam sem estrutura fixa CNES direta. Redes
  moveis/contratadas permanecem com tempo `NA` ate existirem prestadores ou
  bases documentados; nenhum destino foi inventado.

## Ordem De Reproducao

Na raiz do repositorio, execute cada script e seu teste antes de seguir:

```powershell
Rscript analises/modelo_gravitacional_saude/01_fechar_universo_saude_mg.R
Rscript analises/modelo_gravitacional_saude/tests/01_validar_universo_saude_mg.R
Rscript analises/modelo_gravitacional_saude/02_cotejar_mides_munic_saude_2019.R
Rscript analises/modelo_gravitacional_saude/tests/02_validar_cotejamento_mides_munic_saude_2019.R
Rscript analises/modelo_gravitacional_saude/03_revisar_divergencias_documentais_2019.R
Rscript analises/modelo_gravitacional_saude/tests/03_validar_revisao_documental_2019.R
Rscript analises/modelo_gravitacional_saude/04_definir_polos_atracao_saude.R
Rscript analises/modelo_gravitacional_saude/tests/04_validar_polos_atracao_saude.R
Rscript analises/modelo_gravitacional_saude/05_construir_capacidade_assistencial_saude.R
Rscript analises/modelo_gravitacional_saude/tests/05_validar_capacidade_assistencial_saude.R
Rscript analises/modelo_gravitacional_saude/06_integrar_tempo_rodoviario_saude.R
Rscript analises/modelo_gravitacional_saude/tests/06_validar_tempo_rodoviario_saude.R
Rscript analises/modelo_gravitacional_saude/07_montar_painel_analitico_saude.R
Rscript analises/modelo_gravitacional_saude/tests/07_validar_painel_analitico_saude.R
Rscript analises/modelo_gravitacional_saude/08_completar_cobertura_assistencial_saude.R
Rscript analises/modelo_gravitacional_saude/tests/08_validar_cobertura_assistencial_saude.R
python -m pip install -r analises/modelo_gravitacional_saude/requirements_cnes_historico.txt
python analises/modelo_gravitacional_saude/09_temporalizar_cnes_historico_saude.py
python analises/modelo_gravitacional_saude/tests/09_validar_cnes_historico_saude.py
```

Os produtos pesados em `outputs/` sao derivados e ignorados pelo Git. Codigo,
testes, checks, metodologias e evidencias pequenas sao versionados.
