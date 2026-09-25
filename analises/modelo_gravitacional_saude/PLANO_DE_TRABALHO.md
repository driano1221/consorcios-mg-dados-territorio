# Plano De Trabalho Canonico - Modelo Gravitacional De Saude

Este e o **unico arquivo que define a ordem, o estado e o proximo marco** do
modelo gravitacional de saude. A metodologia explica o que ja foi feito; o
dicionario localiza arquivos; a linha do tempo ensina o percurso. Nenhum deles
deve criar uma segunda numeracao de etapas.

## Leitura Do Estado

**Foco retomado na decisão da reunião de 24/09, por orientação de Adriano.**
O exercício imediato é **transversal em 2019, saúde/MG**: pagamento positivo
no MIDES como vínculo financeiro operacional, podendo existir vários vínculos
por município; população de origem, horas SUS cadastradas e distância
rodoviária; comparação de três localizações da oferta: unidades clínicas,
sede municipal do consórcio e misto. Os 853 municípios permanecem candidatos,
inclusive com pagamento zero. O piloto de 2019 **já foi preparado, estimado e
auditado** pelos scripts 31/32/40 e testes 19/20/26. Na comparação limpa,
clínicas e sedes usam os mesmos 53 consórcios, 45.209 pares e 771 pagamentos;
sedes e misto ampliados usam os mesmos 62, 52.886 pares e 1.299 pagamentos.
Os 73 consórcios permanecem na base financeira; dez não têm horas SUS
identificadas e um tem horas clínicas iguais a zero nesse ano. Não aplicar
corte de 180 minutos, cinco vizinhos ou histórico `t−1` a este exercício.

**Teste adicional de Paulo concluído em 25/09, separado da interface.**
O script 43 divide a atração de cada consórcio pela soma dos 53/62
candidatos e usa essa fração para prever cada pagamento sem impor escolha
exclusiva. Comparou-se ao piloto binário auditado e a um controle que usa
a mesma atração sem o denominador concorrente, nas mesmas linhas e folds.
Nos oito pares recorte/validação, Brier, logloss e precisão média melhoraram;
o Brier clínico/53 caiu de 0,008886 para 0,007084 na validação municipal e
de 0,009657 para 0,007206 na espacial. Todos os 40 folds melhoraram.
O controle sem competição ficou próximo do piloto atual. Os erros concretos
e a elegibilidade institucional impedem promover esse ensaio a modelo final.
Script, teste 28, saídas e ressalvas constam da metodologia e do dicionário.
Nenhuma base v1 ou aba foi alterada.

**O que falta no escopo da reunião:** apresentar os quatro ajustes centrais
em comparação justa, seus exemplos e limites; conferir a vigência da sede
somente onde sua interpretação depender dela; não transformar cadastro CNES
em atendimento realizado nem pagamento em filiação jurídica. A normalização
literal da atração pelo somatório dos consórcios foi discutida, mas não
fechada como probabilidade de vários vínculos simultâneos. O piloto binário
original não estima essa competição. O ensaio separado do script 43 usa a
fração relativa como **indicador dentro de um logit binário**, sem chamá-la
de probabilidade multinomial de adesão. Os scripts 41/42 ficam documentados como
exploração adicional, sem orientar o próximo marco nem exigir novos documentos.

**Rodada longitudinal exploratória de 25/09 concluída, sem novos documentos.**
Scripts 41/42 e teste 27 preparam covariáveis em `t−1`, três conjuntos
geográficos de candidatos e três perguntas separadas: primeiro pagamento
observado, interrupção após pagamento e valor positivo. Foram estimadas 22
especificações (iniciais e diagnósticos posteriores), com 110 treinos por
municípios, 110 por blocos espaciais e 22 previsões de 2021 a partir dos
anos anteriores. Todas passaram na conferência independente. O recorte
estadual auditado tem 260.165 pares-ano candidatos em 2015–2021; 173
primeiros pagamentos, 208 interrupções entre 4.628 pares sob risco e 4.660
pagamentos positivos para o bloco de valor. Esses 4.660 são 49,3% das
relações pagas do núcleo no período e 83,8% do valor. Logo, os modelos
não descrevem automaticamente redes móveis, indiretas ou toda a v1.
Tempo e horas ajudam a ordenar entradas, mas não calibram bem suas
probabilidades; continuidade ganha com valor pago anterior. Cortes de
180 minutos/cinco mais próximos excluem 17/16 entradas observadas.
O passo 8 permanece **parcial**: pilotos longitudinais não fecham a regra
institucional das alternativas, a capacidade fora das clínicas, preços
nominais nem modelos finais. O passo 9 continua aberto; passo 10 não mudou.

**Continuação de 25/09 sem depender de novos documentos.** Adriano optou
por seguir com as evidências disponíveis. O script 40 reestima os quatro
recortes principais de 2019 numa sensibilidade separada: mantém São Francisco
de Paula–CISMARG (objetos SICOM sustentam o vínculo), retira apenas
Conselheiro Pena–CISVI (objetos contradizem a atribuição) e não transforma
essa linha em zero. Os 53 consórcios ficam com 45.208 pares e 770 positivos;
os 62, com 52.885 e 1.298. Comparação do original e auditado usa as mesmas
linhas e folds municipais/espaciais; métricas agregadas mudam pouco. Base v1,
piloto original, regra histórica `sem_conflito_credor` e interface não foram
substituídos. Neves/2014 permanece decisão separada para a etapa anual.
O próximo trabalho é definir e testar a elegibilidade das alternativas e
os blocos longitudinais do passo 8, com casos sem comprovação em
sensibilidade explícita. A obtenção dos documentos externos fica em espera,
por escolha de Adriano, sem bloquear esse trabalho.

**Continuação posterior: arquivos históricos recuperados no TCE/SICOM.**
Seis ZIPs conferidos; 130 linhas priorizadas, incluindo controle de
São Francisco/2018. Em São Francisco/2019, 55 lançamentos e R$ 188.969,82
conferem com MIDES e descrevem consórcio/saúde: vínculo financeiro sustentado,
nome cadastral ainda conflitante. Neves/2014: dois objetos de monitoramento
da Câmara rejeitam atribuição ao CISMEP. Conselheiro Pena mantém rejeição.
As decisões ficam separadas em `evidencias/decisoes_sicom_2026_09_25.csv`;
não houve alteração dos dados ou reestimativa. O arquivo SICOM não constitui
comprovante bancário independente. Permanecem: razão de restos Ipatinga/2018,
causa dos zeros Ipatinga e Piedade/2019 e retificação dos cadastros conflitantes.
As cinco solicitações preparadas foram reduzidas ao conteúdo ainda necessário.
Não repetir a busca dos objetos agora recuperados. QA completo do HTML segue
pendente pelo bloqueio já registrado; texto e estrutura passam por testes.

