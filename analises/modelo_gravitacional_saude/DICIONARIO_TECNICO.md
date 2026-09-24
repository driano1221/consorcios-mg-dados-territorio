# Dicionario Tecnico - Modelo Gravitacional De Saude

> Entrega vigente: `outputs/base_v1/`, fechada em 24/09/2026. A secao final
> "Entrega V1" localiza as duas bases, o dicionario de colunas e a reproducao.
> As secoes datadas anteriores documentam as fontes e camadas preservadas.

## Atualizacao De 16/09/2026

O script `11_diagnosticar_universo_e_elegibilidade_saude.R` fecha a camada
funcional do passo 3 reutilizando as saidas anteriores. Rodar na raiz do repo,
apos 10, seguido de `tests/11_validar_diagnostico_universo_e_elegibilidade_saude.R`.

| Arquivo | Conteudo e uso |
|---|---|
| `evidencias/auditoria_documental_21_entidades_2026_09_16.csv` | 21 entidades nao prioritarias: fonte consultada, anos, decisao e limite; rodada delimitada, nao busca exaustiva |
| `evidencias/auditoria_multiarea_2026_09_16.csv` | CISREC, CONVALES, CIMBAJE e alerta estatutario CISPARA; conservar alcance temporal de cada fonte |
| `evidencias/decisoes_fichas_cnes_conflitantes_2026_09_16.csv` | Duas decisoes atuais consumidas pelo script: 5563003 movel; 3987981 clinica |
| `outputs/elegibilidade_assistencial_unidades_atuais_saude_mg.csv` | 670 unidades: 63 clinicas fixas, 20 nao clinicas e 587 moveis |
| `outputs/elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv` | 1.868 unidades-ano: 398 clinicas fixas, 74 nao clinicas e 1.396 moveis |
| `outputs/elegibilidade_assistencial_entidade_ano_saude_mg_2014_2021.csv` | 672 entidades-ano com contagens funcionais; elegibilidade cadastral, nao amostra final |
| `outputs/auditoria_18_entidades_sem_mides_saude_mg.csv` | 15 inativas/inaptas atuais, 2 abertas apos 2021 e 1 ativa sem evidencia |
| `outputs/comparacao_entidades_com_sem_mides_saude_mg.csv` | Comparacao descritiva dos grupos 66 e 18 |
| `outputs/auditoria_multiarea_saude_mg.csv` | Catalogo documental ligado a cobertura CNES, sem reescrever a v0.5 |
| `outputs/decisoes_documentais_91_entidades_ano.csv` | Dossie original preservado e acrescido da rodada documental; R$ 151.093.325,68 conservados |
| `outputs/figuras/mapa_entidades_saude_mg_presenca_mides.png` | Sedes cadastrais das 84 entidades; sobreposicoes possiveis |
| `outputs/figuras/mapa_unidades_cnes_saude_mg_por_funcao.png` | Pontos municipais para 669/670 unidades; movel 5563003 sem municipio no cache |

`funcao_assistencial` e `decisao_tempo_principal` sao o filtro funcional vigente.
O marcador legado `unidade_fixa_elegivel` do script 05 significa apenas
candidata cadastral. Nao usar os dois como sinonimos. A classificacao por tipo
nao garante acesso ou producao. A ligacao de elegibilidade, tempo, capacidade,
escopo e alternativas pertence ao passo 6. O dossie de 91 trata ausencia de
qualquer fixa; a tabela de 672 tambem identifica fixa sem funcao clinica.

## Atualizacao De 10/09/2026

- `05_construir_capacidade_assistencial_saude.R --cache-only`: reprocessa os
  670 caches da coleta de 03/09 sem consultas externas; preserva data e
  proveniencia do vinculo proprio/mantenedor. O tipo CNES movel exclui uma
  unidade fixa mesmo quando o nome apenas informa USB/USA.
- `unidade_movel_pelo_tipo`: 586 unidades oficialmente moveis;
  `classificacao_fixa_pendente`: 2 fichas com indicio nominal e tipo
  conflitante/ausente; `unidade_fixa_elegivel`: 82 candidatas cadastrais,
  antes do filtro final de funcao clinica do script 11. O nome legado nao prova acesso.
- Os produtos de coleta do script 04 e snapshots `2026_09_03` preservam a
  classificacao inicial por nome como evidencia historica. Para capacidade e
  tempo principais, combinar a coleta do script 05 com o filtro do script 11.
- `data_extracao_cnes` permanece 2026-09-03; `data_reprocessamento` e
  2026-09-10 nas unidades. Snapshots `2026_09_10` sao reprocessamentos.
- `10_auditar_pendencias_assistenciais_saude.py`: complemento tecnico do
  passo cientifico 3; usa biblioteca padrao Python e produtos 07/09 existentes.
  Nao e o passo cientifico 10 e nao altera o painel.

| Arquivo | Unidade e finalidade |
|---|---|
| `evidencias/decisoes_sete_entidades_2026_09_10.csv` | 7 entidades; decisao documental, fonte, alcance temporal e pendencia |
| `outputs/decisoes_anuais_sete_entidades.csv` | 56 entidades-ano; junta evidencia e CNES do proprio ano |
| `outputs/dossie_91_entidades_ano_sem_fixa.csv` | 91 entidades-ano com pagamento positivo e nenhuma fixa em dezembro |
| `outputs/resumo_28_entidades_sem_fixa.csv` | 28 entidades; anos, valor e estado da pesquisa documental |
| `tests/10_validar_pendencias_assistenciais_saude.py` | reconcilia chaves, R$ 151.093.325,68, temporalidade e ausencia de imputacao |

