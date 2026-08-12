# Proximos Passos - Consorcios MG: Dados e Territorio

**Atualizado em:** 2026-08-12
**Uso:** roteiro curto do estado atual, decisoes pendentes e proximas entregas possiveis.

---

## Estado Atual

O projeto tem hoje tres blocos principais funcionando:

### Plano Das Oito Frentes - Estado Em 28/07/2026

| # | Frente | Estado atual | O que falta |
|---:|---|---|---|
| 1 | Classificacao detalhada e macrogrupos | Concluida na v0.5 para a camada analitica ativa e integrada ao MIDES completo. | Manter revisao versionada; nao inventar area para perfis amplos sem evidencia. Consolidacao matriz/filial e decisao separada. |
| 2 | Auditar origem da classificacao | Concluida. Fonte, status, justificativa e trilha tecnica foram preservados e documentados. | Manter rastreabilidade nas revisoes futuras. |
| 3 | Base anual de movimentos municipio x consorcio x ano | Concluida e reprocessavel: 22.680 linhas, 2.835 pares e oito anos. | Apenas integrar novos recortes ou regras se forem aprovados. |
| 4 | Features espaciais de fronteira | Concluida: 2.375 fronteiras e nove variaveis espaciais, com universos de entrada e saida. | Eventuais sensibilidades por comprimento de divisa e recortes territoriais. |
| 5 | Tabela analitica anual por consorcio | Concluida em duas leituras: consulta consorcio-ano e trajetoria longitudinal 2014-2021, com matriz municipio-ano e listas nominais. | Apenas adaptar a regra caso matriz/filial venha a ser consolidada. |
| 6 | Testar hipotese de fronteira e movimento | Concluida como analise exploratoria: modelos, taxas, sensibilidades e documentacao no dashboard. | Adicionar controles socioeconomicos, fiscais, politicos e setoriais antes de interpretacoes mais fortes. |
| 7 | Melhorar mapa com nomes em recortes pequenos | Concluida: nomes aparecem com ate 12 municipios destacados; o recorte automatico preserva contexto territorial e reduz a geometria renderizada. | Rever apenas se a equipe solicitar outro limite de rotulos. |
| 8 | Exportacao PNG/PDF de alta qualidade | Concluida nos quatro mapas: PNG 450 dpi, PNG 300 dpi nos pequenos multiplos e PDF vetorial. | Validar uso editorial em cada novo template de relatorio. |

1. **Base 1 2015/2019**
   - recorte comparavel entre MIDES e MUNIC;
   - SICONFI entra como validacao financeira municipio-ano, nao como fonte de par municipio-consorcio;
   - metodologia documentada em `analises/base_1_2015_2019/METODOLOGIA.md`.

2. **Dashboard Shiny**
   - publicado em `https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/`;
   - inclui Base 1, MIDES completo, comparacao 2015 vs 2019, auditorias e documentacao metodologica;
   - inclui mapas dinamicos para intensidade MIDES, composicao territorial das fontes e transicao 2015 vs 2019;
   - a tela MIDES completo permite filtrar por area detalhada, macrogrupo e perfil institucional da classificacao v0.5; atributos sem area permanecem preservados nos totais, sem uma categoria generica de filtro.
   - aba `MIDES completo > Entradas/saidas` mostra movimento anual dos pares municipio-consorcio entre 2014 e 2021;
   - aba `MIDES completo > Trajetoria 2014-2021` compara os oito anos por consorcio e abre sob demanda linha do tempo, tabela anual e matriz municipio-ano para qualquer linha, sem exigir filtro previo;
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

0. **Clareza do indicador de recorrencia no dashboard**
   - recorrencia e definida no par `municipio x CNPJ` ao longo de 2014-2021;
   - o total no resumo do consorcio esta correto;
   - a coluna anual `Recorrentes` mostra pares recorrentes ativos naquele ano, nao novos recorrentes do ano;
   - renomear para `Pares recorrentes ativos no ano` ou retirar a coluna da tabela anual. Recomendacao: retirar da tabela anual e manter o total do periodo no resumo.