**Rodada anterior de 25/09: objetos concluídos e diferença contábil explicada.**
Conselheiro Pena: lidos os 14 objetos de 2019, R$ 11.468,66 em DCTF, ITR,
radiodifusão e acréscimos. Atribuição consorcial rejeitada na decisão derivada
do script 37; y auditado fica ausente, nunca zero inferido. Original e ajustes
anteriores preservados, com alerta e sensibilidade sem os pares conflitantes.
Ipatinga/2018: R$ 567.152,67 sem indicador de restos, iguais ao portal,
mais R$ 137.077,88 classificados como restos no MIDES. A diferença está
explicada internamente; falta confirmação externa dessa segunda parcela.
São Francisco de Paula: portal acessível, mas 2019 não retorna despesas
mesmo sem filtros. Controle 2026 funciona, sem resolver o passado.
Nenhum zero de 2019 recebeu causa financeira encerrada nesta rodada.

Aba Modelo reorganizada: formação da amostra, três cenários, comparação
municipal/espacial, calibração, quatro exemplos e conta do Igarapé–CISMEP.
Três gráficos novos em PNG/SVG; bases e estimativas preservadas.
Gráficos examinados como imagens e conteúdo conferido por testes. A política
do navegador bloqueou a abertura do HTML local: a nova navegação e o layout
completo ainda precisam de conferência humana. O QA anterior é histórico.

**Marco definido antes da coleta SICOM:** obter os documentos históricos especificados em
`evidencias/solicitacoes_financeiras_pendentes_2026_09_25.csv`. São cinco
pedidos preparados e não enviados: Neves/2014, São Francisco/2019,
Ipatinga/2018–2019, Piedade/2019 e identificação correta de Conselheiro Pena.
Não repetir a leitura dos 14 objetos nem a decomposição já encerrada.
A decisão separada de Conselheiro Pena deve acompanhar o uso analítico;
o ajuste original não é uma versão final com todos os credores validados.
Conferir também a nova apresentação no navegador; o bloqueio de abertura
local continua sem contorno, e o QA humano está pendente.

Os blocos seguintes registram os marcos anteriores.

**Estado vigente em 25/09:** correcoes propagadas para v1, atlas e interface.
Derivados anteriores preservados em snapshot. Consultorios PF excluidos do
historico e rotas refeitas; 17 pares-ano sinalizados nas duas bases e na
consulta. A aba Modelo agora abre a adesao financeira (53/62 consorcios);
o piloto fracional permanece identificado como anterior. Testes conferem
valores preservados, destinos, previsoes e interface em desktop/celular.

**Revisao documental em 25/09:** os nove casos foram examinados e
catalogados no script 36: seis zeros/2019 e tres pares com conflito de
credor. Sete receberam contexto documental, dois nao tiveram comprovante
conciliador localizado. Nenhuma causa financeira anual foi encerrada e
nenhum conflito foi resolvido. Mantidos os 17 pares-ano sinalizados e todos
os valores, resultados e graficos. Ha 17 referencias, 15 com copia local
conferida; indice web e portal indisponivel ficam explicitamente separados.

**Marco previsto antes desta consulta:** conciliacao financeira dirigida, com prioridade para
Ipatinga–CONSAUDE/2019 e Piedade–CISMIRECAR/2019 (pagamentos observados em
outros anos), e comprovantes dos tres credores conflitantes. A tabela
`evidencias/auditoria_nove_pares_2026_09_25.csv` especifica a conferencia
de cada caso. Para os demais zeros, recuperar atos e contas do proprio ano.
Nao reiniciar pesquisa geral, retroagir documentos recentes ou ajustar a
amostra para corrigir previsoes ruins. Acesso institucional, sedes historicas
e excesso de confianca em distancia zero continuam limites.

**Estado vigente apos auditoria e testes territoriais (24/09):** os dois
encaminhamentos autorizados foram executados nos scripts 33-35: auditoria
dos maiores erros e sensibilidades de alternativas. Conferidos 1.942
registros CNES de dezembro e 62.269 pares financeiros de 2019. Dois
consultorios PF estavam falsamente ligados ao CISMARG (16 registros-ano);
extrator corrigido, cenarios 31 e modelos 32 regenerados. Principais resultados
invariantes, pois os falsos vinculos tinham zero horas SUS. A versao anterior
foi preservada localmente. Ha 17 pares-ano com conflito entre nome e documento
do credor MIDES, dois em 2019: ficam marcados, com teste sem esses pares,
sem converter pagamentos em zeros. Uberaba-CISVALEGRAN/2019 tem zero
confirmado em relatorio oficial. Sete regras geograficas nos quatro ajustes
principais e sensibilidade documental passaram pelo teste 21 (320 treinos).
Nao foi adotado um corte territorial definitivo; mesma microrregiao perde
28,9% dos vinculos pagos clinicos. Detalhes ao final da metodologia.

O encaminhamento de propagar essa auditoria foi concluido em 25/09.
Os paragrafos seguintes preservam o historico das decisoes.

**Marco anterior, apos estimacao autorizada (script 32):** vinculo financeiro
binario estimado em 2019, com 853 municipios e comparacao clinicas/sedes nos
mesmos 53 consorcios. Ampliacoes sedes/misto com 62 sao exploratorias.
Doze especificacoes, validacao municipal e espacial, coeficientes com erros
agrupados por municipio/consorcio e exemplos exportados. Distancia mostra
associacao forte; horas acrescentam pouco no recorte clinico. Distancia zero
gera excesso de confianca em alguns pares; teste intramunicipal preservado
como sensibilidade posterior, sem ganho consistente. Resultados e limites
na metodologia. Naquele marco a aba visual ainda mostrava o piloto fracional.

**Encaminhamento historico apos a reuniao de 24/09:**
adesao operacional = pagamento MIDES positivo, permitindo varios vinculos
por municipio. Preparar comparacao com horas SUS cadastradas e tres destinos:
unidades clinicas fixas, sede municipal do consorcio e combinacao com sede
quando faltar unidade. A grade estadual foi aceita como cenario de candidatos,
sem provar acesso institucional. Esses sao tres cenarios espaciais da mesma
pergunta, distintos dos tres blocos longitudinais historicos deste plano.
O piloto de participacoes do script 30 permanece como resultado anterior;
nao foi convertido em modelo de adesao. Nesta atualizacao so houve leitura,
conferencia dos dados existentes e documentacao, sem nova estimacao.

