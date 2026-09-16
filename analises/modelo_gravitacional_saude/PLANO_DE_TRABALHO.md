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

**Estado em 16/09/2026:** passos 1 a 5 concluidos como camadas-base; passo 6 em
andamento; passos 7 a 10 ainda nao iniciados como etapas finais.

- [x] **1. Fechar o universo de consorcios de saude**
- [x] **2. Auditar os vinculos**
- [x] **3. Definir o polo e completar a cobertura assistencial**
- [x] **4. Construir e temporalizar a capacidade assistencial direta**
- [x] **5. Construir a camada-base de tempo rodoviario**
- [ ] **6. Montar o painel analitico final - em andamento**
- [ ] **7. Executar a EDA e a validacao do universo final**
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

### 6. Montar O Painel Analitico Final

- [x] materializar a grade preliminar municipio x entidade x ano;
- [x] calcular pagamento, primeiro pagamento, permanencia, retorno e interrupcao;
- [x] preservar a censura dos pagamentos ja existentes em 2014;
- [ ] harmonizar as dez candidatas externas e os tres casos de escopo misto
  com as regras de amostra; completar capacidade LT/SR/PF e presenca mensal
  somente para as entidades que entrarem, reaproveitando os arquivos brutos;
- [ ] definir o conjunto de alternativas plausiveis por municipio e ano;
- [ ] comparar tres regras: todos os consorcios de saude de MG, limite de tempo
  rodoviario e mesma regiao de saude;
- [ ] integrar populacao, RCL, regiao de saude, bacia e ciclo do mandato;
- [ ] ligar capacidade historica, tempo e decisoes do passo 3 sem vazamento
  temporal;
- [ ] definir os universos sob risco de entrada, intensidade e interrupcao.

**Produto parcial:** grade de 573.216 linhas com movimentos financeiros. Ela
ainda nao e o painel final de estimacao.

### 7. Executar A EDA E A Validacao Do Universo Final

- [ ] quantificar zeros, entradas, permanencias, retornos e interrupcoes nos
  universos finais;
- [ ] examinar alternativas por municipio e tempos extremos;
- [ ] identificar entidades sem massa mensuravel;
- [ ] verificar censura, perdas por pareamento e cobertura das variaveis;
- [ ] comparar os tres conjuntos de alternativas antes de escolher o principal.

As estatisticas produzidas nos passos anteriores sao controles preliminares;
nao substituem esta EDA final, que depende do passo 6.

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

Revisao externa e atlas por consorcio concluidos. Agora concluir o **passo 6**:
primeiro harmonizar os candidatos identificados fora das 84 e completar suas
medidas historicas; depois definir e comparar os tres conjuntos de
alternativas plausiveis por municipio e ano; depois integrar capacidade
historica, tempo rodoviario, populacao, RCL, regiao de saude, bacia e mandato
sem vazamento temporal. Nao repetir a triagem dos 91 casos nem a coleta das 84
originais. As 74 unidades-ano externas foram extraidas somente do ST de
dezembro; ainda nao possuem a mesma bateria de capacidade das 84. A EDA final so comeca depois que esse painel
estiver materializado e testado.

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
| 16/09/2026 | Revisao externa de 137 raizes, 28 dossies, MIDES complementar e atlas individual concluidos | nove consorcios de saude nao tinham sido consultados; incorporar candidatos com temporalidade e escopo antes de fechar o painel |
| 16/09/2026 | Passo 3 concluido: filtro funcional, duas fichas conflitantes, 21 auditorias documentais, 18 entidades sem MIDES, tres multiarea, alerta CISPARA e dois mapas validados | todo caso relevante agora possui destino/rede documentado ou decisao explicita de exclusao/sensibilidade |
| 16/09/2026 | Auditoria comparativa das 18 sem MIDES, revisao dos dois multiarea e mapas por tipo incorporados como complementos | demandas da reuniao de 10/09; aprofundam universo e cobertura sem criar nova etapa |
| 10/09/2026 | Triagem dos 91 casos concluida; sete entidades receberam 56 decisoes anuais; passo 3 permanece parcial | faltam filtro clinico das estruturas nao moveis e documentos para casos ainda excluidos |
| 10/09/2026 | 307 unidades moveis retiradas da oferta fixa atual; 82 estruturas candidatas e 63 destinos | nomes USB/USA nao eram reconhecidos pelo filtro anterior; tipo oficial CNES passou a prevalecer |
| 03/09/2026 | Fixada a sequencia canonica de dez passos | eliminar a concorrencia entre o plano original e a numeracao das entregas tecnicas |
| 03/09/2026 | Capacidade ficou antes do tempo rodoviario | o destino assistencial precisa ser conhecido antes de calcular impedancia |
| 03/09/2026 | Auditoria de cobertura e CNES historico foram reclassificados como complementos dos passos 3 e 4 | essas entregas aprofundam etapas existentes; nao criam novos objetivos cientificos |