No dossie, `decisao_principal` trata a especificacao de destino fixo;
nao exclui pagamentos da base financeira. `primeiro_ano_fixo_observado`
e observacao cadastral, nao data real de abertura. `fonte_complementar_url`
nao substitui a evidencia anual local: documentos recentes so corroboram
identidade ou fatos historicos expressamente datados.

Este documento e o inventario oficial da pasta. Ele responde quatro perguntas:

1. qual arquivo executa cada passo;
2. quais dados entram e de onde vieram;
3. qual produto deve ser aberto;
4. qual teste comprova que o passo fechou corretamente.

O `README.md` continua sendo a porta de entrada. A ordem e o estado dos dez
passos estao exclusivamente em `PLANO_DE_TRABALHO.md`. A evolucao substantiva
das entregas esta em `LINHA_DO_TEMPO_PASSOS.md`.

## Numeracao

Ha dez passos cientificos e dez scripts tecnicos executados ate aqui. As duas numeracoes
nao sao equivalentes: um passo pode exigir mais de um script e um complemento
pode corrigir um produto anterior sem criar novo passo cientifico.

| Passo cientifico | Script tecnico | Conteudo |
|---:|---|---|
| 1 | `01` | universo de saude e identidade matriz/filial |
| 2 | `02` e `03` | cotejamento MIDES-MUNIC e revisao documental |
| 3 | `04` | polo ou rede assistencial diretamente vinculada |
| 4 | `05` | capacidade assistencial atual no CNES |
| 5 | `06` | tempo rodoviario ate a oferta fixa |
| 6 | `07` | painel municipio-entidade-ano e eventos |
| complemento do 3 | `08` | auditoria da cobertura assistencial |
| complemento do 4 | `09` | capacidade CNES historica 2014-2021 |

## Mapa Da Pasta

| Local | O que contem | Regra de uso |
|---|---|---|
| `README.md` | visao geral e ordem de leitura | abrir primeiro |
| `PLANO_DE_TRABALHO.md` | dez passos, checkboxes e proximo marco | unica fonte para ordem e estado |
| `DICIONARIO_TECNICO.md` | arquivos, fontes, extracoes e produtos | consultar para localizar ou reproduzir |
| `LINHA_DO_TEMPO_PASSOS.md` | evolucao dos passos e exemplo real | consultar para explicar o projeto |
| `METODOLOGIA_GERAL.md` | metodologia das entregas e complementos executados | consultar para defender decisoes |
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

### Complemento Temporal Do Passo 4 - CNES Historico

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
| CNES/DATASUS historico | `ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/` | `cache_cnes_historico/` e manifesto local | 2014-2021 | complemento do 4 | `ST` mensal; `LT`, `SR` e `PF` de dezembro |
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

- A CNM nao altera os passos concluidos: ela e fotografia cadastral atual e ainda
  nao foi materializada como composicao historica da tabela de saude.
- SICONFI nao identifica o CNPJ destinatario e nao entra como vinculo do par.
- A grade preliminar nao continha populacao, RCL, regiao de saude, bacia nem
  mandato. A integracao anual de 23/09 acrescentou populacao completa, RCL
  parcial, PDR/2019 como referencia para 2019-2021 e ciclo do mandato. Bacia
  segue em decisao metodologica.