O marco naquela leitura, depois executado nos scripts 31/32, era especificar o desfecho binario por par e
uma formulacao gravitacional compativel com multiplos positivos; inventariar
horas por unidade/modalidade, sedes e impedancia dos tres cenarios. A soma
normalizada entre destinos representa atracao relativa, nao automaticamente
probabilidades marginais de vinculos simultaneos. Ver a secao da reuniao de
24/09 ao final da metodologia. Ano, distancia em km versus tempo, zero
intramunicipal e agregacao de varias unidades ainda requerem especificacao.
Nao retroagir cadastro de 2026. Rever o caso CISMEP/Brumadinho em 2021 e
melhorar a legenda do grafico de cobertura como tarefas pontuais, sem reabrir
a coleta inteira. A frente documental geral corre separada do piloto de saude.

**Preparacao posterior executada (script 31):** 2019 mantido como referencia
tecnica comparavel ao piloto, sem escolher o ano por ajuste. Inventario nominal
das 73 entidades e tres grades completas, com 853 municipios cada. S1 tem
54 entidades com horas identificadas; S2/S3, 63, incluindo nove de modalidades
nao clinicas como complemento exploratorio. Dez seguem sem capacidade e
CISVAS tem zero horas: a proposta com log(H) tem 53/62/62 entidades; a grade
integral preserva todos os casos e a opcao log(1+H) mantem o zero separado.
Sedes sao referencias cadastrais, sem vigencia historica validada. Comparacao
comum de 53 entidades separa localizacao de ampliacao da amostra. S1 e S3
coincidem nessa amostra comum, portanto nao geram dois testes distintos nela.
Especificacao binaria gravitacional recomendada na metodologia, com populacao,
horas e impedancia por unidade ponderada pelas horas. Nenhuma estimacao nova.
Brumadinho/2021: serie mensal existente confirma janeiro a junho; ausencia
em dezembro explica o mapa. Causa cadastral/institucional permanece desconhecida.

- `[x]` concluido e validado;
- `[ ] Em andamento` possui produtos parciais, mas ainda nao cumpriu o criterio
  de conclusao;
- `[ ] Nao iniciado` depende das etapas anteriores.

**Estado apos o fechamento da v1 em 24/09/2026:** passos 1 a 7 concluidos
para a entrega delimitada dos dados: base financeira do nucleo de saude e
base gravitacional com oferta clinica direta cadastrada em dezembro.
Adriano autorizou simplificar: MIDES como eixo, RCL complementar e documentos
como apoio. A v1 nao representa toda a oferta indireta/movel nem define a
formula final. Preparacao do passo 8 iniciada com a avaliacao da proposta
logit de um ano. Apos autorizacao para tentar participacoes, piloto de 2019
estimado e validado no script 30. Passo 8 parcial; sensibilidades iniciais do
piloto nao encerram o passo 9. Aba local entregue; deploy do passo 10 pendente.

- [x] **1. Fechar o universo de consorcios de saude**
- [x] **2. Auditar os vinculos**
- [x] **3. Definir o polo e completar a cobertura assistencial**
- [x] **4. Construir e temporalizar a capacidade assistencial direta**
- [x] **5. Construir a camada-base de tempo rodoviario**
- [x] **6. Montar o painel analitico anual e um recorte candidato**
- [x] **7. Executar a EDA e fechar a base v1 para o recorte documentado**
- [ ] **8. Estimar os tres blocos — pilotos transversais e longitudinais exploratorios concluidos; especificacao final pendente**
- [ ] **9. Testar robustez**
- [ ] **10. Integrar resultados validados ao dashboard**

### Complementos Da Reuniao De 10/09

Estes complementos aprofundam etapas existentes e nao criam uma nova
numeracao. O fechamento assistencial do passo 3 refere-se ao recorte das 84
entidades; nao encerra a revisao de fronteira nem os mapas individuais.
Reaproveitam as bases ja materializadas:

- [x] completar a revisao fora das 84: cruzar o cadastro MG e a CNM, verificar
  candidatos em fontes oficiais e distinguir atendimento, compras, autorizacao
  estatutaria e evidencia posterior a 2021;
- [x] detalhar os mapas por consorcio, tipo e periodo; separar localizacao CNES
  de municipios pagadores e de cobertura assistencial comprovada;

**Resultado de 16/09:** 137 raizes externas triadas (122 do cadastro e 15 da
CNM), 28 revisadas documentalmente. Dez candidatas com saude historica e tres
com escopo a segregar. Nove das dez nao estavam no cadastro usado na consulta
MIDES: a consulta complementar recuperou R$ 258.359.912,14 em 2014-2021.
Revisao concluida nas fontes consultadas, sem afirmar censo exaustivo de MG.
O atlas local permite escolher entidade, ano, funcao e tipo CNES; distingue
pagadores anuais e composicao CNM atual. As 221 entidades do inventario nao
sao uma amostra de 221 consorcios de saude.

- [x] comparar as 18 entidades cadastrais sem MIDES com as 66 observadas,
  distinguindo abertura posterior a 2021, situacao cadastral, estrutura CNES e
  possivel selecao do universo financeiro;
- [x] verificar em fontes oficiais a atuacao efetiva de CISREC e CONVALES e
  manter separadas classificacao institucional, oferta CNES e pagamentos;
- [x] produzir mapas diagnosticos dos consorcios e estabelecimentos por tipo,
  sem tratar pagamento, composicao juridica e cobertura assistencial como a
  mesma area;
- [x] registrar o que a evidencia sustenta e o que permanece para decisao da
  equipe, sem repetir a coleta CNES ou a triagem dos 91 casos entidade-ano.

## Ordem Canonica

### 1. Fechar O Universo De Consorcios De Saude

- [x] listar os CNPJs classificados como saude;
- [x] consolidar matriz e filiais pela raiz de oito digitos;
- [x] identificar ativos, baixados e casos duvidosos;
- [x] verificar quais entidades aparecem no MIDES.

**Produto validado:** 100 CNPJs consolidados em 84 entidades, das quais 66
aparecem no MIDES de Minas Gerais.

### 2. Auditar Os Vinculos

- [x] comparar MIDES 2019 com MUNIC 2019;
- [x] revisar documentalmente 50 divergencias prioritarias;
- [x] manter pagamento, declaracao e filiacao juridica como evidencias distintas;
- [x] preservar a CNM como fotografia atual, sem retroagir sua composicao.

**Produto validado:** 1.311 pares municipio-entidade em 2019, sendo 630 comuns,
658 somente MIDES e 23 somente MUNIC.

### 3. Definir O Polo E Completar A Cobertura Assistencial

- [x] consultar unidades CNES pelo CNPJ mantenedor e pelo CNPJ proprio;
- [x] separar polo fixo, rede, oferta movel e ausencia de unidade direta;
- [x] auditar os 36 casos sem unidade direta e os dois casos inicialmente moveis;
- [x] decidir os sete alertas de escopo, situacao ou macrogrupo;
- [x] registrar 56 decisoes anuais para as cinco entidades indiretas/moveis e
  as duas historicas; recuperar polos cadastrais historicos sem retroagir 2026;
