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

**Estado em 10/09/2026:** passos 1, 2, 4 e 5 concluidos como camadas-base; passos 3 e 6 em
andamento; passos 7 a 10 ainda nao iniciados como etapas finais.

- [x] **1. Fechar o universo de consorcios de saude**
- [x] **2. Auditar os vinculos**
- [ ] **3. Definir o polo e completar a cobertura assistencial - em andamento**
- [x] **4. Construir e temporalizar a capacidade assistencial direta**
- [x] **5. Construir a camada-base de tempo rodoviario**
- [ ] **6. Montar o painel analitico final - em andamento**
- [ ] **7. Executar a EDA e a validacao do universo final**
- [ ] **8. Estimar os tres blocos**
- [ ] **9. Testar robustez**
- [ ] **10. Integrar resultados validados ao dashboard**

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
- [ ] distinguir destinos clinicos de centrais de gestao/regulacao, farmacia,
  vigilancia e telessaude nas estruturas nao moveis atuais e historicas;
- [ ] resolver duas fichas atuais com nome/tipo conflitante ou ausente;
- [ ] completar a pesquisa documental individual das entidades nao prioritarias
  e as vigencias/prestadores ainda ausentes; ate la vale a exclusao explicita.

O dossie encerra a triagem dos 91 casos, nao comprova oferta para todos eles:
59 possuem registro fixo posterior; 3 possuem fixa em outros meses do mesmo
ano; 12 pertencem aos dois casos historicos; 5 sao planejamento CISVALES;
1 possui regulacao SAMU documentada em 2021; 11 seguem sem polo suficiente.

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

Fechar o filtro de funcao assistencial nas estruturas nao moveis do **passo 3**
e suas pendencias documentais, partindo das decisoes anuais ja materializadas.
Nao repetir a triagem dos 91 casos ou a extracao CNES. Em seguida, concluir o
**passo 6** com alternativas e variaveis anuais. A EDA final so comeca depois
que esse painel estiver materializado e testado.

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
| 10/09/2026 | Triagem dos 91 casos concluida; sete entidades receberam 56 decisoes anuais; passo 3 permanece parcial | faltam filtro clinico das estruturas nao moveis e documentos para casos ainda excluidos |
| 10/09/2026 | 307 unidades moveis retiradas da oferta fixa atual; 82 estruturas candidatas e 63 destinos | nomes USB/USA nao eram reconhecidos pelo filtro anterior; tipo oficial CNES passou a prevalecer |
| 03/09/2026 | Fixada a sequencia canonica de dez passos | eliminar a concorrencia entre o plano original e a numeracao das entregas tecnicas |
| 03/09/2026 | Capacidade ficou antes do tempo rodoviario | o destino assistencial precisa ser conhecido antes de calcular impedancia |
| 03/09/2026 | Auditoria de cobertura e CNES historico foram reclassificados como complementos dos passos 3 e 4 | essas entregas aprofundam etapas existentes; nao criam novos objetivos cientificos |
