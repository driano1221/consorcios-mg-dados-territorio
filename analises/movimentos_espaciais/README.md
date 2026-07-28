# Movimentos Espaciais No MIDES Completo

Esta pasta materializa a analise de movimentos observados no MIDES completo, sem alterar o dashboard.

## Escopo

- Periodo: 2014 a 2021.
- Unidade basica: municipio x CNPJ de consorcio x ano.
- Presenca MIDES: \`valor_total > 0\`.
- Interpretacao: pagamento observado no MIDES, nao filiacao juridica formal.
- CNPJ matriz e filial permanecem separados.

## Scripts

1. \`01_materializar_movimentos_mides.R\`
   - Cria a serie balanceada de todos os pares observados em todos os anos.
   - Classifica cada linha como \`base_inicial\`, \`entrada_observada\`, \`retorno_observado\`, \`permaneceu\`, \`saida_observada\` ou \`ausente\`.
   - Resume movimentos por par, consorcio-ano e municipio-ano.

2. \`02_features_espaciais_fronteira.R\`
   - Usa a malha oficial geobr/IBGE de municipios de MG em 2020.
   - Define vizinhos apenas por fronteira compartilhada em linha; contato em um ponto nao conta.
   - Calcula, para cada participante, vizinhos dentro e fora do mesmo consorcio, borda e isolamento.
   - Cria tambem o universo de candidatos externos de borda para analisar entradas.

3. tests/03_validar_movimentos_espaciais.R
   - Verifica a unidade, a regra de presenca, a consistencia dos eventos e a cobertura da vizinhanca.

4. 04_eda_validacao_movimentos_espaciais.R
   - Reproduz as tabelas de integridade, movimentos, recorrencia, taxas espaciais, alertas e amostras aleatorias.
   - A leitura consolidada esta em EDA_RESULTADOS.md.

## Saidas

| Arquivo | Conteudo |
|---|---|
| \`movimentos_municipio_consorcio_ano\` | Painel balanceado de 2014-2021 com eventos e valores MIDES. |
| \`movimentos_resumo_par\` | Primeiro/ultimo ano observado, transicoes e recorrencia por par. |
| \`movimentos_consorcio_ano\` | Ativos, entradas, saidas, permanencias e saldo por consorcio-ano. |
| \`movimentos_municipio_ano\` | Movimento agregado por municipio-ano. |
| \`vizinhos_municipais_mg\` | Arestas municipais e comprimento da divisa compartilhada. |
| \`grau_vizinhanca_municipal_mg\` | Numero de vizinhos e comprimento total de divisas por municipio. |
| \`features_espaciais_municipio_consorcio_ano\` | Features contemporaneas e exposicao espacial em t-1. |
| \`risco_entrada_fronteira_municipio_consorcio_ano\` | Municipios externos vizinhos de um consorcio em t-1, com indicador de entrada observada em t. |
| \`features_espaciais_consorcio_ano\` | Resumo territorial por consorcio-ano. |

## Leitura Das Features

- \`prop_vizinhos_no_consorcio\`: proporcao dos vizinhos municipais que tambem apresentam pagamento para o mesmo CNPJ no mesmo ano.
- \`municipio_borda\`: participante com pelo menos um municipio vizinho fora do consorcio no MIDES.
- \`municipio_isolado\`: participante sem nenhum vizinho participante no mesmo CNPJ.
- Campos com sufixo \`_t_1\`: medidos no ano anterior ao evento. Sao os campos adequados para testar saida.
- Para entradas, a exposicao em \`t-1\` e medida no universo de candidatos externos que ja eram vizinhos de membros do consorcio.

## Limites

- Pagamento ausente nao prova desligamento institucional.
- O ano de 2014 e base inicial, portanto nao permite inferir entrada anterior.
- A camada nao consolida CNPJ matriz/filial.
- A proxima etapa analitica e descritiva/inferencial: comparar entradas e saidas segundo borda, isolamento e proporcao de vizinhos participantes. Ela ainda nao foi incorporada ao dashboard.