- [x] registrar exclusao/sensibilidade para os dois casos historicos sem
  prestador ou sucessao comprovados; preservar os pagamentos;
- [x] classificar os 91 casos entidade-ano, distribuidos em 28 entidades, com pagamento e sem unidade fixa
  direta em: rede documentada, oferta movel, ausencia cadastral, exclusao ou
  sensibilidade.
- [x] corrigir 307 unidades moveis indevidamente classificadas como fixas no
  snapshot atual e regenerar capacidade, tempo e grade preliminar;
- [x] distinguir destinos clinicos de centrais de gestao/regulacao, farmacia,
  vigilancia e telessaude nas estruturas nao moveis atuais e historicas;
- [x] resolver duas fichas atuais com nome/tipo conflitante ou ausente;
- [x] completar a pesquisa documental individual das entidades nao prioritarias
  e registrar exclusao/sensibilidade quando a fonte nao identifica vigencia,
  prestador e endereco suficientes para o modelo.

O dossie encerra a triagem dos 91 casos, nao comprova oferta para todos eles:
59 possuem registro fixo posterior; 3 possuem fixa em outros meses do mesmo
ano; 12 pertencem aos dois casos historicos; 5 sao planejamento CISVALES;
1 possui regulacao SAMU documentada em 2021; 11 seguem sem polo suficiente.

O fechamento funcional classificou as 670 unidades atuais em 63 destinos
clinicos fixos, 20 estruturas fixas nao clinicas e 587 unidades moveis, sem
pendencia residual. Na serie historica, as 1.868 unidades-ano se dividem em
398 destinos clinicos fixos, 74 estruturas fixas nao clinicas e 1.396 moveis.
A auditoria documental das 21 entidades nao prioritarias confirmou redes,
implantacoes e servicos moveis em parte dos casos, mas nao autorizou imputar
prestadores ausentes. Tambem revelou o CIMBAJE como terceiro caso multiarea
documentado, alem de CISREC e CONVALES.
O CISPARA recebeu alerta estatutario desde 2017; autorizacao multifinalitaria
nao foi tratada como prova de pagamentos para outras politicas.

**Criterio para concluir:** todo caso entidade-ano relevante tera polo/rede
documentado ou uma decisao explicita de exclusao/sensibilidade. Nao e necessario
inventar um hospital para preencher todos os vazios.

### 4. Construir E Temporalizar A Capacidade Assistencial Direta

- [x] extrair unidades, leitos, servicos e profissionais do CNES;
- [x] evitar somar hospitais de terceiros sem ligacao comprovada ao consorcio;
- [x] reconstruir a oferta diretamente vinculada de 2014 a 2021;
- [x] manter capacidade ausente, em vez de zero, quando nao ha unidade fixa.

**Produto validado:** 672 entidades-ano, 1.868 unidades-ano em dezembro e 120
arquivos oficiais auditados. A capacidade indireta que vier a ser comprovada no
passo 3 sera uma camada separada, nao uma alteracao retroativa deste resultado.

### 5. Construir A Camada-Base De Tempo Rodoviario

- [x] integrar a matriz OpenStreetMap/OSRM publicada pelo projeto Distbrasil;
- [x] calcular tempo de 853 municipios ate 82 estruturas fixas candidatas
  (63 municipios de destino; classificacao corrigida em 10/09);
- [x] preservar minimo, mediana e maximo quando uma entidade possui rede;
- [x] deixar sem tempo os casos sem destino fixo documentado.

**Produto validado:** camada estatica e simetrica de impedancia para 61 entidades
com oferta fixa direta. A ligacao anual ao conjunto final de alternativas sera
feita no passo 6.

### 6. Montar O Painel Analitico Anual

- [x] materializar a grade preliminar municipio x entidade x ano;
- [x] calcular pagamento, primeiro pagamento, permanencia, retorno e interrupcao;
- [x] preservar a censura dos pagamentos ja existentes em 2014;
- [x] harmonizar as dez candidatas externas e os tres casos de escopo misto
  com as regras de amostra; completar capacidade LT/SR/PF e presenca mensal
  somente para as entidades que entrarem, reaproveitando os arquivos brutos;
- [x] materializar conjuntos candidatos por municipio e ano; plausibilidade
  institucional nao demonstrada para todos os pares, a validar na especificacao;
- [x] comparar tres regras: todos os consorcios de saude de MG, limite de tempo
  rodoviario e mesma regiao de saude;
- [x] integrar populacao, RCL disponivel, PDR/2019 como referencia a partir de
  2019 e ciclo do mandato; manter ausencias explicitas;
- [x] ligar capacidade historica, tempo e decisoes do passo 3 sem vazamento
  temporal;
- [x] definir os universos sob risco de entrada, intensidade e interrupcao.

**Produto do passo 6:** a grade original de 573.216 linhas permanece intacta. A
integracao anual de 23/09 contem 661.928 linhas (853 municipios x 97 entidades
x 8 anos), incluindo separadamente as 13 candidatas externas. O CNES clinico e
o tempo agora pertencem ao proprio ano; o teste conserva os R$ 3,102 bilhoes
originais. Populacao cobre 853 municipios em cada ano. A consulta RREO/Anexo 03
recuperou RCL para 160 a 270 municipios por ano em 2015-2021, sem retorno em
2014. O PDR/2019 fornece mapa das 66 microrregioes apenas como referencia de
2019-2021. As regras de alternativas e de risco ja estao materializadas como
diagnosticos. A especificacao candidata usa oferta clinica direta de dezembro
com tempo historico conhecido, sem corte arbitrario de minutos. Para entrada,
retorno e interrupcao, o tempo e a capacidade elegiveis sao os de `t-1`;
para intensidade, sao os do ano do pagamento. Em 2019, 781/1.513 pares pagantes
e 82,8% do valor pago permanecem no recorte direto; 90 minutos deixariam
630 pares. Os 90/120/180 minutos e a mesma microrregiao ficam para sensibilidade.
Bacia hidrográfica foi adiada por decisao de Adriano para analise territorial
posterior, sem bloquear o modelo de saude. RCL incompleta e mapa regional
anterior a 2019 nao sao imputados; o passo 7 medira as perdas e avaliara
a especificacao antes da estimacao.

### 7. Executar A EDA E Avaliar A Suficiencia Dos Dados

- [x] quantificar zeros, entradas, permanencias, retornos e interrupcoes nos
  universos finais;
- [x] examinar alternativas por municipio e tempos extremos;
- [x] identificar entidades sem medidas CNES SUS positivas;
- [x] verificar censura, perdas por pareamento e cobertura das variaveis;
- [x] comparar os conjuntos de alternativas, sem fixar ainda o principal.
- [x] inventariar todas as 60 variaveis por ano e universo, incluindo nulos,
  vazios, zeros, distribuicoes e verificacoes de integridade;
