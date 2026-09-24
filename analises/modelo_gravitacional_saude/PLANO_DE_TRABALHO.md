# Plano De Trabalho Canonico - Modelo Gravitacional De Saude

Este e o **unico arquivo que define a ordem, o estado e o proximo marco** do
modelo gravitacional de saude. A metodologia explica o que ja foi feito; o
dicionario localiza arquivos; a linha do tempo ensina o percurso. Nenhum deles
deve criar uma segunda numeracao de etapas.

## Leitura Do Estado

- `[x]` concluido e validado;
- `[ ] Em andamento` possui produtos parciais, mas ainda nao cumpriu o criterio
  de conclusao;
- `[ ] Nao iniciado` depende das etapas anteriores.

**Estado apos o fechamento da v1 em 24/09/2026:** passos 1 a 7 concluidos
para a entrega delimitada dos dados: base financeira do nucleo de saude e
base gravitacional com oferta clinica direta cadastrada em dezembro.
Adriano autorizou simplificar: MIDES como eixo, RCL complementar e documentos
como apoio. A v1 nao representa toda a oferta indireta/movel nem define a
formula final. Passos 8 a 10 nao iniciados; nenhum modelo foi estimado.

- [x] **1. Fechar o universo de consorcios de saude**
- [x] **2. Auditar os vinculos**
- [x] **3. Definir o polo e completar a cobertura assistencial**
- [x] **4. Construir e temporalizar a capacidade assistencial direta**
- [x] **5. Construir a camada-base de tempo rodoviario**
- [x] **6. Montar o painel analitico anual e um recorte candidato**
- [x] **7. Executar a EDA e fechar a base v1 para o recorte documentado**
- [ ] **8. Estimar os tres blocos**
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
- [x] definir o conjunto de alternativas plausiveis por municipio e ano;
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

- [ ] entrada: logit ou risco discreto;
- [ ] intensidade financeira: PPML ou modelo hurdle;
- [ ] interrupcao/permanencia: sobrevivencia em tempo discreto.

Os tres modelos respondem perguntas diferentes e nao devem ser fundidos em uma
unica regressao.

### 9. Testar Robustez

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

**Proximo marco:** confrontar a formula ja definida pela equipe, quando
enviada, com as duas bases v1. Verificar desfecho, massa, combinacao de
capacidade/tempo, tratamento dos zeros e deflacao dos valores nominais.
Nao estimar modelos automaticamente nem ampliar coleta sem uma necessidade
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
imputada nem substituida por receita total. A formula da equipe sera examinada
depois, como lista de exigencias de dados, sem iniciar modelos automaticamente.

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
