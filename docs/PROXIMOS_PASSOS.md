# Proximos Passos - ideiaMides

**Atualizado em:** 2026-07-28  
**Uso:** roteiro curto do estado atual, decisoes pendentes e proximas entregas possiveis.

---

## Estado Atual

O projeto tem hoje tres blocos principais funcionando:

1. **Base 1 2015/2019**
   - recorte comparavel entre MIDES e MUNIC;
   - SICONFI entra como validacao financeira municipio-ano, nao como fonte de par municipio-consorcio;
   - metodologia documentada em `analises/base_1_2015_2019/METODOLOGIA.md`.

2. **Dashboard Shiny**
   - publicado em `https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/`;
   - inclui Base 1, MIDES completo, comparacao 2015 vs 2019, auditorias e documentacao metodologica;
   - inclui mapas dinamicos para intensidade MIDES, composicao territorial das fontes e transicao 2015 vs 2019;
   - aba `MIDES completo > Entradas/saidas` mostra movimento anual dos pares municipio-consorcio entre 2014 e 2021;
   - mapas foram refinados visualmente com fundo branco, divisas municipais continuas, paletas mais legiveis, zoom/tela cheia e filtros integrados.

3. **Auditorias cadastrais**
   - auditoria por raiz de CNPJ identifica possiveis matriz/filiais;
   - regra de consolidacao ainda nao foi aplicada;
   - resultados servem para validacao humana antes de recalcular valores.

4. **Mapas e visualizacoes territoriais**
   - mapa MIDES completo mostra intensidade municipal por valor, consorcios ou transacoes;
   - mapa Base 1 mostra predominio territorial de `MIDES+MUNIC`, `so MIDES`, `so MUNIC` ou misto;
   - mapa 2015 vs 2019 separa permanencia, entrada e saida de pares;
   - mapa anual do MIDES completo permite observar entradas e saidas de 2014 a 2021 em pequenos multiplos.

---

## Decisoes Pendentes

1. **Matriz e filiais**
   - decidir com superiores se matriz/filiais devem ser consolidadas por raiz de 8 digitos do CNPJ;
   - se aprovado, criar tabela `cnpj_original -> cnpj_matriz`;
   - depois recalcular MIDES/SICONFI usando CNPJ consolidado.

2. **Regra definitiva do SICONFI**
   - regra atual recomendada: `consorcio_pagas`;
   - manter claro que SICONFI valida gasto municipal agregado e nao identifica consorcio de destino;
   - decidir se a regra atual vira padrao definitivo ou se sera mantida como regra principal com analises de sensibilidade.

3. **Escopo territorial**
   - decidir qual recorte territorial entra primeiro no projeto;
   - recomendacao atual: comecar por Regioes de Saude SUS e Bacias Hidrograficas.

---

## Proximos Passos Priorizados

### 1. Consolidar auditoria matriz/filial

**Status:** aguardando validacao dos superiores.

O que fazer se for aprovado:

- criar tabela de correspondencia entre CNPJ observado e CNPJ matriz;
- somar valores MIDES de filiais na matriz;
- revisar se SICONFI precisa ser recalculado na mesma chave;
- atualizar dashboard e metodologia com a regra aplicada.

Nao aplicar automaticamente antes da validacao.

### 2. Analise territorial do movimento no MIDES completo

**Status:** prioridade imediata definida na ultima reuniao.

Objetivo:

- explicar movimentos de entrada e saida, e nao apenas mapea-los;
- verificar quais caracteristicas territoriais e setoriais estao associadas a maior movimento.

Entregas priorizadas:

1. **Tabela analitica ano a ano**
   - por `ano x consorcio`: municipios que entraram, sairam, permaneceram e saldo liquido;
   - detalhamento de municipios quando o filtro retornar poucos consorcios;
   - indicador de recorrencia no par `municipio x consorcio`: quantidade de entradas, saidas e transicoes entre 2014 e 2021;
   - `movimento_recorrente = Sim` quando o par apresentar mais de uma transicao de presenca/ausencia no periodo.

2. **Features espaciais de fronteira**
   - construir vizinhanca entre municipios de MG a partir das geometrias municipais;
   - para cada municipio dentro de cada consorcio-ano, calcular numero e proporcao de vizinhos que tambem pertencem ao consorcio;
   - derivar numero e proporcao de vizinhos fora do consorcio, indicador de municipio de fronteira e eventual isolamento territorial;
   - testar descritivamente se municipios de fronteira apresentam mais entradas, saidas ou movimentos recorrentes.