- [x] classificar as lacunas de polo por entidade-ano e distinguir falta de
  registro no painel de evidencia documental ja existente;
- [x] conferir os extremos financeiros na fonte, preservar o registro de valor
  zero e fornecer nomes de exibicao para as cinco raizes sem sigla;
- [x] indexar produtos e registrar fontes, limites temporais e hashes da conciliacao;
- [x] explicitar quais recortes e variaveis sustentam cada pergunta empirica,
  com perdas e ressalvas: duas bases v1, sem declarar formula/amostra universal;
- [x] gerar CSV/RDS, dicionario de 30 variaveis, registro das 776 entidades-ano,
  perfis de capacidade/modalidade, correlacoes e exemplo real de oito anos;
- [x] conferir conservacao financeira, chaves, zeros, horas e hashes das fontes.

As estatisticas preliminares dos passos anteriores foram confrontadas nesta
EDA com os extratos financeiros, o CNES historico e a matriz rodoviaria.

EDA diagnostica em 24/09: os 1.513 pares pagantes de 2019 se repartem em 781
com tempo clinico direto, 595 no nucleo cadastral sem polo direto e 137 fora
do nucleo. O tempo mediano nos 781 e 52,7 minutos; o percentil 95 e cerca de
143 minutos. Ha 45.281 zeros nas 46.062 alternativas diretas de 2019.
Nos conjuntos de risco com tempo em `t-1`, 2015-2021 somam 181 primeiros
pagamentos, 67 retornos e 216 interrupcoes. A raridade das entradas devera
orientar a especificacao futura, sem estimar regressao nesta etapa.
Os 19 registros acima de 300 minutos correspondem a seis pares repetidos em
anos diferentes, R$ 1.059.868,20 (0,037% do valor do recorte direto de oito
anos). Valores e transacoes conferem com os extratos MIDES; tempos e distancias
conferem com a matriz rodoviaria. Nenhum foi excluido. Essa verificacao nao
prova viagem de pacientes.

Em 2019, 90/120/180 minutos conservariam 630/708/762 dos 781 pagadores
diretos e deixariam 151/70/21 municipios sem opcao; mesma microrregiao do
PDR/2019 conservaria 558 e deixaria 156 municipios sem opcao. A regra sem
corte preserva todas as 853 origens e e o recorte direto candidato. RCL existe para
241 dos 781 pares diretos pagos; nesse grupo, a populacao mediana dos pares com
RCL e 13.828, contra 7.098,5 nos sem RCL. Portanto, sua falta nao parece
aleatoria e ela nao sera controle obrigatorio do modelo de oito anos.

A escassez de leitos SUS ja constava da memoria: na fotografia atual,
somente CISMEP tinha 32; no historico direto, apenas a raiz Alto Sao Francisco
`64486822` tinha 26 em dezembro de 2014-2016. Entre as 54 entidades diretas
de 2019, nenhuma tinha leito SUS registrado. Isso confirma que leitos nao
podem ser a massa unica, sem escolher agora a formula da equipe.

Uma segunda auditoria distinguiu tipo clinico CNES de marcador SUS. Em 2019,
quatro unidades-ano clinicas nao tinham vinculo, leitos, servicos nem
profissionais SUS registrados: uma do CISVAS e tres do CISMARG. Exigir algum
marcador retiraria dez pares pagantes do CISVAS (R$ 1.465.922,21) e aumentaria
o tempo em seis pares do CISMARG (R$ 624.809,36). Em 2020, 18 pares (R$
4.963.224,00) pertencem a duas entidades com vinculo SUS informado, mas sem
capacidade SUS positiva nos modulos coletados. Esses casos permanecem no
painel principal cadastral e foram separados em sensibilidade; zero cadastral
nao foi interpretado como ausencia de atendimento.

### 8. Estimar Os Tres Blocos

**Encaminhamento recebido em 24/09:** foi apresentado pedido de um piloto
logit multinomial, em um unico ano de saude/MG, com atracao por capacidade
ou populacao da sede e impedancia espacial. A compatibilidade foi examinada
no script 29, inicialmente sem estimar. Em seguida, foi autorizada a tentativa
de participacoes com profissionais e tempo em 2019 e sua explicacao numa nova
aba. Script 30 executado: 703 municipios, 54 alternativas estaduais cadastrais,
37.962 linhas. O cenario amplo e exploratorio, sem prova de acesso institucional.
O piloto transversal nao substitui os blocos longitudinais abaixo nem mede
nova adesao juridica. Metodo, perdas, resultados e validacao na metodologia.

- [x] estimar piloto fracional de 2019 com peso municipal igual;
- [x] comparar tempo, profissionais, horas e tempo mediano; validar por
  municipios e grupos geograficos, sem vazamento das respostas dos grupos;
- [x] explicar selecao, transformacoes, matematica e exemplos na aba local;

- [x] definir adesao operacional como pagamento positivo, permitindo varios
  vinculos por municipio (esclarecimento de Adriano apos reuniao de 24/09);
- [x] preparar inventario, rotas, grades e especificacao recomendada para
  unidades/sedes/misto com horas SUS em 2019 (script 31); teste 19;
- [x] estimar o desfecho binario, reportando premissas propostas de ano,
  impedancia, zeros/agregacao, vigencia das sedes e modalidades de capacidade;
- [x] comparar amostra comum e ampliada sem atribuir ganho de cobertura a
  melhora do modelo (script 32); validade institucional permanece limitada;
- [x] reestimar quatro recortes de 2019 com decisão SICOM dirigida, preservando
  originais e comparando as mesmas linhas (script 40; teste 26);
- [x] preparar riscos em `t−1` e estimar pilotos exploratórios de primeiro
  pagamento, interrupção e valor positivo, com versões original/auditada/
  estrita, três conjuntos geográficos e validações municipal, espacial e
  temporal (scripts 41/42; teste 27);
- [ ] validar elegibilidade institucional e vigencia das sedes relevantes;
  recuperar sede nao recupera automaticamente capacidade;
- [ ] distinguir presenca anual do vinculo de evento de primeiro pagamento;
  a extensao de novas adesoes mencionada na reuniao nao foi executada.
- [ ] versao final da entrada: logit ou risco discreto, apos definir alternativas;
- [ ] versao final da intensidade: PPML ou modelo hurdle com tratamento de precos;
- [ ] versao final da interrupcao/permanencia: sobrevivencia em tempo discreto.

Os tres modelos respondem perguntas diferentes e nao devem ser fundidos em uma
unica regressao.

### 9. Testar Robustez

- [x] no piloto binario: km/tempo, escala da distancia, minimo/ponderacao,
  horas zero, exclusao de alertas temporais, retirada das horas e distancia
  intramunicipal; validacao espacial dos quatro ajustes principais;
