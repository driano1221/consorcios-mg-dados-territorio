# Memoria - Projeto Consorcios MG: Dados e Territorio

**Ultima atualizacao:** 2026-09-03
**Status:** universo de consorcios de saude em MG fechado em camadas cadastral, MIDES observada e setorial preliminar; proxima etapa e o confronto MIDES 2019 x MUNIC 2019 e a revisao documental dirigida.

---

## Camada Nacional Consolidada Em 20/08

- A decisao de identidade foi implementada em camada separada: raiz de oito digitos como entidade e estabelecimento `0001` como CNPJ canonico.
- Os 1.194 CNPJs do cadastro IPEA formam 1.159 entidades; 35 filiais foram incorporadas em 23 raizes.
- O crosswalk preserva CNPJ, nome, sigla, situacao e sede de cada estabelecimento original.
- A consulta MIDES encontrou 1.300.862 transacoes associadas a 512 CNPJs, 505 raizes e municipios pagadores de CE, DF, MG, PB, PR, RS, SC e SP.
- O dashboard preserva a visao MG e oferece uma visao Brasil separada no `MIDES completo`, com cobertura temporal explicita por UF, mapas, movimentos, trajetorias, tabelas, exportacao e auditoria nacional.
- As 681 transacoes de SC sem municipio identificado entram no total financeiro sinalizado, mas nao criam pares, mapas ou movimentos municipais.
- A base anual passou de 40.535 linhas por CNPJ original para 40.486 por raiz, conservando R$ 15.168.694.503,38 no painel municipal.
- Seis raizes foram efetivamente afetadas no MIDES e 49 chaves municipio-ano somaram matriz e filial.
- Foram preservadas separadamente 681 transacoes de SC sem codigo municipal, no valor de R$ 11.145.961,39.
- O recorte MG anterior foi reproduzido exatamente antes da consolidacao: 15.135 linhas, chaves, valores e transacoes iguais.
- A camada nacional ja esta integrada ao dashboard em uma visao Brasil separada. Base 1, MUNIC, SICONFI, classificacao v0.5 e modelos MG permanecem inalterados e aguardam decisao especifica de migracao.

## Pendencias Preservadas Em 27/08

1. Validar a leitura da visao Brasil e as seis raizes matriz-filial efetivamente afetadas no MIDES.
2. Decidir quando aplicar a identidade consolidada a Base 1, MUNIC, SICONFI, classificacao e modelos.
3. Manter explicita a cobertura desigual entre UFs e confirmar o tratamento financeiro das 681 transacoes de SC sem municipio.
4. Revisar documentalmente os 23 CNPJs de baixa escala.
5. Definir controles, forma funcional e universo territorial dos proximos modelos.
6. Avaliar o primeiro recorte territorial externo, com prioridade preliminar para regioes de saude.

Essas frentes nao foram canceladas. Permanecem em espera para que as novas demandas sejam registradas e comparadas antes da retomada.

Documentacao: `analises/base_nacional/METODOLOGIA.md` e
`analises/base_nacional/checks/VALIDACAO_BASE_NACIONAL_V0_1.md`.

---

## Atualizacao Do Dashboard Em 29/07

- A base anual balanceada de movimentos esta integrada ao app: 22.680 linhas, 2.835 pares municipio-CNPJ e oito anos.
- A nova tabela anual por consorcio mostra ativos, entradas novas, retornos, saidas, permanencias, saldo, recorrentes e valor; o botao `+` abre as listas de municipios.
- A subaba `Trajetoria 2014-2021` oferece leitura longitudinal: uma linha por consorcio, oito blocos anuais e saldo do recorte. O `+` abre sob demanda KPIs, linha do tempo, tabela anual e matriz municipio-ano para qualquer consorcio, sem exigir filtro previo.
- A carga geral nao gera matrizes pesadas. Cada detalhe e calculado somente no clique da linha escolhida, preservando desempenho e legibilidade.
- Os oito anos sao apresentados como pequenos multiplos de estilo editorial: ano, total de municipios ativos e linhas alinhadas de entradas, retornos e saidas, sem abreviacoes ou quebras.
- Nomes municipais aparecem nos mapas somente com ate 12 municipios destacados. O zoom conserva contexto territorial e reduz a geometria renderizada.
- Os quatro mapas possuem exportacao propria em PNG de alta resolucao e PDF vetorial, sempre refletindo os filtros ativos.
- O teste `dashboards/base1_shiny/tests/test_movimentos_mapas_export.R` valida contagens, mapas, rotulos, recorte e arquivos exportados.
- O teste `dashboards/base1_shiny/tests/test_trajetoria_longitudinal.R` valida os oito anos e o caso CODAP, inclusive entrada, saida, retorno, saldo e matriz municipal.

---

## Atualizacao Da Classificacao v0.5

- A classificacao por area de politica publica e atributo analitico do CNPJ no MIDES completo; nao altera pagamentos, pares ou movimentos.
- A camada tecnica preserva 223 CNPJs MG; a camada analitica ativa tem 216, apos retirar seis CNPJs inaptos/baixados e a AMESP, que e associacao municipal.
- Os perfis `multifinalitario` e `multissetorial` foram unificados em `multifinalitario_ou_multissetorial`. O perfil amplo nao cria area setorial sem evidencia.
- No MIDES completo, 136 dos 161 CNPJs observados tem area classificada; 15 tem perfil amplo sem area comprovada; 8 sao consorcios sediados fora de MG; 1 esta inativo ou baixado; e 1 e entidade associativa fora do escopo.
- A documentacao do dashboard descreve regras ja executadas e limites atuais. A tabela de cobertura detalhada foi removida da documentacao para manter a leitura breve.

---

## Objetivo

Construir um painel longitudinal de participacao municipal em consorcios intermunicipais para **Minas Gerais (piloto)**, combinando evidencias fiscais, declaratorias e cadastrais.

Unidade principal:

> **par municipio x consorcio**

O sistema original de quatro categorias fixas foi substituido por uma **pontuacao acumulada por fonte**, mais adequada para combinar evidencias com graus diferentes de confianca.

---

## Produto Atual

Arquivo principal:

`outputs/csv_base/2026-05-21_painel_universal_mg_v2.csv`

| Item | Valor |
|---|---:|
| Linhas | **3.380** |
| Colunas | **32** |
| Universo cadastral | **223 consorcios MG** |
| Municipios MG | codigos IBGE em `cod_ibge_6` |
| Fontes | MIDES, SICONFI, MUNIC, CNM |
| Pontuacao maxima | **15 pts** |

Escala unificada:

| Fonte | Pontos | Interpretacao |
|---|---:|---|
| MIDES | 8 | pagamento efetivo observado via TCE/MIDES |
| SICONFI | 4 | confirmacao indireta por ano/municipio |
| MUNIC | 2 | declaracao municipal em 2015/2019 |
| CNM | 1 | vinculo na Plataforma Nacional de Consorcios |

Distribuicao principal:

| Pontos | Combinacao | Pares |
|---:|---|---:|
| 15 | MIDES + SICONFI + MUNIC + CNM | 1.037 |
| 14 | MIDES + SICONFI + MUNIC | 160 |
| 13 | MIDES + SICONFI + CNM | 813 |
| 12 | MIDES + SICONFI | 386 |
| 11 | MIDES + MUNIC + CNM | 125 |
| 10 | MIDES + MUNIC | 24 |
| 9 | MIDES + CNM | 150 |
| 8 | so MIDES | 98 |
| 7 | SICONFI + MUNIC + CNM | 26 |
| 6 | SICONFI + MUNIC | 42 |
| 3 | MUNIC + CNM | 13 |
| 2 | so MUNIC | 13 |
| 1 | so CNM | 493 |

---

## Estado Dos Scripts

| Etapa | Script | Status | Output |
|---|---|---|---|
| Diagnostico BigQuery | `00_diagnostico_bigquery.R` | concluido | diagnostico |
| Download MIDES MG | `01_baixar_mides_mg.R` | concluido | `mides_mg_atualizado.rds` |
| Painel participacao | `02_painel_participacao.R` | concluido | `painel_mg_anual.rds`, `painel_mg_participacao.rds` |
| Categorizacao antiga | `03_categorizar_mg.R` | suspenso | substituido por pontuacao |
| Pontuacao MIDES-ancorada | `04_pontuacao_mg.R` | concluido | `csv_base_mides_mg_v2` |
| Painel universal v1 | `05_painel_universal_mg.R` | concluido | `painel_universal_mg_v1` |
| Incorporacao CNM | `06_cnm_mg.R` | concluido | `painel_universal_mg_v2` |
| Auditoria externa | `07_auditoria_fora_cadastro_mg.R` | concluido | `candidatos_fora_cadastro_mg.csv` |
| Slides | `slides/scripts_viz.R` | concluido | PNGs + HTML |