3. **Classificacao por area de politica publica**
   - **versao analitica v0.5 concluida:** `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_analitica_ativa.csv` e `.rds`;
   - cobre os 223 CNPJs MG e reduz o uso analitico a tres campos: `area_politica_final`, `fonte_principal` e `status_validacao`; macroarea e perfil permanecem apenas como auxiliares;
   - status atual: 34 confirmadas, 94 provisorias coerentes, 15 provisorias por cadastro, 48 provisorias por nome, 23 multifinalitarios sem inferencia automatica, 6 pendentes, 2 filiais aguardando regra e 1 associacao fora do escopo;
   - a v0.2 e a trilha tecnica continuam preservadas; a v0.3 nao altera MIDES, Base 1 ou dashboard;
   - regra de fontes: documentacao > revisao documental v0.2 > nome juridico com MUNIC coerente > MUNIC segura > cadastro IPEA arquivo sem conflito > nome juridico provisório > pendencia;
   - `tipo_fonte = regex` no cadastro IPEA e inferencia do nome, nao fonte independente.

   Pendencia antes de uso analitico no dashboard:

   - [feito] auditar e aprovar a regra de consolidacao dos setores MUNIC por CNPJ: a uniao cega nao define mais area final; a excecao de convergencia MUNIC + Cadastro IPEA foi aprovada; CIS/AMAPI, CISMEJE, CISAJE e CISVER foram validados como saude por documentacao institucional;
   - [em validacao humana] conferir a amostra reprodutivel de 19 CNPJs em `analises/classificacao_politicas/outputs/amostra_validacao_regra_MUNIC_v0_1.xlsx`; este controle documenta a aceitacao empirica da regra, sem reabrir a uniao automatica;
   - [feito] gerar `outputs/caderno_decisao_v0_3/caderno_decisao_classificacao_v0_3.xlsx`, que separa os 188 casos sem confirmacao plena por tipo de incerteza e preserva suas evidencias para decisao humana;
   - [feito] incorporar as decisoes de 28/07 na v0.4: 15 casos por cadastro e 48 por nome validados para uso analitico; seis matrizes inaptas/baixadas excluidas apenas da camada ativa; duas filiais herdaram classificacao da matriz; 23 multifinalitarios foram separados em perfil por nome e area apenas quando explicitada;
   - estado ativo v0.5: 217 CNPJs (34 confirmados, 94 coerentes validados pelo usuario, 63 validados pelo usuario por cadastro/nome, 7 com saude explicita por nome/alias, 16 perfis sem area especifica, 2 filiais herdadas e 1 fora do escopo);
   - os seis pendentes tematicos inaptos/baixados foram retirados somente da camada analitica ativa; permanecem no arquivo tecnico;
   - a classificacao de matriz/filial ainda nao consolida CNPJs, valores ou movimentos; isso requer decisao separada;
   - os 16 multifinalitarios/multissetoriais sem area final permanecem apenas como perfil institucional, sem inferencia setorial adicional nesta etapa;
   - antes da frente de movimentos, integrar a v0.5 ao dashboard e consolidar documentacao e repositorio.

4. **Aprimoramentos do dashboard**
   - exibir nome de municipio no mapa apenas em filtros suficientemente restritos, para preservar legibilidade;
   - substituir o download atual por exportacao de mapa em alta resolucao, adequada para apresentacao e relatorio;
   - manter a visualizacao dinamica separada da exportacao estatica de alta qualidade.

5. **Hipoteses a investigar**
   - municipios com maior proporcao de vizinhos fora do consorcio apresentam maior probabilidade de entrada ou saida?
   - movimentos recorrentes se concentram em determinadas areas de politica publica?
   - ha anos, regioes ou consorcios com saldo sistematicamente positivo ou negativo?
   - primeiros anos de mandatos municipais se associam a maior ocorrencia de entrada ou saida?

Observacao:

- a unidade continua sendo `municipio x consorcio x ano`;
- MIDES completo nao usa MUNIC nem SICONFI.

### 3. Aplicar recortes territoriais viaveis

**Status:** pesquisa feita, nao implementado.

Ordem recomendada:

1. **Regioes de Saude SUS**
   - maior prioridade;
   - dados oficiais por municipio;
   - encaixa diretamente com consorcios de saude;
   - permite testar se consorcios de saude seguem a regionalizacao SUS.

2. **Bacias Hidrograficas**
   - prioridade alta/media;
   - usar bases IGAM/SISEMA;
   - exige decisao metodologica: centroide, bacia predominante por area ou multiplas bacias com pesos;
   - mais util para saneamento, meio ambiente, residuos, recursos hidricos e desenvolvimento regional.

3. **Associacoes Microrregionais AMM**
   - prioridade media;
   - hipotese institucional forte, mas base municipio-associacao ainda precisa ser montada;
   - usar como frente exploratoria/historica, nao como resultado fechado de imediato.

4. **Votos/deputados**
   - prioridade baixa para implementacao inicial;
   - dados TSE existem, mas interpretacao causal e sensivel;
   - tratar apenas como sobreposicao exploratoria de territorios eleitorais, sem afirmar causalidade.

### 4. Criar medida de coerencia territorial

**Status:** proposta metodologica salva, nao implementada.

Medida sugerida:

> coerencia territorial do consorcio = percentual de pares de municipios do mesmo consorcio que pertencem ao mesmo recorte territorial.

Exemplo:

- consorcio com 10 municipios gera 45 pares municipio-municipio;
- se 30 pares estao na mesma regiao de saude;
- coerencia = 30 / 45 = 66,7%.

Depois comparar contra sorteios aleatorios de municipios do mesmo tamanho.

Primeiro output sugerido:

| consorcio | n_municipios | recorte | regiao_dominante | pct_na_regiao_dominante | coerencia_observada | coerencia_aleatoria_media | p_valor_permutacao |
|---|---:|---|---|---:|---:|---:|---:|

---

## Itens Pausados Ou Fora Do Escopo Imediato

- **SICONV:** pausado; nao mexer ate decisao explicita.
- **CNM na Base 1:** fora do recorte 2015/2019; CNM e fonte atual/historica separada, nao comparavel diretamente com MUNIC 2015/2019.
- **Consolidacao matriz/filial:** nao aplicar ainda; apenas auditoria esta pronta.
- **Deputados/votos:** viavel tecnicamente, mas deixar para etapa posterior por risco de interpretacao.
- **AMM completa:** nao assumir que a base esta pronta; precisa coleta municipio a municipio.

---

## Arquivos De Apoio

- `docs/MEMORIA_ideiaMides.md`: estado consolidado do projeto.
- `docs/DICIONARIO_MEMORIAS.md`: indice rapido das memorias.
- `docs/2026-06-10-pesquisa-recortes-territoriais.md`: pesquisa de viabilidade dos recortes territoriais.
- `analises/base_1_2015_2019/METODOLOGIA.md`: metodologia da Base 1.
- `dashboards/base1_shiny/app.R`: codigo do dashboard.