- [ ] variar as medidas de capacidade;
- [ ] variar os conjuntos de alternativas;
- [ ] comparar pagamento bruto, per capita e proporcional a RCL;
- [ ] comparar cenarios documental estrito e ampliado;
- [ ] usar MUNIC e CNM como verificacoes complementares.

### 10. Integrar Resultados Validados Ao Dashboard

- [ ] publicar metodologia, exemplos e resultados validados;
- [ ] manter o modelo espacial anterior identificado como exploratorio;
- [ ] testar todas as telas e exportacoes antes do deploy.

## Proximo Marco

**Próximo:** apresentar lado a lado o piloto binário auditado, o controle
sem competição e o ensaio relativo de 2019, mostrando os acertos e os erros
reais. Com Paulo e a equipe, decidir quais consórcios eram alternativas
institucionalmente plausíveis para cada município e como verificar sedes
históricas. Só então considerar uma nova sensibilidade ou a inclusão do
resultado na aba, preservando o piloto atual.

**Teste delimitado da ideia de Paulo, concluído sem alterar a aba:** manter
os quatro ajustes binários auditados de 2019 como referência e não alterar
a aba Modelo. Nos mesmos pares e cinco folds municipais/espaciais, calcular
atração relativa de cada consórcio a partir de horas SUS por unidade e
distância rodoviária. Para várias unidades, somar a atração de cada ponto,
ponderando suas horas; na sede, concentrar as horas no município sede.
O denominador inclui **todos os 53 ou 62 candidatos do cenário**, inclusive
pares com pagamento zero e o par cujo credor ficou indeterminado na auditoria;
apenas sua resposta fica fora da estimação. A população da origem cancela
nessa fração, mas pode entrar separadamente na chance binária de pagamento.
Estimar os expoentes de capacidade e distância somente no treino; comparar
as previsões fora do treino com o logit existente **na mesma amostra**.
Relatar logloss, Brier, precisão média, calibração, casos concretos e
sensibilidade por cenário. Fração normalizada é atração relativa, nunca
uma filiação observada ou, sozinha, uma probabilidade de vínculo. Publicar
resultados em produto separado; não escolher a nova forma apenas por uma
métrica e não sobrescrever v1, modelos anteriores ou interface. O script 43
e o teste 28 executaram esse protocolo.

**Prioridade atual após a releitura da reunião:** fechar a apresentação do
piloto binário de 2019 já estimado. Usar `outputs/adesao_financeira/amostras.csv`,
`validacao.csv`, `coeficientes.csv` e a sensibilidade auditada do script 40.
Mostrar primeiro clínicas versus sedes nos mesmos 53; depois sedes versus
misto nos mesmos 62. Explicar a formação dos recortes a partir dos 73, o
sentido de cada zero e um exemplo como Igarapé–CISMEP. Reportar que horas
SUS são capacidade cadastrada, que as sedes são aproximações cadastrais e
que a distância zero não mede viagem porta a porta. Nenhum novo ajuste ou
coleta é necessário para executar essa apresentação. Os modelos anuais e os
recortes geográficos dos scripts 41/42 são extensões opcionais futuras.

**Marco anterior após scripts 41/42:** não promover um conjunto geográfico ou piso
intramunicipal a regra final por desempenho. Apresentar o recorte direto,
as perdas e a calibração imperfeita; depois estudar elegibilidade institucional
e capacidade das modalidades móveis/indiretas como frente separada, se houver
evidência disponível. Para valor nominal, definir deflator ou limitar a
interpretação temporal; para interrupção, distinguir ausência observada de
saída jurídica. Pedidos externos continuam em espera. O dashboard aguarda
resultados finalizados e QA visual.

### Protocolo Fixo Para A Rodada Longitudinal Exploratória

Este protocolo foi definido após conferir viabilidade e antes de estimar os
novos modelos. A unidade continua município × consórcio × ano, 2015–2021;
2014 fornece histórico e atributos anteriores, mas nunca uma entrada datada.
Fonte financeira: v1 de 73 consórcios do núcleo de saúde. A amostra com
atributos gravitacionais exige clínica fixa direta, horas SUS positivas e
tempo no **ano anterior**. Por isso não representa redes móveis/indiretas.

1. **Alternativas predeterminadas em `t−1`:** todos os consórcios com esses
   atributos em MG; até 180 minutos; cinco menores tempos por município
   (incluindo empates). Os filtros não usam o pagamento de `t` nem reincluem
   positivos após observar a resposta. Relatar pagamentos e origens perdidos
   antes de qualquer comparação; não escolher regra por melhor métrica.
2. **Três perguntas separadas:** primeiro pagamento observado entre pares sem
   positivo prévio; continuidade entre pares pagos em `t−1`; log do valor
   nominal entre pagamentos positivos em `t`. Retornos não são primeiras
   entradas. Capacidade, tempo e população vêm de `t−1` em todos os blocos.
3. **Versões:** MIDES original versus auditada. Na auditada, Neves–CISMEP/2014
   e Conselheiro Pena–CISVI/2019 são indeterminados, nunca zeros inventados;
   São Francisco–CISMARG/2019 permanece positivo. Um histórico anterior
   indeterminado exclui o par do risco de primeira entrada até haver positivo
   confirmado. Descrever a diferença de amostra antes das métricas.
4. **Comparações predefinidas:** referência de população e tendência anual
   versus essas variáveis mais horas e tempo. Para continuidade, testar ainda
   o valor pago em `t−1`. Validar por municípios não vistos e, em separado,
   treinar em 2015–2020 para prever 2021. Comparar cada modelo com uma
   prevalência/média aprendida apenas no treino.
5. **Interpretação:** Brier/logloss para eventos e erro em log reais para
   valor; contar eventos e perdas por versão, ano e alternativa. Métricas de
   filtros diferentes têm denominadores diferentes e não demonstram qual
   conjunto é institucionalmente correto. Valor é nominal e condicionado a
   pagar; nenhum coeficiente será chamado de efeito causal ou adesão legal.

Após a primeira rodada, a inspeção dos 17 alertas já existentes motivou
uma **terceira sensibilidade, posterior ao protocolo inicial**: deixar
indeterminados os 16 pares-ano com nome/documento conflitante ainda sem
comprovação anual, preservando São Francisco–CISMARG/2019, já sustentado
pelos objetos. Ela não é uma nova verdade nem será escolhida pela métrica.
O diagnóstico posterior também compara substituições arbitrárias de 5/15/30 min
somente para viagens intramunicipais registradas como zero pela matriz, apenas no
bloco de primeiro pagamento. O exercício identifica a sensibilidade à
convenção de tempo zero; não observa o tempo real dentro do município e
não seleciona um piso pelo desempenho de 2021.
Como robustez adicional, repetir a validação dos mesmos modelos nos cinco
blocos espaciais já fixados pelo piloto de 2019. Os blocos não têm zona de
separação; isso mede transferência entre grupos geográficos, não outro ano.

