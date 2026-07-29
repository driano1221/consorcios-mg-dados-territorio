# Movimentos Espaciais No MIDES Completo

Esta pasta materializa a analise de movimentos observados no MIDES completo. Seus resultados alimentam as tabelas, trajetorias e a documentacao espacial do dashboard, sem alterar os dados brutos.

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

5. \`05_modelar_riscos_entrada_saida.R\`
   - Materializa o universo completo de nao membros expostos a entrada e o universo de participantes expostos a saida.
   - Separa entrada nova, retorno e eventos sem CNPJ ativo em \`t-1\`.
   - Estima modelos logisticos com exposicao espacial defasada, controles basicos e erros-padrao agrupados por municipio e CNPJ.
   - Executa sensibilidades por pagamento corrente e valores minimos.

6. \`tests/06_validar_modelos_risco.R\`
   - Recompoe todos os movimentos, verifica a particao dos 853 municipios e recalcula diretamente uma amostra de 500 exposicoes espaciais.

7. \`07_eda_modelos_risco.R\`
   - Produz resumo anual, motivos de exclusao do modelo e amostras reproduziveis de eventos.

Documentacao adicional:

- \`METODOLOGIA_MODELOS_RISCO.md\`: desenho completo dos universos, features e modelos.
- \`RESULTADOS_MODELOS_RISCO.md\`: resultados, sensibilidades e limites de interpretacao.

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
| \`risco_entrada_completo_municipio_consorcio_ano\` | Todos os municipios nao participantes dos CNPJs ativos em t-1, inclusive os sem vizinho participante. |
| \`risco_saida_municipio_consorcio_ano\` | Todos os participantes em t-1 e seu resultado de permanencia ou saida em t. |
| \`modelos_logisticos_resultados.csv\` | Odds ratios e intervalos agrupados dos modelos principal e de sensibilidade. |
| \`eventos_entrada_fora_universo_modelo.csv\` | Entradas sem CNPJ ativo em t-1, separadas entre primeiro aparecimento e reaparecimento apos lacuna. |
| \`features_espaciais_consorcio_ano\` | Resumo territorial por consorcio-ano. |

## Leitura Das Features

- \`prop_vizinhos_no_consorcio\`: proporcao dos vizinhos municipais que tambem apresentam pagamento para o mesmo CNPJ no mesmo ano.
- \`municipio_borda\`: participante com pelo menos um municipio vizinho fora do consorcio no MIDES.
- \`municipio_isolado\`: participante sem nenhum vizinho participante no mesmo CNPJ.
- Campos com sufixo \`_t_1\`: medidos no ano anterior ao evento. Sao os campos adequados para testar saida.
- Para entradas, a exposicao em \`t-1\` e medida para todos os nao membros dos CNPJs ativos no ano anterior. A tabela antiga de fronteira permanece como subconjunto operacional.

## Limites

- Pagamento ausente nao prova desligamento institucional.
- O ano de 2014 e base inicial, portanto nao permite inferir entrada anterior.
- A camada nao consolida CNPJ matriz/filial.
- Os modelos atuais sao exploratorios e nao causais; faltam controles municipais, politicos, fiscais, setoriais e institucionais.
- Os resultados foram incorporados ao dashboard como produto exploratorio; isso nao elimina as limitacoes metodologicas descritas acima.