- Trinta e cinco das 84 entidades nao possuem destino clinico fixo no filtro
  atual. Redes moveis/contratadas exigem desenho proprio e documentacao;
  nenhum destino foi inventado. A disponibilidade historica e avaliada por ano.

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
python analises/modelo_gravitacional_saude/10_auditar_pendencias_assistenciais_saude.py
python analises/modelo_gravitacional_saude/tests/09_validar_cnes_historico_saude.py
python analises/modelo_gravitacional_saude/tests/10_validar_pendencias_assistenciais_saude.py
Rscript analises/modelo_gravitacional_saude/11_diagnosticar_universo_e_elegibilidade_saude.R
Rscript analises/modelo_gravitacional_saude/tests/11_validar_diagnostico_universo_e_elegibilidade_saude.R
```

Os produtos pesados em `outputs/` sao derivados e ignorados pelo Git. Codigo,
testes, checks, metodologias e evidencias pequenas sao versionados.

## Revisao Externa E Atlas Por Consorcio — Scripts 12 E 13

| Arquivo | Conteudo / unidade |
|---|---|
| `12_revisar_fronteira_universo_saude.py` | cadastro MG + CNM menos 84; selecao CNES em oito ST de dezembro; reutiliza o conversor do script 09 |
| `evidencias/revisao_fora_84_2026_09_16.csv` | 28 decisoes documentais por raiz, com fonte, periodo e limites |
| `13_detalhar_atlas_consorcios_saude.R` | consulta MIDES complementar opcional, cruzamento financeiro e atlas |
| `atlas_consorcios.js` | interacao Leaflet: consorcio, periodo, funcao, tipo, camadas e CSV |
| `tests/12_validar_fronteira_e_atlas.py` | invariantes de universo, valores, fontes e tempo; `--browser` testa interface offline |

Novos produtos locais em `outputs/`, sem sobrescrever os scripts 01-11:

| Produto | Conteudo |
|---|---|
| `fronteira_universo_cadastro.csv` | 137 raizes externas: 122 cadastro IPEA + 15 somente CNM |
| `fronteira_cnes_unidades_2014_2021.csv` | 74 unidades-ano ST, das quais 71 clinicas e tres nao clinicas |
| `fronteira_cnes_fontes.csv` | oito arquivos-fonte, URL e SHA-256 |
| `fronteira_mides_complementar.csv` | 1.079 agregados ano-municipio-CNPJ; consulta de 15 raizes |
| `fronteira_consulta_mides.sql` / `fronteira_consulta_mides_manifesto.json` | consulta exata, data, raizes e estatisticas da execucao; cache BigQuery pode indicar zero bytes processados naquela execucao |
| `revisao_fora_84_resultado.csv` | 137 decisoes, sinais cadastrais, CNES e montantes MIDES; 28 com pesquisa documental |
| `atlas_pagamentos_entidade_municipio_ano.csv` | valores anuais somados por raiz, preservando matriz/filial; o mapa seleciona valores positivos |
| `atlas_unidades_consorcio_periodo.csv` | 2.612 registros unidade-periodo; 670 atuais + 1.868 historicos originais + 74 externos |
| `atlas_municipios.geojson` / `atlas_dados.json` | 853 municipios e dados incorporados ao HTML |
| `atlas_consorcios_saude_mg.html` | mapa interativo autocontido, executavel localmente sem servidor |
| `atlas_cismep_2019.png` / `atlas_ciesp_2019.png` | capturas produzidas pelo teste opcional do navegador |

Entradas: cadastro nacional consolidado (Windows-1252), classificacao v0.5,
CNM `C:/IPEA/dados cnm/snapshots/2026-08-27/data/base_unificada_consorcios_macroareas.csv`,
cache ST, elegibilidade do script 11, painel MIDES local e malha municipal do
dashboard. O campo `valor_mides` soma pares-ano positivos e nao identifica
finalidade setorial. Zero sinal na triagem nao e prova de capacidade zero.
`revisao_documental` distingue as 28 pesquisadas individualmente das 109
restantes; `status_mides` distingue consulta complementar da extracao original.

Reproducao, na raiz do repositorio, depois dos produtos 01-11:

```powershell
python analises/modelo_gravitacional_saude/12_revisar_fronteira_universo_saude.py
Rscript analises/modelo_gravitacional_saude/13_detalhar_atlas_consorcios_saude.R --consultar-mides
python analises/modelo_gravitacional_saude/tests/12_validar_fronteira_e_atlas.py --browser
```

Apenas a primeira consulta exige BigQuery autenticado e projeto autorizado
(`MIDES_BILLING_ID`, padrao do projeto existente). Reexecucoes do atlas omitem
`--consultar-mides` para usar o cache; a opcao `--somente-consulta` encerra
depois do download. O limite de faturamento por consulta e 100 GB; nao implica
gratuidade. Nenhuma credencial e gravada nos produtos. R requer sf, dplyr,
readr, bigrquery (consulta), leaflet, htmlwidgets, htmltools, jsonlite e Pandoc;
se nao detectado, definir `RSTUDIO_PANDOC` para a pasta do executavel.
O teste basico usa Python padrao; `--browser` requer Playwright com Chromium.

## Integracao Anual Do Passo 6 - 23/09/2026

O painel novo nao sobrescreve `painel_analitico_saude_mg.rds`, que continua a
documentar a grade preliminar das 84 entidades. Os produtos abaixo ficam em
`outputs/` e nao entram no Git; os scripts, SQL e teste sao versionados.

| Arquivo | Papel e unidade | Limite |
|---|---|---|
| `14_completar_cnes_candidatas_saude.py` | Reusa os 120 DBC CNES; gera 74 unidades-ano externas em dezembro, capacidade LT/SR/PF, 104 entidades-ano e 75 registros de presenca unidade-ano | vinculo por CNPJ direto; nao mede prestadores terceirizados |
| `populacao_ibge_mg_2014_2021.sql` | Consulta reproduzivel de 6.824 municipio-ano em `basedosdados.br_ibge_populacao.municipio` | requer BigQuery e projeto de faturamento autorizado |
| `16_extrair_rcl_siconfi_saude.py` | Consulta API oficial Siconfi, RREO-Anexo 03, sexto bimestre; um CSV por ano | 2014 sem retorno; em 2015-2021 so 160-270/853 municipios por ano retornaram RCL |
| `17_extrair_regioes_saude_pdr_2019.py` | Le Anexo I da Deliberacao CIB-SUS/MG 3.013/2019: 853 municipios, 66 micros e 12 macros | a referencia de 2019 nao e retroagida a 2014-2018 |
| `15_integrar_painel_anual_saude.R` | Junta 853 municipios, 97 entidades e 8 anos; recalcula tempo ate destinos clinicos do proprio ano e materializa alternativas e riscos | recorte direto candidato condicionado a clinica direta e tempo historico; cobertura parcial |
| `18_diagnosticar_alternativas_painel_saude.R` | Compara cobertura das regras, retenção de pagamentos, cortes de 90/120/180 minutos e municipios sem opcao | diagnostico do passo 6, sem estimacao de modelo |
| `19_eda_inicial_painel_saude.R` | Audita zeros, eventos, perdas por polo/escopo, RCL, capacidade, cortes territoriais e 19 tempos extremos contra MIDES/Distbrasil | passo 7; nao exclui extremos automaticamente |
| `20_auditar_marcador_sus_e_destinos.R` | Compara clinicas CNES com vinculo ou capacidade SUS registrada; recalcula tempos para este subconjunto | teste de qualidade/sensibilidade, sem mudar o painel principal |
| `21_inventariar_qualidade_painel_saude.R` | Perfila as 60 colunas por ano em grade, pagadores de saude e pagadores diretos; audita chaves e extremos e lista lacunas por entidade-ano | diagnostico de qualidade, sem alterar a base ou declarar amostra final |
| `tests/13_validar_painel_anual_saude.R` | Confere montantes, chaves, historia Igarape-CISMEP, CIESP, CIMBAJE, CIMAMS e ausencia sem polo | executado apos o script 15 |

Produtos principais: `painel_anual_integrado_saude_mg_2014_2021.rds`
(661.928 linhas), `painel_anual_integrado_resumo.csv`,
`diagnostico_alternativas_painel_saude_2014_2021.csv`,
`diagnostico_municipios_sem_alternativa_saude.csv`,
`eda_inicial_painel_saude_2014_2021.csv`,
`eda_tempos_acima_300min_saude.csv`,
`eda_selecao_pagadores_saude.csv`, `eda_selecao_entidades_saude.csv`,
`eda_selecao_rcl_saude.csv`, `eda_cobertura_capacidade_cnes_saude.csv`,
`eda_sensibilidade_alternativas_saude.csv`,
`eda_marcadores_sus_unidades.csv`, `eda_efeito_marcador_sus_saude.csv`,
`eda_pares_afetados_marcador_sus_saude.csv`,
`eda_inventario_60_variaveis_painel_saude.csv`,
`eda_cobertura_anual_painel_saude.csv`,
`eda_lacunas_polo_entidade_ano_saude.csv`,
`eda_anomalias_painel_saude.csv`,
`eda_extremos_exploratorios_saude.csv`,
`candidatas_cnes_capacidade_unidades_2014_2021.csv`,
`candidatas_cnes_capacidade_entidade_ano_2014_2021.csv`,
`candidatas_cnes_presenca_mensal_2014_2021.csv`,
`populacao_municipal_ibge_2014_2021.csv`, `rcl_siconfi_mg_AAAA.csv` e
`regionalizacao_saude_mg_pdr_2019.csv`.

As 60 colunas do painel se organizam em identificacao e escopo da entidade,
pagamento MIDES, capacidade CNES anual, decisao documental, tempo e destino
rodoviarios, controles territoriais/fiscais, movimentos financeiros e flags de
alternativas/risco. O arquivo `eda_inventario_60_variaveis_painel_saude.csv`
lista **cada coluna** e sua classe, nulos, strings vazias, zeros e distribuicao
por ano em tres universos. Leia os denominadores antes de comparar percentuais:
na grade inteira, zero em `valor_total` significa ausencia de pagamento
observado; nos pares pagantes sem CNES direto, `NA` em capacidade e tempo
significa que o destino direto nao foi identificado. `NA` em `rcl_municipal`
e falta da fonte consultada; `NA` em `regiao_saude` antes de 2019 evita
retroagir o PDR/2019; `NA` em colunas `t_1` em 2014 decorre da borda da serie.
Zero em `leitos_sus_clinicos` e somente zero cadastral no modulo consultado.
As colunas de decisao documental foram preenchidas em subconjunto auditado;
seu `NA` nao equivale a falta de pesquisa nos dossies separados.

Proveniencia: [estimativas do IBGE](https://www.ibge.gov.br/estatisticas/sociais/populacao/9103-estimativas-de-populacao.html)
via Base dos Dados/BigQuery;
[API Siconfi](https://www.gov.br/conecta/catalogo/apis/siconfi-extratos-das-declaracoes-contabeis)
e [definicao do RREO/Anexo 03](https://siconfi.tesouro.gov.br/siconfi/pages/public/arquivo/conteudo/2024_Regras_Gerais_e_Instrucoes_de_preenchimento_RREO.pdf);
[PDR-SUS/MG 2019, Anexo I](https://www.saude.mg.gov.br/wp-content/uploads/2019/11/Del-3013-SUBGR_SDCAR_DREA-Ajuste-PDR-versao-CIB-alterada-15.10-a71.pdf).
O tempo usa a mesma matriz Distbrasil do passo 5, com checksum conferido.

Decisao de 23/09: bacia hidrografica fica para analise territorial posterior,
fora dos controles exigidos pelo modelo gravitacional de saude. O recorte
candidato usa clinica direta historica sem limite de minutos; 90/120/180
minutos e mesma microrregiao sao sensibilidades. O PDR/2019 so se aplica a
2019-2021; RCL faltante permanece ausente.

Auditoria de 24/09: `clinica_direta_dezembro` significa registro de tipo
clinico vinculado ao CNPJ no dezembro do ano; nao significa producao SUS nem
viagem de pacientes. O script 20 distingue `vinculo_sus` e capacidade SUS
positiva e mede o efeito de exigir qualquer um desses marcadores. O achado
anterior sobre leitos escassos permanece valido: CISMEP tem 32 no retrato
atual, enquanto a raiz `64486822` tinha 26 nos dezembros de 2014-2016.
Os produtos da EDA sao locais em `outputs/`, com scripts versionados.

Para reproduzir a partir desta pasta: instalar
`requirements_cnes_historico.txt` e `requirements_painel_anual.txt`; executar
o script 14, a consulta SQL de populacao, os scripts 16 e 17, depois o 15;
executar o teste 13 a partir da raiz `ideiaMides`. O script 16 grava
checkpoints por ano para retomada. O ano 2014 mantem RCL ausente; ausencia de
resposta da API em outros anos nao significa receita zero. A medida de
profissionais somada entre unidades nao equivale a pessoas distintas.
Para refazer a auditoria de 24/09, executar o script 18 e depois os scripts
19 e 20 a partir desta pasta. O script 19 confronta os extremos com os
extratos MIDES anteriores; o 20 confere o exemplo Igarape-CISMEP e a excecao
CISVAS/2019 sem marcador SUS. Nenhum altera o painel `.rds`.

## Conciliacao E Indice De Produtos — 24/09/2026

O script `22_conciliar_lacunas_e_proveniencia_saude.py` reaproveita os dossies,
o CNES historico e o inventario do script 21. Usa Python 3.11 ou superior;
a verificacao opcional dos 12 ST reutiliza as dependencias e o conversor do
script 09. Nao modifica o painel anual e nao executa consulta paga ao MIDES.

| Arquivo | Conteudo e uso |
|---|---|
| `evidencias/conciliacao_181_entidades_ano_2026_09_24.csv` | 181 chaves raiz-ano; classificacao anterior, grupo, decisao detalhada, tratamento, CNES, fonte anual, contexto documental e limite; versionado |
| `evidencias/fontes_conciliacao_2026_09_24.csv` | Sete referencias novas: cinco marcos SAMU e duas atas localizadas sem conteudo acessivel; datas e alcance; versionado |
| `outputs/resumo_conciliacao_lacunas_saude.csv` | Seis grupos exclusivos com entidades-ano, pares pagos e valores |
| `outputs/conciliacao_cismas_2016_mensal.csv` | 12 competencias de 2016, tipo da unidade 6776434, municipio, URL e hash do ST |
| `outputs/eda_extremos_conferidos_na_fonte_saude.csv` | 60 conferencias financeiras do script 21: valor e transacoes recalculados, origem e diferenca; inclui um caso de valor zero |
| `outputs/rotulos_entidades_sem_sigla_saude.csv` | Cinco raizes, nome completo canonico e numero de pares pagos; nao inventa siglas |
| `outputs/inventario_produtos_saude.csv` | Indice dos produtos diretamente em outputs na ultima execucao, com tamanho, hash, modificacao local e scripts que os mencionam |
| `outputs/manifesto_entradas_conciliacao_saude.csv` | Caminhos relativos ao repositorio e hashes dos extratos principais e catalogos usados |
| `outputs/fontes_conciliacao/manifesto.csv` | URL, consulta UTC, caminho, hash e status de cada tentativa de arquivamento documental |
| `tests/14_validar_conciliacao_lacunas_saude.py` | Verifica conservacao, cobertura, temporalidade, nomes, conferencias financeiras e integridade dos arquivos |

Os dois indices CSV nao indexam um ao outro, evitando hashes circulares.
Subpastas de cache tem seus proprios manifestos; esse indice nao
e um inventario recursivo de cada arquivo bruto. Referencia textual em script
nao identifica necessariamente o produtor do arquivo. O dicionario e os
manifestos de cada fonte continuam sendo a referencia de reproducao.

Na tabela de conciliacao, `classificacao_anterior_painel` preserva os 97
vazios originais como `sem_classificacao_anual_no_painel`.
`fonte_documental_aplicada` distingue documento utilizado na decisao de
`referencias_contextuais_nao_automaticamente_anuais`: fonte atual ou de outro
periodo nao comprova disponibilidade no ano da linha. `fonte_cnes_url` e
`fonte_cnes_sha256` identificam o ST de dezembro. Nas quatro excecoes mensais,
consultar tambem a presenca mensal e o manifesto historico; CISMAS possui a
conferencia adicional das 12 competencias. `polo_clinico_anual_recuperado`
permanece falso em todas as linhas: classificacao nao e imputacao de destino.

Reproduzir na pasta do modelo, depois dos produtos 01-21:

```powershell
Rscript 21_inventariar_qualidade_painel_saude.R
python 22_conciliar_lacunas_e_proveniencia_saude.py --verificar-cismas --baixar-fontes
python tests/14_validar_conciliacao_lacunas_saude.py
```

Nas reexecucoes locais, omitir as duas flags se a conferencia mensal e o cache
ja existem. O script 22 deve rodar depois do 21 para atualizar o inventario de
hashes. O teste 13 continua sendo executado da raiz do repositorio. Quatro
fontes novas ficaram em cache; a pagina CIS-URG foi lida via web, mas sua copia
local retornou 403. As duas atas Circuito nao tiveram seu conteudo lido e nao
sustentam nenhuma afirmacao sobre prestadores.

A fonte financeira original e `dados/bruto/mides_mg_atualizado.rds`;
`scripts/01_baixar_mides_mg.R` documenta a consulta. A data 05/05/2026 e
indicada por comentario e metadados locais, sem log confirmatorio da extracao.
O complemento usa `fronteira_mides_complementar.csv`, com consulta e data em
`fronteira_consulta_mides_manifesto.json` (16/09/2026). Data de modificacao de
arquivo nao deve ser apresentada como data de extracao confirmada.

## Revisao Prioritaria, Piloto Mensal E Suficiencia — 24/09/2026

Esta continuidade usa os mesmos quatro documentos substantivos. Nao altera
painel, extratos brutos, regras de alternativas ou dashboard. Evidencias
manuais e scripts ficam no Git; produtos derivados e copias integrais de
documentos ficam locais em `outputs/`, com URLs e hashes auditaveis.

| Arquivo | Granularidade, produtor e uso |
|---|---|
| `evidencias/fontes_prioritarios_2026_09_24.csv` | Nove fontes primarias, URL, paginas, alcance e limite; revisao manual. Aviso do CONSARDOCE e de autoria do consorcio, publicado em jornal |
| `evidencias/revisao_prioritarios_2026_09_24.csv` | 14 chaves raiz-ano; decisao, servico, CNES quando associavel, base da associacao, periodo e pendencia. Todas sem disponibilidade clinica anual integral recuperada |
| `23_avaliar_temporalidade_cnes_saude.py` | Diagnostico a partir da presenca mensal original/externa e elegibilidade de dezembro; flags opcionais coletam piloto, arquivam fontes e verificam candidato CONSARDOCE |
| `outputs/diagnostico_necessidade_mensal_unidades_saude.csv` | 482 unidades-ano com algum tipo clinico; 58 com prioridade temporal; meses presentes nao significam necessariamente meses clinicos |
| `outputs/diagnostico_necessidade_mensal_entidades_saude.csv` | 405 entidades-ano com algum tipo clinico, sendo 53 prioritarias; estabilidade de tipo/presenca nao prova estabilidade de capacidade |
| `outputs/piloto_cnes_competencias_saude.csv` | Seis fotografias unidade-competencia: CNPJ proprio/mantenedor, tipo, municipio, vinculo, leitos, servicos, profissionais, CBO e horas SUS; sem identificadores pessoais |
| `outputs/manifesto_cnes_piloto_temporal.csv` | 24 arquivos ST/LT/SR/PF, URL, caminho, SHA-256, bytes e verificacao UTC; quinze DBC novos e nove reutilizados nesta primeira execucao |
| `outputs/manifesto_fontes_prioritarios_saude.csv` | Nove fontes com caminho, URL, hash e resultado do arquivamento; oito copiadas. Pagina de transporte Lagoa Santa lida via web; copia local retornou 403 |
| `outputs/verificacao_cnes_candidato_consardoce.csv` | Oito ST de dezembro pesquisados pelo codigo 5941954, sem restringir CNPJ: ausente em todos; nao exclui atendimento sob outro cadastro |
| `24_delimitar_suficiencia_dados_saude.R` | Le painel e diagnostico; mede oito recortes em nove periodos, incorpora revisao e confere quatro janelas financeiras; requer dplyr ja utilizado |
| `outputs/matriz_suficiencia_recortes_saude.csv` | 72 linhas: oito recortes, oito anos e total. Quantidades, valor, RCL e PDR; os recortes se sobrepoem e nao devem ser somados |
| `outputs/impacto_prioridade_temporal_saude.csv` | 53 prioridades; 48 com pagamento no nucleo saude, 692 pares e R$ 394.645.232,32; impacto potencial de temporalidade, nao valor incorreto |
| `outputs/conciliacao_lacunas_com_revisao_prioritaria_saude.csv` | Visao vigente das 181 chaves: conserva classificacao/valor anteriores, adiciona 14 revisoes e `decisao_vigente`; sempre ler pendencia/alcance junto da decisao |
| `outputs/pagamentos_janelas_clinicas_piloto_saude.csv` | Oito grupos para quatro casos; 1.022 transacoes por janela, somando `valor_final`; data financeira nao e data de atendimento |
| `tests/15_validar_suficiencia_e_piloto_saude.py` | Conservacao das chaves/valores, identidade municipal, restricoes de vigencia, prioridades, seis fotografias, recortes e hashes |

O painel possui campos documentais anteriores. A visao complementar vigente
nao deve ser confundida com alteracao dessas colunas no RDS. Em particular,
`cnes_associado=6019463` no Circuito e uma ligacao por nome/localidade e noticia;
nao consta como codigo no instrumento citado nem como CNPJ direto do consorcio.
`polo_anual_integral_recuperado=FALSE` impede interpretar identificacao parcial
como disponibilidade integral. Regulacao e transporte nao recebem CNES ficticio.

Reproducao nesta pasta, apos os produtos anteriores:

```powershell
python 22_conciliar_lacunas_e_proveniencia_saude.py
python 23_avaliar_temporalidade_cnes_saude.py --coletar-piloto --arquivar-fontes --verificar-candidato
Rscript 24_delimitar_suficiencia_dados_saude.R
python -c "import runpy; runpy.run_path('22_conciliar_lacunas_e_proveniencia_saude.py')['inventory']()"
python tests/14_validar_conciliacao_lacunas_saude.py
python tests/15_validar_suficiencia_e_piloto_saude.py
```

O piloto reutiliza Python 3.11+, o conversor e dependencias do script 09.
Arquivos ja baixados sao reutilizados; `ja_em_cache` descreve cada execucao.
Sem flags, o script 23 apenas refaz o diagnostico, sem rede. O arquivamento
documental nao faz OCR nem substitui leitura: PDFs escaneados foram lidos
com OCR portugues e conferidos visualmente nas paginas citadas; OCR e
previas sao auxiliares locais, sem expor CPFs ou assinaturas na tabela publica.
Para apenas atualizar hashes apos novos produtos, usar a chamada `inventory`
acima; isso nao refaz a conciliacao. Teste 13 continua na raiz do repositorio.

Nao foi repetida a consulta MIDES. A conferencia usa o extrato original ja
identificado por hash, preservando sua data de extracao incerta e o manifesto
do complemento. Rerodar a consulta original sem outra necessidade nao resolve
prestadores/contratos e sobrescreveria a fonte existente.

Consulta metodologica de 24/09: o README ganhou um mapa das camadas da base;
a secao final da metodologia explica indicadores, PCA, discriminante e quatro
estudos comparaveis, com URLs e limites. Dois artigos foram copiados para
`outputs/literatura/`, com URL e SHA-256 em `outputs/literatura/manifesto.csv`.
Sao referencias de pesquisa, nao entradas do painel; os demais foram lidos
nas paginas dos autores/editoras. A verificacao de correlacoes tem comando R
reproduzivel na metodologia; nao houve ajuste de PCA ou modelo gravitacional.

## Entrega V1 — Duas Bases E Retrato Dos Dados

Pasta local `outputs/base_v1/`; arquivos grandes continuam fora do GitHub.
O README e a entrada humana; nao foi criado outro Markdown. O script
`25_fechar_base_v1_saude.R` usa dplyr e digest ja disponiveis no ambiente.

| Produto | Uso |
|---|---|
| `base_financeira_v1.csv` / `.rds` | 491.328 linhas x 19 colunas; nucleo de saude, com e sem pagamentos |
| `base_gravitacional_v1.csv` / `.rds` | 323.287 x 30; subconjunto com clinica direta em dezembro e tempo, conservando zeros |
| `inclusao_entidade_ano.csv` | 776 chaves das 97 entidades: destino de cada caso, motivo, pagamentos e alerta temporal |
| `capacidade_entidade_ano.csv` | 379 chaves diretas sem repeticao municipal; medidas CNES e horas agregadas |
| `perfil_capacidade.csv` | 45 perfis: quantis, zeros, nulos e concentracao de cinco medidas por periodo |
| `correlacoes_capacidade.csv` | 90 correlacoes Spearman; constante gera NA identificado, nao zero |
| `perfil_modalidades_cnes.csv` | Perfis por ano, funcao e tipo; universo das 1.942 unidades-ano |
| `cnes_multiplas_entidades.csv` | Conferencia de mesmo CNES/ano em raizes diferentes; somente cabecalho porque nenhum caso foi encontrado |
| `cobertura_recortes.csv` | Quatro recortes x nove periodos reaproveitados da matriz de suficiencia |
| `cobertura_variaveis.csv` | Nulos e vazios por coluna das duas bases; completude nao implica atendimento comprovado |
| `dicionario_variaveis.csv` | Definicao, tipo R, tabela e fonte das 30 variaveis distintas |
| `exemplo_igarape_cismep.csv` | Oito linhas reais de 2014 a 2021 para leitura ponta a ponta |
| `manifesto.csv` | SHA-256 e tamanho de oito entradas e 14 saidas; impede substituicao silenciosa por fontes diferentes |

As entradas sao o painel anual, os dois arquivos CNES historicos por unidade,
a conciliacao vigente, o diagnostico temporal, os cadastros original/externo
e a matriz de suficiencia; os caminhos exatos estao no manifesto. Fontes remotas,
consultas e extracoes subjacentes permanecem nas secoes anteriores e nos
manifestos originais. A data antiga incerta do MIDES nao foi reinventada.

Dentro de `analises/modelo_gravitacional_saude`, executar:

```powershell
& 'C:\Program Files\R\R-4.3.1\bin\Rscript.exe' 25_fechar_base_v1_saude.R
```

Da raiz do repositorio, validar:

```powershell
& 'C:\Program Files\R\R-4.3.1\bin\Rscript.exe' analises/modelo_gravitacional_saude/tests/16_validar_base_v1_saude.R
```

O teste verifica as chaves exatas dos filtros originais, todos os campos herdados,
pagamentos/zeros, horas das clinicas, motivos de exclusao, CSV/RDS, exemplo real
e hashes, inclusive preservacao do MIDES e painel originais. Nao se precisa
rodar novamente scripts de coleta. Mudanca de entrada exige planejar uma v2.

CSV: virgula, ponto decimal, UTF-8 e vazio para NA; importar CNPJ/IBGE como
texto. Para analise em R, preferir RDS. Horas sao somas cadastrais PF, nao
horas anuais realizadas; `distancia_minima_km` e a distancia ao destino de
menor tempo, nome herdado. RCL/PDR e variaveis de risco detalhadas permanecem
no painel de 60 colunas, sem funcionar como filtros das tabelas v1.

## Revisao Dos Produtos Visuais — 24/09/2026

| Produto local existente | Universo e leitura correta |
|---|---|
| `outputs/figuras/mapa_entidades_saude_mg_presenca_mides.png` | 84 entidades originais; 66 com pagamento MIDES em 2014-2021. Localizacao municipal das sedes; nao e o universo v1. |
| `outputs/figuras/mapa_unidades_cnes_saude_mg_por_funcao.png` | Snapshot coletado em 03/09/2026: 670 unidades, sendo 63 clinicas fixas, 20 nao clinicas e 587 moveis. Mapeia 669: CNES 5563003 sem municipio. |
| `outputs/atlas_consorcios_saude_mg.html` | Inventario de 221 entidades, nao amostra de saude. Filtros entidade/ano/funcao/tipo; 2.612 registros unidade-periodo: 670 atuais e 1.942 historicos. |

Mapas produzidos em 16/09 e revistos em 24/09. No atlas, municipios azuis
tem pagamento MIDES no ano escolhido. O contorno CNM opcional representa
27/08/2026, mesmo quando o ano selecionado e historico; nao prova composicao
anual. Pontos CNES agrupam unidades no municipio, nao sao enderecos exatos.
A coleta atual abrange as 84 originais; ausencia dessa coleta nas externas
nao significa zero unidades. O total financeiro inclui todas as finalidades
e nao e repartido pelos filtros de unidade. Nenhuma dessas areas demonstra
origem dos pacientes ou cobertura contratada.

**Conferencia:** `python analises/modelo_gravitacional_saude/tests/12_validar_fronteira_e_atlas.py --browser`,
na raiz, passou em 24/09: filtros, exportacao, avisos, tela estreita e uso offline.
As capturas `outputs/atlas_cismep_2019.png` e `outputs/atlas_ciesp_2019.png`
sao evidencias de interface, nao novos graficos analiticos. A conciliacao em
R por raiz/municipio/ano confirmou valores (tolerancia R$ 0,01) e transacoes
das 10.735 relacoes pagas v1; por raiz/ano, as contagens clinicas das 379
entidades-ano diretas tambem coincidem. CISMEP/2019: 45 municipios pagadores,
R$ 93.342.499,23 e duas clinicas, em Betim e Brumadinho.

**Ajustes pendentes antes de apresentacao:** atualizar o texto do atlas que
ainda remete ao passo 6 e identificar as decisoes de revisao como retrato
de 16/09; explicitar os universos nas legendas. Os mapas do dashboard geral
pertencem a outras analises, nao sao graficos CNES da v1. Seu codigo local
foi consultado; a publicacao online nao foi retestada nesta revisao.

**Ainda nao produzido:** pacote visual da EDA v1. Seus perfis, correlacoes e
cobertura ja existem em CSV. Usar `capacidade_entidade_ano.csv` para nao
repetir a capacidade por municipio; valores financeiros sao nominais e
zeros da grade nao sao transacoes observadas. Os multiarea ficam em painel
comparativo auxiliar. A definicao da amostra do modelo nao impede esses
graficos descritivos, mas impede interpreta-los como estimacao gravitacional.

Previa de design posterior nesta data: `outputs/visuais_v1/prototipo/`, com
`index.html` navegavel e tres exemplos reais (cobertura, capacidade/2019 e
CISMEP/2019), PNG 300 dpi e SVG. `gerar_previa.R` reproduz somente o rascunho,
executado da raiz; nao substitui os scripts nem o atlas existentes. Os
produtos sao locais e aguardam aprovacao visual; nao constituem o pacote
final. Navegacao, uso offline e ausencia de overflow da pagina em tela
estreita conferidos; figuras mantem rolagem propria para leitura. Teste 16
reexecutado confirmou conservacao da v1 e dos hashes das fontes.

**Revisao da proposta na mesma data:** a previa acima foi rejeitada e fica
apenas como historico. A segunda proposta local esta em
`outputs/visuais_v1/proposta_02/index.html`. Demonstra serie anual financeira,
cobertura por relacoes e dinheiro, e atlas CISMEP/2014–2021 com ano, camadas,
recorte regional/estadual e consulta municipal. A terceira aba especifica
os seis blocos completos, inclusive tempos e comparacao multiarea ainda
por implementar. Nao e substituto do atlas nem entrega final aprovada.

Reproducao da proposta, a partir da raiz: executar com Rscript
`outputs/visuais_v1/proposta_02/preparar_dados.R` (prefixado por
`analises/modelo_gravitacional_saude/`), depois executar com Python
`analises/modelo_gravitacional_saude/outputs/visuais_v1/proposta_02/montar.py`.
O primeiro le as bases v1, capacidade, unidades do atlas e geometria municipal;
o segundo incorpora `dados.json` ao HTML. Nenhuma fonte e sobrescrita.
`atlas_2019.png` e `leitura.png` sao capturas da proposta, nao figuras finais.
Conferidos os oito anos do CISMEP, totais da cobertura, camadas, selecao de
Igarape, troca de escala e leitura em tela de 390 px; nova carga sem erros
JavaScript. O HTML incorpora os dados e pode ser aberto localmente.

## Entrega Visual Da V1

A segunda proposta foi aprovada e implementada. A entrada vigente e
`outputs/visuais_v1/index.html`; as pastas `prototipo` e `proposta_02` sao
historicas. A entrega tem seis secoes: leitura da base, pagamentos, CNES,
tempos, atlas e fontes/arquivos. O HTML incorpora o conjunto interativo;
as figuras sao arquivos locais relativos, por isso a pasta deve acompanhar
o HTML ao transferir a entrega. Dados e interacoes nao consultam servicos
externos. A abertura direta por file:// do pacote final foi bloqueada pela
politica do navegador de verificacao; os testes interativos usaram servidor
local. Nao foi declarado teste offline do pacote final.

| Arquivo/pasta | Conteudo e reproducao |
|---|---|
| `26_preparar_visuais_v1.R` | Le v1, inventario do atlas e CNES historico; agrega sem alterar fontes |
| `27_renderizar_visuais_v1.R` | Produz 20 figuras com ggplot2, Noto Sans e paleta aprovada; mapas com sf/patchwork |
| `28_montar_visuais_v1.py` | Incorpora dados/CSS/JS ao HTML, registra hashes e gera ZIP para compartilhar |
| `outputs/visuais_v1.zip` | Pacote com HTML, figuras e dados; extrair a pasta inteira |
| `visuais_v1.html`, `.css`, `.js` | Interface e interacoes da entrega aprovada |
| `outputs/visuais_v1/figuras/` | 20 PNG a 300 dpi e 20 SVG; nomes e interpretacao no catalogo |
| `outputs/visuais_v1/dados/` | CSV dos graficos, JSON interativo, preparacao RDS e manifesto SHA-256 |
| `dados/catalogo_figuras.csv` | Correspondencia figura, pergunta, tabela de dados e secao |
| `tests/17_validar_visuais_v1.py` | Conciliacao independente com os CSVs v1, hashes, PNG/SVG e links |
| `checks/17_visuais_v1.json` | Resultado da verificacao de dados/arquivos |
| `outputs/visuais_v1/qa/` | Capturas da revisao e registro das verificacoes no navegador |

Executar 26 e 27 com Rscript, depois 28 e teste 17 com Python, sempre da raiz
do repositorio. O teste 16 confirma a conservacao da v1. Dependencias R ja
existentes: dplyr, tidyr, readr, sf, jsonlite, ggplot2, scales, stringr,
stringi, patchwork, ragg e svglite. Python usa a biblioteca padrao.

Interacoes: ranking por periodo, trajetoria financeira e municipios
pagadores por consorcio; atlas de 221 entidades por periodo, funcao e tipo,
camadas de pagamento/unidades/CNM, enquadramento regional/estadual e consulta
municipal. Exporta CSV dos filtros e SVG; mapa tambem exporta PNG em alta
resolucao. O PNG do mapa gerado pelo navegador usa dimensoes em pixels,
enquanto os 20 PNG gerados em R possuem metadado de 300 dpi.

O atlas anterior e os dois mapas de 16/09 tiveram textos/universos revistos.
O script 27 atualiza tambem os caminhos antigos dos dois PNG em
`outputs/figuras/`. A capacidade historica nao e projetada para 2026.