**Marco histórico após a sensibilidade SICOM:** avançar na elegibilidade das
alternativas e nos blocos longitudinais de vínculo financeiro. Ao usar 2014,
aplicar a decisão de Neves–CISMEP como desfecho indeterminado, não zero.
Manter os casos sem prova documental em análise de sensibilidade, sem esperar
novos comprovantes para prosseguir. A v1 e os modelos de 2019 permanecem
exploratórios; publicação no dashboard vem somente após validação.

**Marco histórico apos o script 32:** levar os resultados binarios e suas limitacoes
para a aba do modelo, distinguindo-os do piloto de participacoes, e corrigir
a comunicacao da cobertura. Antes de promover a modelo final: aprofundar
elegibilidade institucional, calibracao intramunicipal e capacidade por
modalidade; conferir sedes historicas conforme relevancia. Nao ampliar o
modelo apenas porque a amostra maior cobre mais dinheiro. Inventario
documental geral segue como frente complementar.

**Prioridade anterior a reuniao de 24/09, apos piloto autorizado:** discutir os
resultados e a disponibilidade institucional das alternativas. Tempo tem
associacao forte com a distribuicao; profissionais acrescentam ganho pequeno
na validacao. Proximas sensibilidades substantivas: alternativas documentadas
e capacidade anterior ao pagamento. Nao promover o cenario amplo a modelo final.
Entrada local: `outputs/visuais_v1/index.html#modelo`, setima aba, com selecao
97 -> 73 -> 54, municipios 853 -> 703, variaveis, pipeline, previsoes de todos
os municipios e matematica. As seis abas anteriores e as fontes v1 permanecem.

Execucao visual iniciada em 24/09 com design-vault. A primeira previa,
`outputs/visuais_v1/prototipo/index.html`, foi rejeitada por Adriano: a
leitura do vault e a proposta visual precisavam de maior profundidade.
Apos leitura integral das 16 notas de design e inspecao das referencias,
a segunda proposta esta em `outputs/visuais_v1/proposta_02/index.html`:
leitura guiada dos pagamentos/cobertura, atlas CISMEP com oito anos reais
e especificacao dos seis blocos da entrega. Essa proposta navegavel foi
avaliada antes da implementacao geral, conforme a skill. Adriano aprovou a segunda proposta e
autorizou a entrega completa, incluindo revisao visual durante a execucao.
Os rascunhos ficam como historico; a entrada vigente e `visuais_v1/index.html`.

**Primeira entrega visual, preservada como historico:**

- [x] revisar o pedido da reuniao, os mapas existentes e sua coerencia com a v1;
- [x] ajustar as legendas de universo/data e os textos antigos de status do
  atlas; preservar a distincao entre pagadores, CNM atual e unidades CNES;
- [x] mostrar unidades por consorcio, ano, funcao e tipo, reaproveitando o atlas;
- [x] comparar capacidade separadamente (unidades, profissionais, servicos e
  horas), usando uma linha por entidade-ano; destacar CISREC, CONVALES e CIMBAJE
  em comparacao auxiliar, sem inclui-los silenciosamente no nucleo v1;
- [x] apresentar evolucao/ranking dos pagamentos observados e cobertura dos
  recortes, com valores nominais, denominadores e perdas explicitos.
- [x] representar tempos das 5.612 relacoes pagas diretas, curva acumulada,
  comparacao por consorcio e tabela de extremos, sem exclusoes silenciosas;
- [x] conferir fontes, totais e exportacoes; registrar reproducao nos scripts
  26 a 28 e validacao no teste 17, alem da integridade da v1 no teste 16.

**Revisao solicitada depois da primeira entrega, executada em 24/09:**

- [x] concentrar a interface na v1; retirar CNM, retrato 2026, entidades
  externas e comparacao multiarea da navegacao vigente;
- [x] explicar variaveis, periodos, nulos, zeros, primeiras linhas reais
  e construcao por fluxos, com detalhamento das ligacoes do CNES;
- [x] disponibilizar as duas bases completas, todas as colunas e filtros
  por ano, municipio, consorcio e pagamento, em paginas de 25 linhas;
- [x] remover botoes de download, autoria e data de elaboracao dos rodapes;
  preservar fontes e competencias dos dados;
- [x] conciliar todas as celulas das tabelas consultaveis com a v1 original
  e verificar filtros, navegacao, mapas e leitura em tela estreita.

Depois desse retrato visual, confrontar a formula com os dados e justificar
os pares/zeros antes de estimar. Os mapas descritivos continuam uteis mesmo
sem amostra de estimacao aprovada; nao comprovam filiacao ou atendimento.

**Passo 7 encerrado para a v1 delimitada**, por autorizacao de simplificacao
de Adriano em 24/09. As 181 entidades-ano pagas sem polo direto estao
conciliadas em tabela separada, com classificacao, fonte e limite: 57 de
oferta movel/regulacao/transporte, 21 anteriores a operacao regional SAMU,
28 de redes indiretas/programas, seis de cadastro intrano ou posterior,
12 historicas e 57 demais casos sem destino clinico suficientemente documentado.
Os 5.123 pares e R$ 450.467.803,61 foram preservados. Classificar todos os
casos nao recuperou prestadores fixos anuais nem completou os dados assistenciais.

Os tres trabalhos seguintes foram executados em 24/09, dentro do passo 7:

- [x] Aprofundar CIAS/2016-2020, Circuito/2017 e CONSARDOCE/2014-2021:
  14 decisoes complementares, 172 pares pagos e R$ 63.840.806,52 examinados.
  Contratos SAMU do CIAS e unidade municipal do Circuito foram identificados;
  prestadores historicos do CONSARDOCE continuam sem confirmacao.
- [x] Delimitar necessidade mensal: 58 unidades-ano em 53 entidades-ano
  prioritarias; seis fotografias de capacidade extraidas para cinco unidades.
  Isso nao constitui a serie mensal completa nem media anual.
- [x] Medir e documentar a suficiencia dos recortes: 10.735 pares-ano pagos
  de saude, 5.612 diretos, 1.052 diretos com RCL e 510 com RCL e PDR.
  Os recortes fiscais sao seletivos e nao definem a amostra final.

**Marco anterior a reuniao de 24/09:** discutir o piloto de distribuicao do gasto ja executado,
seu ganho modesto com capacidade e a regra das alternativas. Os resultados
e as perdas estao em METODOLOGIA_GERAL.md; amostra derivada separada da v1.
Em um so ano, a deflacao por indice comum nao muda participacoes nem ranking.
Para retornar a comparacoes monetarias entre anos, reabrir a deflacao.
O piloto de participacoes foi autorizado; novos desfechos nao sao uma
consequencia automatica dessa autorizacao. Nao ampliar coleta sem necessidade
especifica. A base gravitacional conserva alternativas sem pagamento, sem
limite arbitrario de minutos e sem exigir RCL/PDR.