0.1. **Auditar CNPJs de baixa escala e persistencia**
   - gerar tabela por CNPJ com maximo de municipios pagantes, anos ativos, municipio-anos, valor, entradas, saidas e recorrencia;
   - destacar inicialmente CNPJs com no maximo 1 ou 2 municipios pagantes, sem exclui-los automaticamente;
   - cruzar nomes, raizes, situacao cadastral, ano de fundacao e documentos;
   - comparar resultados dos modelos com e sem casos classificados como pontuais ou de evidencia insuficiente;
   - estudar distancia/tempo rodoviario ate a sede ou nucleo do consorcio.

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

**Status:** bases de movimentos, fronteira, universos de risco e modelos exploratorios materializados e validados; metodologia e resultados documentados em `Documentacao > Movimentos espaciais`, ainda sem tela analitica propria no dashboard.

Objetivo:

- explicar movimentos de entrada e saida, e nao apenas mapea-los;
- verificar quais caracteristicas territoriais e setoriais estao associadas a maior movimento.

Entregas priorizadas:

1. **Tabela analitica ano a ano**
   - por `ano x consorcio`: municipios que entraram, sairam, permaneceram e saldo liquido;
   - detalhamento de municipios quando o filtro retornar poucos consorcios;
   - indicador de recorrencia no par `municipio x consorcio`: quantidade de entradas, saidas e transicoes entre 2014 e 2021;
   - `movimento_recorrente = Sim` quando o par apresentar mais de uma transicao de presenca/ausencia no periodo.

   Entrega concluida em 2026-07-28:

   - `analises/movimentos_espaciais/01_materializar_movimentos_mides.R` gerou uma serie balanceada de 22.680 linhas: 2.835 pares observados x 8 anos;
   - a regra aplicada e `valor_total > 0`, interpretada como pagamento observado no MIDES, nunca como filiacao juridica;
   - outputs incluem movimento por par, por consorcio-ano e por municipio-ano;
   - 673 pares tiveram duas ou mais transicoes observadas entre 2014 e 2021.

2. **Features espaciais de fronteira**
   - construir vizinhanca entre municipios de MG a partir das geometrias municipais;
   - para cada municipio dentro de cada consorcio-ano, calcular numero e proporcao de vizinhos que tambem pertencem ao consorcio;
   - derivar numero e proporcao de vizinhos fora do consorcio, indicador de municipio de fronteira e eventual isolamento territorial;
   - testar descritivamente se municipios de fronteira apresentam mais entradas, saidas ou movimentos recorrentes.

   Entrega concluida em 2026-07-28:

   - malha oficial completa geobr/IBGE de 2020 usada somente no processamento; a geometria leve do dashboard nao foi usada para calcular vizinhanca;
   - 2.375 fronteiras municipais compartilhadas foram identificadas por linha, excluindo contato apenas por canto;
   - cada par ativo recebeu numero/proporcao de vizinhos dentro e fora do consorcio, indicador de borda e isolamento;
   - foi criado inicialmente um subconjunto de 18.404 candidatos externos adjacentes;
   - a revisao metodologica posterior ampliou o universo para todos os municipios nao participantes dos CNPJs ativos em `t-1`, permitindo comparar candidatos adjacentes com municipios sem vizinho participante;
   - os outputs ainda nao foram integrados ao dashboard;
   - EDA concluida em `analises/movimentos_espaciais/EDA_RESULTADOS.md`: integridade aprovada e associacoes espaciais descritivas fortes; restos a pagar e valores baixos foram testados por sensibilidade, enquanto matriz/filial e nomes canonicos permanecem pendentes.

3. **Universos de risco e modelos exploratorios**
   - universo de entrada: 742.916 exposicoes de nao membros, com 1.395 entradas/retornos modelaveis;
   - universo de saida: 12.842 exposicoes de participantes, com as 966 saidas originais recompostas;
   - 418 entradas ficaram separadas por nao haver CNPJ ativo em `t-1`: 387 no primeiro aparecimento do CNPJ na janela e 31 apos lacuna completa;
   - modelos logisticos usam exposicao espacial em `t-1`, tamanho do consorcio, grau municipal e efeitos fixos de ano, com erros-padrao agrupados por municipio e CNPJ;
   - aumento de 10 pontos percentuais na proporcao de vizinhos participantes apresentou OR 2,22 para entrada/retorno e OR 0,79 para saida;
   - sinais permaneceram estaveis usando somente pagamento corrente e valores minimos de R$ 100 e R$ 1.000;
   - documentacao: `analises/movimentos_espaciais/METODOLOGIA_MODELOS_RISCO.md` e `RESULTADOS_MODELOS_RISCO.md`;
   - documentacao didatica integrada ao dashboard em `Documentacao > Movimentos espaciais`, com pipeline, exemplo real, resultados, sensibilidades e limitacoes;
   - interpretacao mantida: associacao exploratoria entre pagamentos MIDES, nao efeito causal nem adesao juridica.