---

## Fontes

### MIDES

- Fonte primaria de evidencia fiscal.
- MG no BigQuery: **2014-2021**.
- Gera `ano_entrada_proxy`, `ultimo_ano_corrente`, `n_anos_pagamento`, `ainda_ativo` e valores pagos.
- `ano_entrada_proxy = 2014` pode significar censura a esquerda, nao entrada real em 2014.

### SICONFI

- Base municipal anual.
- Periodo valido para pontuacao: **2013-2024** (`nota_cobertura = "ok"`).
- Anos 2010-2012 existem, mas foram classificados como `pre_rubrica_71`.
- 2025 foi considerado ano incompleto.
- Nao identifica o CNPJ destino; confirma indiretamente que o municipio pagou algum consorcio no ano.
- A base guarda:
  - `siconfi_confirma`
  - `anos_siconfi_match`
  - `n_anos_siconfi_match`

### MUNIC

- Dados utilizaveis em **2015** e **2019**.
- E declaratorio/autodeclarado pelo municipio.
- Edicoes posteriores investigadas nao trazem a mesma estrutura de municipio x CNPJ de consorcio.

### CNM

- Scraping completo em `C:\IPEA\dados cnm\`.
- Base usada: `base_unificada_municipio_consorcio.csv`.
- 13.119 pares municipio x consorcio na base nacional raspada.
- No painel MG:
  - **2.657 pares confirmados pela CNM**
  - **493 pares novos so CNM**
  - **135/223 consorcios MG** presentes na CNM
- CNM confirma vinculo, mas nao reconstrói historico anual pre-2014 por si so.

---

## Auditoria Fora Do Cadastro MG

Arquivo:

`outputs/auditoria/2026-05-29_candidatos_fora_cadastro_mg.csv`

Criado para preservar CNPJs e vinculos que aparecem em MUNIC/CNM com municipios MG, mas que nao entram no painel principal por estarem fora dos **223 consorcios MG** do cadastro IPEA.

Resumo:

| Item | Valor |
|---|---:|
| CNPJs candidatos | **143** |
| Pares municipio x consorcio | **843** |
| Maior caso | CONECTAR |
| CONECTAR | 414 municipios MG, sede DF |

Regra atual:

> A auditoria nao altera o painel v2. Ela serve para revisao futura do universo cadastral.

---

## Slides

Arquivo:

`slides/2026-05-14_apresentacao_ipea.html`

Estado atual:

- HTML standalone
- **14 slides reais**
- 5 PNGs principais embutidos
- 7 downloads embutidos
- CNM incorporada
- nota de auditoria fora do cadastro incluída na pagina de base de referencia

Correcoes feitas em 2026-05-29:

- removida ideia de pares com pontuacao zero no painel;
- exemplo ajustado para `Cristiano Otoni x CODAP`;
- tabela de exemplos corrigida contra CSV v2;
- CNM tratada como fonte ja incorporada;
- SICONV removido das proximas fontes visiveis;
- rotulos dos scripts 04/05 corrigidos no ultimo slide.

---

## Regras Importantes

- `ANOS` no slide = `n_anos_pagamento`.
- `n_anos_pagamento` conta anos distintos com pagamento corrente no MIDES.
- Nao e idade do consorcio nem duracao real do vinculo.
- Pares so CNM ou so MUNIC nao recebem ano MIDES inventado.
- SICONFI pontua se houver pelo menos um match nos anos de ancora, mas os anos especificos ficam guardados em `anos_siconfi_match`.
- CNPJs fora dos 223 MG ficam fora do painel principal ate revisao metodologica.

---

## Atas De Reunioes

Arquivo central:

`docs/ATAS_REUNIOES.md`

Registro atual:

- **2026-05-29:** discussao metodologica sobre temporalidade das fontes, interpretacao da pontuacao, possivel separacao de bases analiticas e papel do SICONFI como evidencia municipal indireta.

Consequencia pratica:

> A base v2 deve ser comunicada como retrato integrado de evidencias, nao como painel anual completo. SICONFI deve ser tratado como apoio/validacao por municipio e ano, pois nao identifica o CNPJ destino.

---

## Analise Tangente - Base 1 2015/2019

Pasta:

`analises/base_1_2015_2019/`

Metodologia completa:

`analises/base_1_2015_2019/METODOLOGIA.md`

Objetivo:

> criar um recorte comparavel entre MIDES e MUNIC nos anos 2015 e 2019, deixando CNM fora e reservando SICONFI para validacao financeira posterior no nivel municipio x ano.

Status em 2026-06-10:

- estrutura da frente criada;
- script `scripts/01_base_vinculos_2015_2019.R` criado e executado;
- output principal gerado em `outputs/base_1_vinculos_2015_2019.csv`;
- unidade: municipio x consorcio x ano;
- dimensao inicial: 4.046 linhas x 23 colunas;
- chave `ano + cod_ibge_6 + cnpj_consorcio` sem duplicatas.
- EDA inicial salva em `checks/EDA_base_1_vinculos_2015_2019.md` e `checks/base_1_eda_vinculos_2015_2019.xlsx`.
- Achado de EDA: 2 registros MIDES em 2019 com transacoes e `tem_pagamento_corrente = TRUE`, mas valor total zero; revisar na validacao financeira.
- Achado de EDA: 79 registros MIDES com valor positivo ate R$ 1.000; manter, mas revisar como possiveis taxas/registros residuais.
- validacao SICONFI criada em `scripts/03_validacao_siconfi_2015_2019.R`;
- output de validacao: `outputs/base_1_validacao_siconfi_2015_2019.csv`;
- resumo executivo: `outputs/base_1_resumo_executivo.csv`;
- regra de validacao revisada: comparar `valor_mides_corrente_cadastro_1194` com `valor_cons_real` do SICONFI no nivel municipio x ano, com tolerancia de R$ 10.000 ou 10%.
- motivo da revisao: SICONFI nao informa CNPJ/UF do consorcio destino; portanto, para validacao financeira, o MIDES deve considerar os 1.194 CNPJs do cadastro IPEA, nao apenas os 223 consorcios MG da Base 1.
- resultado inicial: congruencia financeira direta baixa, 14,4% em 2015 e 13,9% em 2019 entre casos com MIDES e SICONFI positivos.
- interpretacao: SICONFI e mais util como diagnostico financeiro agregado do que como confirmacao automatica de par municipio x consorcio.

Distribuicao inicial:

| Ano | Grupo | Linhas |
|---:|---|---:|
| 2015 | MIDES+MUNIC | 818 |
| 2015 | MIDES_only | 908 |
| 2015 | MUNIC_only | 166 |
| 2019 | MIDES+MUNIC | 993 |
| 2019 | MIDES_only | 1.065 |
| 2019 | MUNIC_only | 96 |

---

## Proximas Frentes Possiveis

Etapa 11 pre-2014 foi pausada por decisao de trabalho. **Nao iniciar SICONV sem nova orientacao.**

---

## Dashboard Shiny - Estado Em 2026-06-24

App publicado:

`https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/`

Pasta do app:

`dashboards/base1_shiny/`

Arquivos de dados internos ao app:

- `data/base_1_vinculos_2015_2019.csv`
- `data/base_1_validacao_siconfi_reconstruido_2015_2019.csv`
- `data/painel_mg_anual.rds`
- `data/painel_mg_participacao.rds`
- `data/cadastro_base.rds`
- `data/mides_municipios_lookup.csv`

Estado funcional:

- Base 1 continua como recorte metodologico de 2015 e 2019.
- SICONFI continua apenas como camada de validacao financeira por municipio-ano; nao cria vinculo municipio-consorcio.
- MIDES completo foi adicionado como consulta separada, usando painel anual 2014-2021 (`15.135` linhas municipio x consorcio x ano).
- Filtros da Base 1 e filtros do MIDES completo foram separados.
- Auditoria removeu a secao "Municipios com mais de um consorcio", mantendo foco em duplicidades de nome/CNPJ e nomes territoriais parecidos no mesmo municipio-ano.

Decisao de produto em 2026-06-24:

> Antes de implementar mapas, redesenhar o dashboard para ficar mais didatico, robusto e visualmente claro. A direcao escolhida e usar uma arquitetura mais proxima de produto: `page_navbar()`, paginas separadas por tarefa, `card()`/`value_box()`, filtros locais por pagina e filtros avancados em `accordion()`.

Implementacao feita em 2026-06-24:

- app refatorado de `page_fluid()`/abas simples para `page_navbar()`;
- paginas separadas: Visao geral, Base 1, MIDES completo, 2015 vs 2019, Auditoria e Definicoes;
- filtros da Base 1 ficaram dentro da pagina Base 1;
- filtros do MIDES completo ficaram dentro da pagina MIDES completo;
- comparacao 2015 vs 2019 manteve filtros proprios;
- KPIs foram reorganizados por tela;
- codigo morto da UI antiga foi removido;
- app republicado no shinyapps.io.

Proximo trabalho aprovado:

1. revisar visualmente o app publicado com a equipe;
2. ajustar textos/nomes de paginas se houver confusao;
3. depois do redesenho, implementar mapas.

Mapa MIDES implementado em 2026-06-24:

- primeira versao do mapa adicionada na pagina `MIDES completo`;
- tecnologia usada: `ggplot2 + sf + ggiraph`, nao Leaflet;
- motivo: visual mais editorial/analitico e melhor encaixe estetico com o dashboard;
- geometria municipal MG simplificada salva em `dashboards/base1_shiny/data/mg_municipios_sf_simplificado.rds`;
- fonte da geometria: cache local `geobr`/IBGE 2020;
- mapa respeita os filtros do MIDES completo: ano, municipio, consorcio/sigla, regra de valor e busca livre;
- metrica selecionavel: valor total MIDES, valor corrente, numero de consorcios e numero de transacoes;
- municipios sem registro no filtro aparecem em cinza;
- tooltip mostra municipio, valor total, valor corrente, restos a pagar, numero de consorcios, numero de transacoes e principais siglas;
- tabela de apoio lista os 15 municipios de maior intensidade no filtro atual;
- app republicado no shinyapps.io.

Ajuste do mapa MIDES em 2026-06-24:

- escala continua substituida por classes quantilicas, mais adequada a valores financeiros muito assimetricos;
- paleta substituida por sequencia azul/verde mais discreta e legivel, com cinza para municipios sem registro;
- legenda passou a usar faixas legiveis, em vez de gradiente continuo;
- contorno estadual de MG adicionado como camada visual de referencia;
- reativo `dados_mides_filtrados`, reativo `dados_mides_mapa` e `renderGirafe` passaram a usar `bindCache()` para reduzir recalculos;
- fontes Google removidas do tema e substituidas por pilhas locais (`Segoe UI`, `Georgia`, `Consolas`) para reduzir dependencia externa e melhorar carregamento;
- tentativa de baixar regioes intermediarias e regioes de saude via `geobr` falhou por indisponibilidade temporaria do servidor de dados; nao incorporar recorte territorial incompleto.

Revisao cartografica em 2026-06-24:

- mapa MIDES deixou de ser coropletico preenchendo todos os municipios;
- nova abordagem MIDES: base municipal clara com fronteiras visiveis + simbolos proporcionais nos centroides municipais;
- motivo: valores MIDES sao magnitudes absolutas; simbolos proporcionais evitam que municipios grandes parecam mais importantes apenas por area e deixam as divisas municipais legiveis;
- mapa do recorte 2015/2019 adicionado em `Recorte 2015/2019 > Mapa fontes`;
- mapa de transicao adicionado em `2015 vs 2019`;
- mapa de fontes mostra predominio territorial entre MIDES+MUNIC, so MIDES, so MUNIC e misto/empate;
- mapa de transicao mostra predominio territorial entre permaneceu, entrou em 2019, saiu apos 2015 e misto/empate;
- todos os mapas foram testados via `shiny::testServer()` e `renderGirafe`;
- app republicado no shinyapps.io.

Refino cartografico posterior em 2026-06-24:

- abordagem de simbolos proporcionais no MIDES foi descartada por baixa legibilidade visual;
- mapa MIDES voltou para coropletico classificado, mais proximo da primeira versao aprovada visualmente;
- divisas municipais dos tres mapas foram reduzidas para linhas muito finas (`linewidth = 0.018`);
- contorno estadual mantido separado e discreto (`linewidth = 0.32`);
- hover/selection dos mapas reduzido para nao engrossar as divisas;
- paleta sequencial ajustada para tons suaves azul/verde, com cinza claro para sem registro;
- mapas testados novamente com `source(app.R)` e `shiny::testServer()`;
- app republicado no shinyapps.io.

Revisao final dos mapas em 2026-06-24:

- mapas interativos `ggiraph` foram substituidos por mapas estaticos `renderPlot()`;
- motivo: referencias visuais enviadas indicam mapas estaticos limpos, e `ggiraph` estava deixando o app pesado e visualmente ruidoso;
- MIDES passou a usar coropletico continuo com escala logaritmica (`scale_fill_viridis_c(trans = "log10")`), seguindo a ideia de manter municipios pequenos visiveis em distribuicoes muito assimetricas;
- divisas municipais ficaram quase imperceptiveis (`linewidth = 0.012`) e o contorno estadual ficou discreto (`linewidth = 0.28`);
- notas dos mapas foram ajustadas para remover mencao a tooltip;
- arquivos auxiliares nao usados foram removidos da pasta `dashboards/base1_shiny/data/` para reduzir o bundle;
- deploy passou de bundle com 15 arquivos para 11 arquivos e removeu dependencia direta de `ggiraph`;
- app testado com `source(app.R)` e `shiny::testServer()` apos a mudanca.

Correcao de direcao em 2026-06-24:

- usuario esclareceu que as referencias eram para orientar a estetica, mas os mapas devem continuar dinamicos;
- mapas voltaram a usar `ggiraph`, mas sem pontos proporcionais;
- todos os mapas dinamicos agora usam coropletico preenchido com `geom_sf_interactive()`;
- geometria especifica para web foi criada em `data/mg_municipios_sf_web.rds` e `data/mg_contorno_sf_web.rds`;
- tamanho da geometria municipal usada no app caiu de cerca de 2,25 MB para cerca de 426 KB;
- MIDES usa paleta verde editorial com escala logaritmica, aproximando o visual das referencias enviadas;
- divisas municipais usam cinza fino e continuo, evitando o aspecto pontilhado/ruidoso;
- hover e selecao foram mantidos, mas com stroke discreto;
- arquivos pesados antigos da pasta do app foram removidos;
- bundle do deploy reduziu para cerca de 1,45 MB;
- app testado localmente e republicado no shinyapps.io.

Revisao tecnica em 2026-06-24:

- parsing executado nos scripts R principais, scripts da Base 1, `slides/scripts_viz.R` e `dashboards/base1_shiny/app.R`;
- app Shiny testado com `source()` e `shiny::testServer()`;
- outputs principais do app comparados com outputs da analise Base 1: dimensoes batem;
- chaves verificadas: `ano + cod_ibge_6 + cnpj_consorcio` sem duplicatas na Base 1; `ano + cod_ibge_6` sem duplicatas na validacao SICONFI;
- CNPJs do app verificados com 14 digitos apos leitura;
- bug corrigido: Rmd antigo `scripts/viz/mapas_consorcios_mg.Rmd` apontava para RDS em `outputs/`, mas arquivos reais estao em `outputs/mapas/`;
- performance corrigida: contorno estadual e centroides municipais deixaram de ser calculados no startup do app e passaram a ser lidos de `data/mg_contorno_sf.rds` e `data/mg_centroides.rds`;
- tempo de `source(app.R)` medido apos otimizacao: cerca de 8 segundos no ambiente local;
- app republicado com os novos arquivos pre-computados.

Estado atual dos mapas dinamicos em 2026-06-24:

- decisao final do usuario: os mapas devem continuar dinamicos, mas com visual limpo semelhante as referencias enviadas;
- corrigido o problema principal das divisas municipais com aparencia pontilhada/ruidosa no SVG;
- solucao final: a camada visual do mapa passou a ser rasterizada em alta resolucao com `ggrastr::rasterise()`, enquanto uma camada transparente `geom_sf_interactive()` preserva hover/tooltip;
- os tres mapas usam fundo branco puro, divisas visualmente continuas, contorno estadual separado e paletas mais discretas;
- mapas afetados: MIDES completo, composicao territorial MIDES/MUNIC e transicao 2015 vs 2019;
- aba `2015 vs 2019` foi separada em dois subitens: `Mapa` e `Tabela`;
- app testado com `source(app.R)`, `shiny::testServer()` e capturas locais via navegador headless/chromote dos tres mapas;
- app republicado no shinyapps.io em `https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/`.

Otimizacao do dashboard em 2026-06-25:

- mapas continuam dinamicos, mas passaram a atualizar por botao (`Atualizar mapa`) para evitar recalcule pesado a cada filtro;
- KPIs e tabelas continuam reagindo imediatamente aos filtros;
- selects de municipio/consorcio passaram para `updateSelectizeInput(..., server = TRUE)`, reduzindo o HTML inicial;
- CSVs usados pelo app foram convertidos para RDS sem compressao para acelerar leitura no startup;
- tabelas DT deixaram de buscar traducao por CDN e passaram a usar `dt_pt` local, com `deferRender = TRUE` e `searchDelay = 450`;
- deploy passou a usar `appFiles` explicito via `dashboards/base1_shiny/deploy_app.R`, evitando empacotar CSVs e `mg_divisas_sf_web.rds`;
- bundle publicado caiu de cerca de 2,64 MB / 15 arquivos para cerca de 1,72 MB / 11 arquivos;
- HTML inicial publicado verificado em cerca de 51 KB;
- app testado com `source(app.R)`, `shiny::testServer()` e resposta HTTP 200 no shinyapps.io.

Refino visual dos mapas categoricos em 2026-06-25:

- mapa MIDES completo foi preservado, pois a versao sequencial verde estava aprovada;
- mapas `Recorte 2015/2019` e `2015 vs 2019` receberam paletas qualitativas, mais adequadas para classes nominais;
- `Recorte 2015/2019`: MIDES+MUNIC em verde, so MIDES em roxo, so MUNIC em amarelo, misto em cinza e sem par em cinza quase branco;
- `2015 vs 2019`: permaneceu em verde, entrou em 2019 em azul, saiu apos 2015 em laranja, misto em cinza e sem par em cinza quase branco;
- divisas municipais dos mapas categoricos foram reforcadas (`linewidth = 0.16`) e contorno estadual ajustado (`linewidth = 0.35`);
- capturas locais via navegador headless foram conferidas antes do deploy;
- app republicado no shinyapps.io com bundle enxuto de 11 arquivos.

Correcao dos filtros dos mapas em 2026-07-02:

- bug identificado: ao filtrar municipio, consorcio ou busca livre, KPIs e tabelas atualizavam, mas os mapas podiam continuar exibindo o estado anterior;
- causa principal: `bindCache()` estava aplicado diretamente em outputs `renderGirafe()`, em combinacao com reativos debounced, permitindo recuperar widget antigo com chave nova;
- correcao: removido cache dos tres outputs de mapa (`mapa_mides`, `mapa_fontes`, `mapa_transicao`);
- cache foi mantido apenas nos reativos de dados filtrados e de dados agregados de mapa, com chaves separadas para MIDES, Base 1 e 2015 vs 2019;
- mapas voltaram a acompanhar automaticamente os filtros, sem botao manual de atualizacao;
- otimizacao visual/performance: camada base dos mapas voltou para `geom_sf()` vetorial direto, removendo `ggrastr::rasterise()` e a dependencia `ggrastr`;
- deploy passou a montar bundle temporario ASCII em `C:/_ideiaMides_deploy/base1_shiny`, evitando falha do `rsconnect` com o caminho acentuado `análise`;
- testes realizados: `shiny::testServer()` cobrindo municipio, consorcio e busca livre nos tres mapas; capturas visuais locais para `Betim` em MIDES completo, Recorte 2015/2019 e 2015 vs 2019;
- app republicado no shinyapps.io e verificado com HTTP 200 em `https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/`.

Auditoria matriz/filial por raiz de CNPJ em 2026-07-08:

- regra adotada para auditoria: matriz e filiais devem ser identificadas pela raiz de 8 digitos do CNPJ; a matriz normalmente tem ordem `0001` nas posicoes 9-12 e filiais usam outras ordens, como `0002`, `0003`;
- observacao: os 10 primeiros digitos tambem batiam nos exemplos analisados, mas a raiz oficial do CNPJ e de 8 digitos;
- a auditoria antiga por nome juridico capturava apenas 3 casos, pois exigia nome igual;
- nova subaba `Raiz CNPJ` adicionada ao dashboard, usando o `cadastro_base.rds` completo;
- resultado atual: 23 raizes com multiplos CNPJs no cadastro completo; 12 dessas raizes aparecem na Base 1 2015/2019;
- a tabela informa matriz, filiais, todos os CNPJs, prefixos de 10 digitos, nomes juridicos, siglas, situacoes, anos de fundacao e presenca/volume na Base 1;
- ainda nao foi feita consolidacao automatica: valores de filiais ainda nao foram somados na matriz; a nova auditoria serve para validacao antes da regra de correcao;
- dashboard republicado no shinyapps.io e verificado com HTTP 200.

Movimento anual no MIDES completo em 2026-07-09:

- usuario pediu para pular, por enquanto, a consolidacao matriz/filial por `cnpj_original -> cnpj_matriz`;
- nova subaba `Entradas/saidas` adicionada dentro de `MIDES completo`;
- unidade da analise: par `municipio x consorcio` no MIDES completo, por ano;
- regra: cada ano e comparado contra o ano anterior no proprio MIDES; 2014 e tratado como `Base inicial 2014`, nao como entrada;
- classes do mapa: `Base inicial 2014`, `Predominio permanencia`, `Predominio entrada`, `Predominio saida`, `Troca mista` e `Sem registro`;
- a visualizacao usa pequenos multiplos 2014-2021, inspirada nas referencias de mapas temporais/urban growth de Dominic Roye;
- filtros MIDES de ano, municipio, consorcio, busca livre e regra de valor tambem afetam a nova subaba;
- tabela-resumo anual separa base inicial, entradas, saidas, permanencias e municipios sem registro;
- testes realizados: `source(app.R)`, `shiny::testServer()` para filtros e resumo, `session$getOutput('mapa_mides_movimento')` para renderizacao do grafico;
- app republicado no shinyapps.io e verificado com HTTP 200.

Refino da subaba `Entradas/saidas` em 2026-07-09:

- mapa anual reformulado para ficar mais legivel: pequenos multiplos em 4 colunas x 2 linhas, titulo mais curto e area de desenho maior;
- legenda simplificada para rotulos curtos: `Inicio`, `Permaneceu`, `Entrou`, `Saiu`, `Misto` e `Sem dado`;
- legenda passou a mostrar apenas classes presentes no filtro atual, reduzindo ruido visual;
- mapa convertido para `ggiraph`, com zoom ate 5x, tela cheia e download PNG;
- camada do mapa foi simplificada para preservar performance: um `geom_sf` tematico com divisas municipais e contorno estadual, sem tooltip individual por municipio;
- tabela inferior passou a aparecer somente quando houver de 1 a 4 consorcios selecionados no filtro MIDES;
- tabela inferior ganhou expansao por linha com `+`, mostrando municipios em `Base inicial`, `Entraram` e `Sairam` por ano;
- com todos os consorcios ou 5+ consorcios selecionados, o app mostra apenas aviso orientando a filtrar antes de abrir o detalhe municipal;
- testes realizados: `source(app.R)`, `shiny::testServer()` com um consorcio selecionado, renderizacao de mapa e tabela expansivel;
- app republicado no shinyapps.io e verificado com HTTP 200.

Mapas sugeridos para etapa posterior:

1. MIDES completo 2014-2021: intensidade territorial por ano, valor e consorcio.
2. 2015 vs 2019: entrou, saiu, permaneceu.
3. Comparacao MIDES/MUNIC/SICONFI: intersecao de fontes e validacao financeira, com cuidado porque SICONFI e municipio-ano.
4. Mapa por consorcio especifico, reaproveitando a logica do CODAP.

Pesquisa detalhada salva em:

`docs/2026-06-10-pesquisa-recortes-territoriais.md`

Frentes discutidas como possiveis:

1. Regioes de Saude SUS: alta viabilidade.
2. Bacias Hidrograficas: alta/media, exige regra espacial.
3. Associacoes Microrregionais AMM: media, depende de base municipio x associacao.
4. Votos/deputados: media/baixa, exige cuidado de interpretacao.

Medida sugerida:

> coerencia territorial do consorcio = percentual de pares de municipios do mesmo consorcio que pertencem ao mesmo recorte territorial, comparado contra sorteios aleatorios de municipios do mesmo tamanho.

Proximos passos consolidados em 2026-07-20:

- criado `docs/PROXIMOS_PASSOS.md` como roteiro operacional atualizado;
- o arquivo separa estado atual, decisoes pendentes, proximas frentes priorizadas e itens pausados/fora do escopo imediato;
- prioridades atuais: validar matriz/filial antes de consolidar valores; refinar MIDES completo; iniciar recortes territoriais por Regioes de Saude SUS e Bacias Hidrograficas;
- estado atual tambem destaca os avancos dos mapas: MIDES completo, composicao MIDES/MUNIC, transicao 2015 vs 2019 e pequenos multiplos anuais de entradas/saidas no MIDES;
- itens pausados: SICONV, consolidacao automatica matriz/filial sem aprovacao, CNM dentro da Base 1 e analise de deputados como etapa inicial.

Encaminhamento da ultima reuniao - analise territorial do movimento:

- a prioridade imediata passou a ser explicar entradas e saidas no MIDES completo, e nao apenas exibi-las no mapa;
- a analise deve criar features espaciais por `municipio x consorcio x ano`: numero/proporcao de municipios vizinhos dentro e fora do consorcio, indicador de fronteira e isolamento territorial;
- a hipotese inicial e verificar se municipios de fronteira tem maior probabilidade de entrada, saida ou movimento recorrente;
- recorrencia foi definida como repeticao de mudancas de presenca/ausencia no mesmo par entre 2014 e 2021; a base deve registrar `n_entradas`, `n_saidas`, `n_transicoes` e `movimento_recorrente`;
- a tabela anual deve informar, por consorcio, municipios que entraram, sairam, permaneceram e saldo liquido;
- sera proposta classificacao setorial inicialmente desagregada, posteriormente agregada em macroareas; cada classificacao devera registrar origem e regra (`cadastro_ipea`, `MUNIC`, `MIDES/nome juridico`, regra textual ou revisao manual);
- no mapa, rotulos com nomes de municipios devem aparecer apenas em filtros restritos; a exportacao precisa ser refeita em alta resolucao, independente da visualizacao dinamica;
- mandatos municipais continuam como hipotese complementar para explicar variacao temporal dos movimentos.

Primeira entrega da classificacao por area de politica publica em 2026-07-20:

- criada a pasta `analises/classificacao_politicas/`, com rotina, taxonomia e outputs versionados;
- a classificacao tem como unidade o CNPJ de consorcio e cobre os 223 CNPJs do recorte MG;
- fontes preservadas: `setores` do cadastro IPEA, `tipo` quando originado de arquivo, setores declarados na MUNIC 2015/2019 e fallback por razao social/nome MIDES;
- a rotina separa `origem_classificacao` (fonte usada) de `fontes_evidencia_disponiveis` (todos os sinais, inclusive divergentes);
- `multifinalitario` foi definido como perfil institucional explicito, sem apagar areas detalhadas; perfis possiveis: `setorial`, `multiarea_documentada`, `multifinalitario_explicito` e `sem_classificacao`;
- resultado v0.1: 184 CNPJs classificados sem alerta e 39 para revisao humana; 28 continuam sem area identificada e nao receberam classificacao inventada;
- revisao documental v0.2 concluida para os 39 alertas: 19 confirmados, 10 ajustados e 10 mantidos explicitamente como `evidencia_insuficiente`; cada decisao, justificativa e URL esta em `analises/classificacao_politicas/inputs/revisao_documental_39_cnpjs_v0_2.csv`;
- a versao v0.2 adiciona campos finais sem apagar os automaticos: `areas_politica_final`, `macroareas_final`, `perfil_institucional_final`, `classe_analitica_final`, `origem_classificacao_final`, `confianca_final` e `necessita_revisao_final`;
- a regra matriz/filial continua fora desta entrega. Casos de filiais, como CIS Caparao e CISMEP, mantem classificacao tematica quando documentada, mas nenhum valor ou CNPJ foi consolidado;
- a classificacao ainda nao foi integrada ao dashboard nem usada em testes de movimento; primeiro devem ser consultadas fontes institucionais para as 10 pendencias e validada a taxonomia final.

Leitura da procedencia e confianca da v0.2:

- origem final dos 223 CNPJs: 80 por combinacao Cadastro IPEA + tipo de arquivo + MUNIC; 61 por MUNIC; 44 por razao social/nome MIDES; 29 por revisao documental; 9 continuam sem classificacao;
- o output final tem 125 classificacoes de confianca alta, 44 media, 49 baixa e 5 sem classificacao; esses niveis indicam qualidade da evidencia disponivel e nao equivalem a certeza absoluta;
- dentro dos 39 alertas revisados: 15 confirmacoes documentais de confianca alta, 4 confirmacoes de confianca media, 10 ajustes de confianca media e 10 casos mantidos pendentes;
- pipeline: campos brutos -> mapeamento de setores IPEA/MUNIC -> fallback textual apenas sem evidencia direta -> perfil institucional separado (setorial, multiarea ou multifinalitario) -> alerta de conflito/ausencia -> revisao documental -> campos finais; os campos automaticos nao foram apagados.
- alerta metodologico identificado na explicacao dos exemplos em 2026-07-22: estar fora dos 39 alertas nao equivale a auditoria individual. A regra automatica consolida todos os setores MUNIC observados para o CNPJ; por isso consorcios de saude como CIS/AMAPI e CISMEJE aparecem com `saude` e `residuos_solidos`. Antes de usar a classificacao como resultado final, validar se essas combinacoes refletem atividade real do consorcio ou classificacao/registro heterogeneo na MUNIC.
- auditoria da consolidacao MUNIC executada em 2026-07-22 por `analises/classificacao_politicas/02_auditar_consolidacao_munic.R`: entre 149 CNPJs com registro MUNIC, 76 tem setor unico; 15 podem usar varios setores com salvaguarda (mesma macroarea ou cobertura integral do cadastro); 58 nao devem unir automaticamente as areas MUNIC. Quatro sao prioridade alta: CIS/AMAPI, CISMEJE, CISAJE e CISVER. Em todos, `saude` aparece em 100% dos pares municipio-ano MUNIC e `residuos_solidos` aparece somente em 1 ou 2 municipios de 2015. A v0.2 nao foi alterada: a auditoria gera recomendacao e trilha de suporte antes de qualquer reclassificacao.
- classificacao analitica v0.3 concluida em 2026-07-22 por `03_consolidar_classificacao_v0_3.R`: a v0.2 foi preservada como trilha historica e a v0.3 passou a usar apenas `area_politica_final`, `fonte_principal` e `status_validacao` como campos centrais de analise. A regra MUNIC foi aplicada: combinacoes heterogeneas nao ampliam automaticamente a area final. Os quatro casos prioritarios foram confirmados como `saude` por fontes institucionais; CIMERP recebeu `defesa_consumidor; inspecao_produtos_origem_animal`; AMESP foi marcado `fora_escopo` como associacao municipal; duas filiais aguardam a decisao matriz/filial. Estado v0.3: 34 confirmadas, 94 provisorias coerentes, 15 provisorias por cadastro, 48 por nome, 23 multifinalitarios sem inferencia automatica, 6 pendentes, 2 filiais e 1 fora do escopo. Outputs principais: `classificacao_areas_politica_mg_v0_3_analitica.csv/.xlsx`, arquivo tecnico, XLSX de pendencias e `METODOLOGIA_CLASSIFICACAO_V0_3.md`.
- em 2026-07-23, a regra MUNIC foi aprovada: setor MUNIC e evidencia do vinculo municipio-consorcio, nao prova isolada de todo o escopo institucional; combinacoes entre macroareas nao sao unidas automaticamente; e a excecao de convergencia MUNIC + Cadastro IPEA foi confirmada. O script `04_gerar_amostra_validacao_munic.R` gerou a amostra fixa de 19 CNPJs em `outputs/amostra_validacao_regra_MUNIC_v0_1.xlsx` (4 prioritarios, 5 setor unico, 5 multiarea coerentes e 5 heterogeneos) para conferencia humana. A revisao de multifinalitarios, pendentes documentais e filiais permanece como proxima etapa, separada da regra MUNIC.
- em 2026-07-28, foi criado o `outputs/caderno_decisao_v0_3/caderno_decisao_classificacao_v0_3.xlsx` para leitura e decisao humana dos 188 CNPJs sem confirmacao documental plena. Ele separa 94 provisorios coerentes, 15 provisorios por cadastro IPEA, 48 por nome, 23 multifinalitarios, 6 sem area suficiente e 2 filiais sem classificacao tematica. Esses 2 nao representam o total de matriz/filial: a auditoria do dashboard detecta raizes CNPJ em universo cadastral mais amplo; o caderno destaca apenas as filiais cuja area ficou suspensa. Cada grupo tem aba de decisao enxuta; a aba `Todos os casos` preserva as evidencias tecnicas, MUNIC, cadastro, justificativa e campos de parecer.
- em 2026-07-28, decisoes do usuario foram aplicadas pela v0.4 sem sobrescrever v0.3: os 15 casos por cadastro IPEA e 48 por nome foram validados para uso analitico, mantendo a fonte original; os seis pendentes foram excluidos somente da camada ativa por estarem todos `Inapta` ou `Baixada` e serem matrizes sem outra unidade da raiz no recorte MG; as filiais Centro-CIS e ICISMEP LOG herdaram `saude` da matriz; os 23 multifinalitarios foram classificados como 19 `multifinalitario` e 4 `multissetorial` pelo nome, com `saude` somente em sete nomes/aliases MIDES explicitos. A camada ativa v0.4 possui 217 CNPJs; arquivos em `outputs/classificacao_areas_politica_mg_v0_4_*` e metodologia em `METODOLOGIA_CLASSIFICACAO_V0_4.md`. A regra matriz-filial ainda nao foi aplicada a valores MIDES ou movimentos.
- em 2026-07-28, a decisao humana seguinte validou os 94 casos `provisoria_coerente` para uso analitico. A rotina `07_consolidar_classificacao_v0_5.R` criou a v0.5 sem sobrescrever a v0.4: 217 CNPJs ativos, 34 confirmados, 94 coerentes validados, 63 validados por cadastro/nome, 7 por nome/alias setorial explicito, 16 perfis sem area, 2 filiais herdadas e 1 fora do escopo. A documentacao sintetica esta em `docs/METODOLOGIA_CLASSIFICACAO_ATUAL.md`.
- em 2026-07-28, o dashboard recebeu a secao `Documentacao`, substituindo a antiga `Definicoes`: Guia do painel, Conceitos e Classificacao de areas. A classificacao ainda nao foi usada como filtro analitico nas outras telas; a mudanca atual e de transparência metodologica.
- em 2026-07-28, o projeto passou a ter repositorio Git local inicializado. `README.md`, `docs/ESTRUTURA_REPOSITORIO.md` e `.gitignore` definem a porta de entrada, a estrutura e a separacao entre codigo/documentacao versionados e bases pesadas locais.
- em 2026-07-28, foram adicionados icones de ajuda aos 16 filtros das telas Recorte 2015/2019, MIDES completo e 2015 vs 2019. Cada icone explica o campo e seu efeito no recorte por tooltip, sem criar filtro de origem/status. O dashboard foi republicado.
- em 2026-07-28, foi criado `docs/DIARIO_DE_TRABALHO.md` como registro versionado de sessoes relevantes. O diario complementa, sem substituir, a memoria consolidada, os proximos passos e as atas de reuniao.
- em 2026-07-28, a classificacao v0.5 foi integrada a tela MIDES completo como atributo de CNPJ por `left_join`. Foram adicionados filtros de area detalhada, macrogrupo e perfil institucional. A integracao preserva integralmente as 15.135 linhas MIDES e seus valores; CNPJs sem camada ativa ficam identificados como `Sem classificacao ativa`. A regra matriz/filial continua sem consolidar valores ou movimentos.
- em 2026-07-29, o repositorio publico foi profissionalizado sob a identidade `ideiaMides | Consorcios Intermunicipais de Minas Gerais`, com slug `ideiamides-consorcios-mg`. O `README.md` passou a documentar finalidade, fontes, arquitetura, produtos, execucao e limites; foram adicionados `CONTRIBUTING.md`, `CHANGELOG.md` e template de pull request. O repositorio versiona codigo, testes, documentacao e pequenos insumos decisorios, mas nao distribui as bases pesadas. A ausencia de `renv.lock` e de licenca formal permanece registrada como limitacao de governanca.
- ainda em 2026-07-29, a identidade provisoria foi substituida por `Consorcios MG: Dados e Territorio`; o dashboard passou a usar `Painel Consorcios MG` e o GitHub foi renomeado para `consorcios-mg-dados-territorio`. Caminhos locais e nomes de arquivos historicos que contem `ideiaMides` foram mantidos para preservar compatibilidade e rastreabilidade. O app foi testado, republicado e manteve sua URL original.

---

## Movimentos Anuais E Features Espaciais - 2026-07-28

- as frentes de movimentos e fronteira foram materializadas fora do dashboard em `analises/movimentos_espaciais/`;
- a unidade e `municipio x CNPJ x ano`, exclusivamente no MIDES completo entre 2014 e 2021;
- a presenca adotada e `valor_total > 0`: o resultado descreve pagamento observado no MIDES, nao filiacao juridica formal;
- os 2.835 pares observados foram balanceados nos oito anos, formando 22.680 linhas; 673 pares tiveram duas ou mais transicoes;
- os eventos possiveis sao `base_inicial`, `entrada_observada`, `retorno_observado`, `permaneceu`, `saida_observada` e `ausente`; 2014 e apenas base inicial;
- a vizinhanca foi criada com a malha oficial geobr/IBGE 2020, nao com a geometria simplificada do dashboard; ha 2.375 fronteiras compartilhadas e os 853 municipios tem ao menos um vizinho;
- fronteira exige linha compartilhada; municipios que apenas se tocam em um canto nao sao vizinhos;
- features por par ativo: numero/proporcao de vizinhos no mesmo consorcio, fora do consorcio, indicador de borda e isolamento;
- features para saida sao observadas em `t-1`, quando o municipio ainda estava no consorcio; para entrada, foi criado universo de 18.404 candidatos externos de borda em `t-1`, dos quais 1.060 tiveram entrada ou retorno observado;
- matriz e filial continuam como CNPJs separados; MUNIC e SICONFI nao entram nesta frente;
- outputs nao foram integrados ao dashboard. O proximo passo e revisar resultados descritivos e definir o teste estatistico antes de publicar.
- EDA de validacao salva em `analises/movimentos_espaciais/EDA_RESULTADOS.md`: nenhuma falha estrutural; taxa de saida variou de 24,4% entre isolados a 3,1% com mais de 80% dos vizinhos no mesmo consorcio, e a taxa de entrada entre candidatos de borda variou de 2,4% a 29,3%; os alertas principais sao restos a pagar, valores muito baixos, matriz/filial e nomes MIDES ruidosos.

## Guia Do Modelo Espacial - 2026-08-05

- criado `docs/GUIA_MODELO_ESPACIAL_REUNIAO.md` como material de estudo e apoio para reunioes;
- o guia recompoe o processo completo: Cadastro IPEA -> consulta MIDES -> painel anual balanceado -> movimentos -> vizinhanca municipal -> indicadores em `t-1` -> universos de risco -> regressao logistica -> resultados e limites;
- a terminologia foi corrigida para `municipio pagante`, `entrada financeira observada` e `saida financeira observada`, evitando interpretar pagamento como filiacao juridica;
- o documento explica os 1.395 eventos de entrada/retorno modelados, os 418 movimentos preservados fora do modelo espacial e as 966 saidas modeladas;
- resultados centrais documentados: OR 2,22 para entrada/retorno e OR 0,79 para saida a cada 10 pontos percentuais adicionais de vizinhos pagantes; esses resultados sao associativos, nao causais;
- o exemplo Pote x CISNORJE x 2021 percorre o pipeline completo e mostra como uma observacao entra no modelo;
- a base e os scripts permaneceram inalterados; a entrega foi exclusivamente documental.
- a bibliografia do guia identifica separadamente fontes dos dados, infraestrutura espacial, metodo estatistico e literatura substantiva, deixando explicito que os trabalhos proximos motivam a hipotese, mas nao tornam o modelo atual causal.

## Esclarecimentos Metodologicos E Recorrencia - 2026-08-12

- par significa `municipio x CNPJ`, sem ano; a unidade `municipio x CNPJ x ano` e uma observacao anual;
- efeitos fixos de ano sao indicadores binarios estimados pela regressao e absorvem diferencas gerais de cada ano em relacao ao ano de referencia;
- permanecias dentro e fora entram nos modelos como resultado zero; primeiros aparecimentos de CNPJ e reaparecimentos sem territorio em `t-1` ficam fora do modelo espacial de entrada;
- o CIMVA foi conferido como exemplo aplicado: 22 municipios pagantes em 2019, 37 em 2020 e 48 em 2021; linhas reais ligam exposicao de vizinhanca, controles e resultado anual;
- recorrencia e propriedade longitudinal do par com duas ou mais transicoes em 2014-2021;
- o total longitudinal de recorrentes no resumo do consorcio esta correto; em 12/08 a coluna anual ambigua foi removida e o indicador permaneceu apenas na trajetoria do periodo;
- a nova auditoria de baixa escala identifica 23 CNPJs com no maximo dois municipios pagantes por ano, sem exclusao automatica: 12 com maximo de um, 11 com maximo de dois, 6 filiais, 11 continuos, 5 intermitentes e 7 observados em um ano;
- nenhuma base ou estimativa foi modificada; os esclarecimentos foram incorporados ao guia e ao diario.

## Padrao Permanente De Reunioes - 2026-08-12

- criado `docs/reunioes/` com indice cronologico, template e uma ata por reuniao;
- novas reunioes passam a separar decisoes confirmadas, encaminhamentos, hipoteses e pontos nao decididos;
- tarefas abertas seguem para `docs/PROXIMOS_PASSOS.md`; trabalho realizado segue para `docs/DIARIO_DE_TRABALHO.md`; mudancas concretas de patamar seguem para esta memoria;
- registrada provisoriamente como 06/08/2026 a reuniao sobre casos MIDES esparsos e universo do modelo, com data a confirmar;
- encaminhamento principal: caracterizar CNPJs de baixa escala/persistencia antes de excluir casos ou reestimar modelos;
- validacoes propostas: cadastro/nome/CNPJ, documentos institucionais, distancia rodoviaria e sensibilidades do modelo;
- nao foi aprovada exclusao automatica de CNPJs com no maximo 1 ou 2 municipios;
- SICONFI permanece sem CNPJ destinatario e nao valida diretamente o par municipio-consorcio.

## Nova Trilha CNM E Variaveis Territoriais - 2026-08-27

- Demandas encaminhadas por Paulo em 20–21/08/2026 passaram a orientar a proxima sequencia de trabalho.
- A base CNM existente em `C:\IPEA\dados cnm` e uma fotografia cadastral coletada em maio de 2026. A proxima coleta deve ser versionada e comparada com maio, nunca sobrescrita.
- `data_constituicao` e os filtros de ano da plataforma indicam a criacao do consorcio; nao reconstroem a composicao municipal anual. A lista atual de municipios nao deve ser retroagida.
- Ordem aprovada para planejamento: nova raspagem CNM; crosswalk CNM x Cadastro IPEA x MIDES; cotejamento piloto em MG; regionalizacao da saude; bacias ANA/BHO6; confirmacao da `arvore dos municipios`; piloto de tempo de viagem; associacoes municipais; integracao posterior aos modelos.
- O cotejamento devera separar `CNM+MIDES`, `somente CNM`, `somente MIDES` e `nao pareado`, distinguindo cadastro atual de pagamento anual observado.
- A hipotese preliminar para `arvore dos municipios` e a hierarquia urbana REGIC, mas a definicao precisa ser confirmada com Paulo.
- O tempo de viagem sera calculado somente depois da validacao de pares e sedes. A escolha entre rota estatica e Google com trafego previsto para sabado as 10h30 permanece pendente.
- Regioes de saude e bacias hidrograficas sao as primeiras camadas externas recomendadas por terem fontes oficiais estruturadas.
- As novas variaveis nao alteram automaticamente os modelos atuais; cada camada exigira EDA, auditoria de cobertura e validacao substantiva.
- As pendencias da camada nacional MIDES, baixa escala, classificacao e modelos foram preservadas em segundo plano.

## Primeira Entrega CNM Atualizada - 2026-08-27

- A plataforma CNM foi raspada novamente: 727 consorcios, 4.816 municipios unicos, 13.133 vinculos brutos e 13.109 pares unicos.
- O snapshot de maio foi preservado em `C:\IPEA\dados cnm\snapshots\2026-05-14`; a nova fotografia esta em `C:\IPEA\dados cnm\snapshots\2026-08-27`, ambas com manifesto e hash dos arquivos centrais.
- Entre maio e agosto houve um consorcio removido, 23 vinculos adicionados, nove removidos, uma mudanca de nome e uma mudanca de areas. O CIDS FLORESTA passou de 42 areas para lista vazia na resposta da CNM; isso exige confirmacao documental.
- Auditorias: um CNPJ invalido, nenhum CNPJ repetido, nenhum codigo IBGE invalido e 24 chaves de vinculo duplicadas, todas repeticoes idênticas em duas linhas.
- O crosswalk CNM x cadastro IPEA cobre os 727 consorcios: 655 CNPJs exatos, tres sugestoes nominais sem uso automatico e 69 nao encontrados.
- O piloto CNM x MIDES em MG gerou 28.283 observacoes anuais e 3.912 pares do periodo: 2.163 `CNM+MIDES`, 914 `somente CNM`, 658 `somente MIDES` e 177 `nao pareado`.
- Abaete x COMASF foi validado como caso real: CNPJ exato, cadastro CNM atual e pagamentos MIDES em todos os anos de 2014 a 2021.
- A marca CNM permanece fotografia de 27/08/2026; ela nao foi retroagida como filiacao historica.
- Scripts, testes, mapa, linha do tempo e metodologia foram organizados em `analises/cnm_mides/`. O proximo passo depende de validacao humana do piloto e das identidades pendentes.

## Reuniao Do Modelo Gravitacional De Saude - 2026-08-27

- A equipe definiu Minas Gerais e o setor saude como primeiro recorte da nova modelagem.
- MIDES sera a fonte longitudinal principal, interpretada como pagamento observado.
- A unidade permanece `municipio x consorcio x ano`, permitindo multiplos consorcios simultaneos; nao foi adotada escolha multinomial exclusiva.
- O nucleo gravitacional combinara capacidade de atracao do polo e impedancia por tempo de viagem.
- Antes da estimacao, o universo saude-MG sera validado com documentos e comparacao MIDES-MUNIC em 2019.
- Entrada/presenca financeira e continuidade do vinculo serao estudadas separadamente.
- Permanecem abertas a medida do valor, a forma da sobrevivencia, a definicao do polo/capacidade e o conjunto de alternativas.
- Nenhum modelo novo foi estimado; a reuniao alterou o planejamento metodologico, nao os resultados existentes.

## Universo De Consorcios De Saude Em MG - 2026-09-03

- A classificacao v0.5 identificou 100 estabelecimentos CNPJ com area explicita `saude`, `urgencia_emergencia` ou `vigilancia_em_saude`.
- A identidade por raiz de oito digitos consolidou esses estabelecimentos em 84 entidades, incorporando 16 filiais em 11 raizes.
- Sessenta e seis entidades possuem pagamento positivo observado no MIDES MG entre 2014 e 2021.
- O nucleo setorial preliminar possui 64 entidades; CISREC e Consorcio Conviver entram separadamente como sensibilidade multiarea observada.
- A situacao atual das matrizes e: 67 ativas, 13 inaptas e quatro baixadas. Situacao atual nao foi retroagida para interpretar os anos do MIDES.
- Sete entidades foram separadas para revisao de escopo, situacao temporal ou consistencia do macrogrupo; nenhuma classificacao de saude esta marcada como documentalmente pendente.
- Cinco raizes possuem mais de um CNPJ observado no MIDES e 21 chaves municipio-ano exigem soma de pagamentos entre estabelecimentos da mesma raiz.
- Codigo, testes e relatorio: `analises/modelo_gravitacional_saude/`.

## Cotejamento MIDES X MUNIC De Saude Em 2019 - 2026-09-03

- A comparacao foi feita por `municipio x entidade consolidada` em 2019,
  reunindo matriz e filiais antes do confronto das fontes.
- A uniao possui 1.311 pares: 630 MIDES+MUNIC, 658 somente MIDES e 23 somente
  MUNIC, distribuidos por 819 municipios e 66 entidades com alguma evidencia.
- Dos 653 pares declarados na MUNIC, 630 (96,5%) tambem possuem pagamento
  MIDES. Em sentido inverso, a MUNIC cobre 48,9% dos 1.288 pares MIDES.
- O valor MIDES total foi R$ 379,1 milhoes; 71,3% ocorreu em pares presentes
  nas duas fontes e 28,7% em pares somente MIDES.
- Em nivel de entidade, 61 possuem municipios em comum nas duas fontes, tres
  aparecem somente no MIDES, uma somente na MUNIC, uma nas duas fontes sem
  municipio coincidente e 18 nao aparecem em nenhuma delas em 2019.
- Os documentos do cadastro foram mantidos como apoio nao temporal: eles nao
  provam composicao municipal em 2019 sem data explicita.
- Foi criada amostra reprodutivel com os 23 casos somente MUNIC e os 27 maiores
  valores somente MIDES para a proxima revisao documental.
- Nenhum resultado foi integrado ao dashboard e nenhum modelo novo foi
  estimado.

## Revisao Documental Das Divergencias De 2019 - 2026-09-03

- Os 50 pares prioritarios foram pesquisados em fontes oficiais ou
  institucionais, com URL, ano, cobertura temporal e grau de evidencia
  preservados em catalogo versionado.
- Quatorze pares possuem evidencia anterior ou contemporanea a 2019; 33 foram
  apenas corroborados por fonte posterior; um e historicamente compativel sem
  prova anual exata.
- `Juiz de Fora x ACISPES` foi classificado como relacao financeira ou
  assistencial sem filiacao comprovada: a propria ACISPES distingue municipios
  consorciados de cidades apenas atendidas.
- `Sao Miguel do Anta x SIMSAUDE` permaneceu em revisao humana prioritaria:
  nao houve corroboracao localizada e uma fonte municipal posterior aponta
  parceria com outro consorcio.
- `Itabira x CIAS` possui evidencia oficial de 2016 e ausencia na lista atual,
  padrao compativel com mudanca temporal e nao com erro automatico da MUNIC.
- A revisao nao alterou MIDES, MUNIC, dashboard ou modelos. Fontes posteriores
  ficam em sensibilidade e pagamento nao foi convertido em adesao juridica.
- Em validacao humana, foi confirmado que pagamento MIDES deve ser tratado
  como forte indicio de relacao real, mas nao como prova juridica. O cenario
  estrito usara evidencia temporal compativel e o ampliado aceitara
  corroboracao posterior; estabilidade entre ambos sera criterio de robustez.
- A revisao humana tambem nao encontrou evidencia de `Sao Miguel do Anta x
  SIMSAUDE`; o par permanece divergente e nao confirmado.
- A CNM foi atualizada e o piloto CNM x MIDES MG ja existe, mas o marcador de
  fotografia atual ainda nao foi incluido na tabela especifica de saude de
  2019. Essa integracao e complementar e nao deve ser interpretada como prova
  historica nem bloquear a definicao do polo assistencial.
- Proximo passo metodologico: definir o polo assistencial e a medida de
  capacidade de atracao antes de integrar CNES e tempo rodoviario.

## Polo Assistencial E CNES - 2026-09-03

- O passo 3 foi concluido fora do dashboard: as 84 entidades de saude MG
  receberam sede administrativa canonica e situacao de polo assistencial.
- O CNES/DATASUS foi consultado para 100 CNPJs de matriz e filial, sem erro
  final, pelas rotas de CNPJ mantenedor e CNPJ proprio. Foram retornadas 670
  unidades diretamente vinculadas.
- A decisao e estritamente cadastral: 61 entidades possuem oferta fixa direta,
  21 nao possuem unidade direta e duas possuem somente unidades moveis. Sede
  administrativa nao foi promovida automaticamente a hospital ou rede.
- CISMAS (Itajuba, CNES 6776434) e CISMARPA (Pocos de Caldas, CNES 5796601)
  sao os dois polos fixos unicos. CIMES possui um vacimovel e fica fora da
  medida principal de distancia fixa.
- Proxima ordem recomendada: definir capacidade e agregacao das redes no CNES,
  depois calcular tempos rodoviarios ao polo ou conjunto realmente definido.

## Documentos Historicos

Arquivos antigos continuam uteis como registro de processo, mas nao devem ser usados como estado atual:

- `docs/2026-05-13-prep-reuniao-14-05.md`
- `docs/2026-05-14-registro-etapas-6-7-8.md`
- `docs/2026-05-14-boas-praticas-slides-dataviz.md`
- `slides/PROTOTIPO.md`

## Capacidade Assistencial Direta CNES - 2026-09-03

- O quarto bloco cientifico da trilha saude foi concluido fora do dashboard.
- Foram consultados ficha, leitos, atendimento e profissionais para 670
  unidades vinculadas diretamente aos CNPJs de matriz/filial: 389 fixas e 281
  moveis/itinerantes, sem erro final de modulo.
- Sessenta e uma entidades possuem capacidade fixa direta; 21 permanecem sem
  unidade direta e nao foram convertidas em zero; CIS/CEN e CIMES
  possuem somente unidades moveis e ficam sem polo rodoviario fixo.
- Cinquenta e oito das 61 entidades com oferta fixa possuem ao menos um CBO
  medico SUS ativo. Apenas o ICISMEP possui leitos SUS diretamente registrados; portanto,
  leitos nao serao usados como medida unica de atracao.
- O modelo futuro testara separadamente unidades, CBOs medicos, atendimento
  ambulatorial, SADT e leitos. Nao foi criado indice composto.
- A coleta passou a suportar cache, faixas de coleta e recuperacao apenas dos
  modulos com erro. Nomes e CNS de profissionais nao sao retidos.
- O tempo rodoviario foi integrado no passo seguinte. A cobertura complementar
  dos casos pendentes foi concluida sem imputar prestador ou capacidade.

## Tempo Rodoviario Da Oferta Fixa - 2026-09-03

- O quinto bloco cientifico da trilha saude foi concluido fora do dashboard.
- A fonte `dist_brasil.rds` do Zenodo 11400243 foi validada pelo MD5 publicado
  e filtrada para os 363.378 pares entre os 853 municipios de MG, sem rota
  ausente.
- Foram geradas tres camadas: 203.014 linhas municipio-destino, 331.817
  municipio-unidade e 71.652 municipio-entidade.
- Sessenta e uma entidades possuem tempo para unidades fixas; 21 sem unidade
  direta e CIS/CEN/CIMES permanecem com tempo `NA`.
- Redes mantem as unidades como fonte principal. Minimo, mediana e maximo sao
  resumos de sensibilidade e nao substituem a oferta por especialidade.
- A fonte usa sedes municipais IBGE 2010, assume simetria e nao considera
  transito ou partida as 10h30 de sabado.
- Proximo passo: painel `municipio x entidade x ano` e definicao do conjunto de
  alternativas plausiveis antes da estimacao.

## Painel Analitico De Saude - 2026-09-03

- O sexto bloco cientifico foi concluido fora do dashboard. A grade possui
  573.216 linhas: 853 municipios, 84 entidades consolidadas e oito anos.
- As 10.080 linhas MIDES de saude foram agregadas em 10.059 combinacoes
  municipio-entidade-ano. Vinte e uma combinacoes tinham matriz e filial na
  mesma raiz; R$ 3.101.980.422,83 foram conservados integralmente.
- O painel diferencia 1.192 estoques positivos em 2014, 426 primeiros
  pagamentos, 252 retornos, 8.188 permanencias e 533 interrupcoes. Pagamento
  continua sendo evidencia financeira, nao filiacao juridica.
- Ha 1.618 pares municipio-entidade com algum pagamento; 329 apresentam mais
  de uma transicao na janela.
- Os 843 municipios com alguma linha MIDES de saude e os dez sem linha ficam
  juntos no universo territorial completo; ausencia nao foi descartada.
- Entidades sem polo fixo continuam no painel com tempo/capacidade `NA`. Foram
  criados recortes adicionais `_com_tempo`, sem imputacao nem exclusao
  silenciosa.
- O universo estadual para entrada e apenas exploratorio. O proximo passo e
  definir alternativas plausiveis e integrar populacao, RCL, regiao de saude,
  bacia e mandato a partir de fontes anuais validadas antes da estimacao.
- Script, teste, check e metodologia: `07_montar_painel_analitico_saude.R`,
  `tests/07_validar_painel_analitico_saude.R`,
  `checks/VALIDACAO_PAINEL_ANALITICO_SAUDE_MG.md` e a metodologia unica
  `METODOLOGIA_GERAL.md`.
- A pasta passou a ter um inventario unico em `DICIONARIO_TECNICO.md` e uma
  narrativa ponta a ponta em `LINHA_DO_TEMPO_PASSOS.md`. O caso real Igarape x
  CISMEP documenta a passagem de CNPJs para entidade, evidencias, rede,
  capacidade, tempo e observacoes anuais sem alterar resultados.
- `METODOLOGIA_GERAL.md` e a unica fonte metodologica dos passos 1 a 6 e da cobertura complementar; as
  antigas notas separadas foram removidas para evitar versoes concorrentes.

## Cobertura Assistencial Complementar - 2026-09-03

- A busca CNES foi ampliada da rota de CNPJ mantenedor para a busca oficial
  pelo CNPJ proprio de cada matriz/filial. O universo passou de 639 para 670
  unidades diretamente vinculadas.
- Quinze das 36 entidades antes classificadas como sem unidade foram
  recuperadas. A cobertura fixa direta passou de 46 para 61 entidades, com
  389 unidades fixas e 281 moveis/itinerantes.
- Os 38 casos originalmente pendentes foram auditados sem imputacao: 15
  recuperados no CNES, 15 fora do universo modelavel atual, dois historicos ou
  inativos, cinco com oferta movel/indireta sem prestador fixo unico e um ativo
  sem MIDES e sem evidencia assistencial localizada.
- CISCEN possui vacimoveis diretamente cadastrados e contratos atuais de
  servicos especializados, mas a evidencia nao autoriza escolher um hospital
  unico. CIMES possui vacimovel e rede indireta com a mesma limitacao.
- CIS/UBA e a raiz `02287790` permanecem como entidades historicas: pagamentos
  MIDES sao preservados, mas elas nao entram automaticamente no conjunto atual
  de alternativas.
- Os sete alertas de escopo, situacao ou macrogrupo receberam decisao explicita
  para modelo principal, sensibilidade ou exclusao atual.
- A matriz de tempo e a capacidade foram reprocessadas: 61 entidades possuem
  oferta fixa e tempo; as demais permanecem com `NA`, nunca com capacidade
  inventada ou distancia ate uma sede administrativa arbitraria.
- Oito testes automatizados passaram. O dashboard e os modelos existentes nao
  foram alterados.
- Proximo passo: definir o conjunto anual de alternativas e temporalizar
  capacidade/prestadores antes da EDA e da estimacao.