**Pendencias registradas, nao bloqueadoras da v1:** prestadores historicos do
CONSARDOCE, acesso municipal ao CEAE/Circuito e serie mensal completa. As
53 prioridades temporais continuam documentadas; 45 entidades-ano pertencem
ao recorte direto v1 e recebem alerta. Para esta entrega, a capacidade mede
dezembro, nao media anual. Esses casos so reabrem se a pergunta requerer
rede indireta, acesso contratado ou capacidade ao longo de todo o ano.
Uma comprovacao nova de erro de identidade/valor/destino/competencia exige
correcao e nova versao; a fonte atual permanece preservada.

Os extremos financeiros ja conferem com as fontes; nomes completos resolvem
a exibicao das cinco raizes sem sigla, sem inventar abreviacoes. RCL nao sera
imputada nem substituida por receita total. A proposta logit ja foi examinada
como exigencia de dados; participacoes foram estimadas depois da autorizacao,
com alternativas amplas explicitadas como hipotese, ainda sem validacao institucional.

## Controle De Mudancas

1. Qualquer mudanca de ordem ou estado deve ser registrada primeiro neste
   arquivo.
2. `METODOLOGIA_GERAL.md` descreve entregas executadas, sem criar nova ordem.
3. A numeracao dos scripts e tecnica e nao precisa coincidir com os dez passos.
4. Um complemento metodologico pertence ao passo que ele corrige; nao recebe
   automaticamente um novo numero.

### Historico

| Data | Alteracao | Motivo |
|---|---|---|
| 24/09, auditoria e alternativas | Scripts 33-35 e teste 21; extrator CNES corrigido; 31/32 regenerados; 28 comparacoes territoriais e quatro documentais | Separar erro cadastral, identidade financeira conflitante e limite institucional; explicitar perdas antes de escolher alternativas |
| 24/09, estimacao apos preparacao | Script 32 estima vinculo binario, cenarios e sensibilidades; teste 20 independente | Comparar clinicas/sedes na mesma amostra, avaliar ampliacao e expor limites de horas, populacao e distancia zero |
| 24/09, preparacao apos reuniao | Script 31 inventaria tres cenarios, 186.807 linhas conciliadas e especificacao binaria; teste 19 | Quantificar ampliacao 54->63 (53->62 com horas positivas), preservar ausentes/zeros e separar mudanca espacial de amostral |
| 24/09, reuniao e esclarecimento posterior | Adesao operacional definida como pagamento positivo com varios vinculos; horas SUS e tres cenarios espaciais encaminhados, ainda sem estimar | Distinguir presenca de vinculo, atracao relativa e participacao financeira; separar agenda documental geral e piloto MG |
| 24/09, piloto autorizado | Passo 8 parcial: participacoes estimadas, validacao e aba local concluidas | Testar atracao/tempo com desfecho financeiro, explicar selecao e manter limites de acesso institucional |
| 24/09, proposta logit | Passo 8 em especificacao; diagnostico de um ano executado, sem estimar | Pagamentos simultaneos exigem distinguir principal destino, participacoes e ocorrencia por par; sede/populacao nao equivalem a hospital |
| 24/09/2026, fechamento v1 | Passo 7 concluido para entrega delimitada: duas bases, sintese CNES, inclusao/exclusao e testes | Adriano priorizou MIDES e uma entrega simples; RCL e pesquisa documental deixam de bloquear; formula/amostra final continuam por definir |
| 24/09/2026 | Revisados tres casos prioritarios; coletadas seis fotografias mensais e medida a cobertura dos recortes | distinguir servico movel de polo clinico; corrigir leitura incompleta da Fhemig; dimensionar coleta mensal e selecao fiscal |
| 24/09/2026 | Conciliadas 181 entidades-ano, conferidos 60 casos financeiros e indexados produtos/fontes | distinguir classificacao resolvida de prestador anual ainda desconhecido; passo 7 continua aberto |
| 24/09/2026 | Passo 7 reaberto como avaliacao de suficiencia; inventario de 60 variaveis, 181 lacunas entidade-ano e anomalias executado | a auditoria do recorte direto nao validava automaticamente a cobertura do fenomeno completo |
| 24/09/2026 | EDA do passo 7 concluida para o recorte cadastral direto, com auditoria de extremos, capacidade, RCL, alternativas e marcador SUS | medir perdas e separar cadastro clinico de evidencia de atividade SUS antes de qualquer modelo |
| 23/09/2026 | Passo 6 fechado na especificacao restrita; bacia adiada por decisao de Adriano | comparar alternativas demonstrou perda material de pares sem polo direto; bacia nao mede diretamente acesso assistencial |
| 23/09/2026 | Primeira integracao anual de 97 entidades, capacidade externa, populacao IBGE, RCL parcial, PDR/2019 e tempos historicos materializados | comparar alternativas antes de fixar o recorte restrito no mesmo dia |
| 16/09/2026 | Revisao externa de 137 raizes, 28 dossies, MIDES complementar e atlas individual concluidos | nove consorcios de saude nao tinham sido consultados; incorporar candidatos com temporalidade e escopo antes de fechar o painel |
| 16/09/2026 | Passo 3 concluido: filtro funcional, duas fichas conflitantes, 21 auditorias documentais, 18 entidades sem MIDES, tres multiarea, alerta CISPARA e dois mapas validados | todo caso relevante agora possui destino/rede documentado ou decisao explicita de exclusao/sensibilidade |
| 16/09/2026 | Auditoria comparativa das 18 sem MIDES, revisao dos dois multiarea e mapas por tipo incorporados como complementos | demandas da reuniao de 10/09; aprofundam universo e cobertura sem criar nova etapa |
| 10/09/2026 | Triagem dos 91 casos concluida; sete entidades receberam 56 decisoes anuais; passo 3 permanece parcial | faltam filtro clinico das estruturas nao moveis e documentos para casos ainda excluidos |
| 10/09/2026 | 307 unidades moveis retiradas da oferta fixa atual; 82 estruturas candidatas e 63 destinos | nomes USB/USA nao eram reconhecidos pelo filtro anterior; tipo oficial CNES passou a prevalecer |
| 03/09/2026 | Fixada a sequencia canonica de dez passos | eliminar a concorrencia entre o plano original e a numeracao das entregas tecnicas |
| 03/09/2026 | Capacidade ficou antes do tempo rodoviario | o destino assistencial precisa ser conhecido antes de calcular impedancia |
| 03/09/2026 | Auditoria de cobertura e CNES historico foram reclassificados como complementos dos passos 3 e 4 | essas entregas aprofundam etapas existentes; nao criam novos objetivos cientificos |