4. **Classificacao por area de politica publica**
   - **versao analitica v0.5 concluida:** `analises/classificacao_politicas/outputs/classificacao_areas_politica_mg_v0_5_analitica_ativa.csv` e `.rds`;
   - cobre os 223 CNPJs MG e reduz o uso analitico a tres campos: `area_politica_final`, `fonte_principal` e `status_validacao`; macroarea e perfil permanecem apenas como auxiliares;
   - status atual: 34 confirmadas, 94 coerentes validadas, 63 validadas por cadastro/nome, 16 perfis amplos sem area especifica, 2 filiais herdadas, 6 inativos/baixados e 1 associacao municipal fora da camada analitica;
   - a v0.2 e a trilha tecnica continuam preservadas; a v0.5 entra no MIDES completo somente como atributo de filtro, sem alterar valores, pares ou movimentos;
   - regra de fontes: documentacao > revisao documental v0.2 > nome juridico com MUNIC coerente > MUNIC segura > cadastro IPEA arquivo sem conflito > nome juridico provisório > pendencia;
   - `tipo_fonte = regex` no cadastro IPEA e inferencia do nome, nao fonte independente.

   Pendencia antes de uso analitico no dashboard:

   - [feito] auditar e aprovar a regra de consolidacao dos setores MUNIC por CNPJ: a uniao cega nao define mais area final; a excecao de convergencia MUNIC + Cadastro IPEA foi aprovada; CIS/AMAPI, CISMEJE, CISAJE e CISVER foram validados como saude por documentacao institucional;
   - [em validacao humana] conferir a amostra reprodutivel de 19 CNPJs em `analises/classificacao_politicas/outputs/amostra_validacao_regra_MUNIC_v0_1.xlsx`; este controle documenta a aceitacao empirica da regra, sem reabrir a uniao automatica;
   - [feito] gerar `outputs/caderno_decisao_v0_3/caderno_decisao_classificacao_v0_3.xlsx`, que separa os 188 casos sem confirmacao plena por tipo de incerteza e preserva suas evidencias para decisao humana;
   - [feito] incorporar as decisoes de 28/07 na v0.4: 15 casos por cadastro e 48 por nome validados para uso analitico; seis matrizes inaptas/baixadas excluidas apenas da camada ativa; duas filiais herdaram classificacao da matriz; 23 multifinalitarios foram separados em perfil por nome e area apenas quando explicitada;
   - estado ativo v0.5: 216 CNPJs (34 confirmados, 94 coerentes validados pelo usuario, 63 validados pelo usuario por cadastro/nome, 7 com saude explicita por nome/alias, 16 perfis amplos sem area especifica e 2 filiais herdadas);
   - os seis pendentes tematicos inaptos/baixados foram retirados somente da camada analitica ativa; permanecem no arquivo tecnico;
   - a classificacao de matriz/filial ainda nao consolida CNPJs, valores ou movimentos; isso requer decisao separada;
   - os 16 casos de perfil `multifinalitario_ou_multissetorial` sem area final permanecem sem inferencia setorial adicional nesta etapa;
   - [feito] integrar a v0.5 ao MIDES completo, consolidar documentacao e preparar testes automatizados; os filtros ativos sao area detalhada, macrogrupo e perfil institucional.

5. **Aprimoramentos do dashboard**
   - exibir nome de municipio no mapa apenas em filtros suficientemente restritos, para preservar legibilidade;
   - substituir o download atual por exportacao de mapa em alta resolucao, adequada para apresentacao e relatorio;
   - manter a visualizacao dinamica separada da exportacao estatica de alta qualidade.

6. **Hipoteses a investigar**
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
