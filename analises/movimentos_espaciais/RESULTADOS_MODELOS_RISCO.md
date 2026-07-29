# Resultados Dos Modelos De Risco MIDES

**Data:** 2026-07-28
**Natureza:** resultados exploratorios, ainda fora do dashboard.

## Universo Principal

| Analise | Exposicoes | Eventos | Taxa |
|---|---:|---:|---:|
| Entrada ou retorno entre todos os nao membros | 742.916 | 1.395 | 0,188% |
| Entrada nova, sem presenca anterior | 741.040 | 990 | 0,134% |
| Retorno, com presenca anterior | 1.876 | 405 | 21,6% |
| Saida entre participantes em `t-1` | 12.842 | 966 | 7,52% |

## Associacao Espacial Ajustada

| Modelo | Odds ratio | IC 95% | Leitura |
|---|---:|---:|---|
| Entrada/retorno: +10 p.p. de vizinhos participantes | 2,22 | 2,11-2,34 | Odds de entrada aproximadamente 2,2 vezes maiores. |
| Entrada nova: +10 p.p. | 2,20 | 2,09-2,31 | Associacao muito semelhante no primeiro pagamento observado. |
| Retorno: +10 p.p. | 1,26 | 1,17-1,35 | Associacao positiva, mas menor que na entrada nova. |
| Saida: +10 p.p. | 0,79 | 0,76-0,83 | Reducao aproximada de 21% nas odds de saida. |
| Candidato externo adjacente | 130,17 | 94,34-179,61 | Contraste muito elevado contra o grande universo sem vizinho participante. |
| Participante isolado | 3,98 | 2,90-5,46 | Odds de saida quase quatro vezes maiores. |
| Participante na borda | 2,97 | 1,91-4,61 | Odds de saida maiores que entre participantes sem vizinho externo. |

O odds ratio de adjacencia e elevado porque o grupo de referencia e muito amplo: entre 724.512 exposicoes sem vizinho participante ocorreram apenas 335 entradas, enquanto 1.060 entradas ocorreram entre 18.404 candidatos adjacentes. Ele nao deve ser lido como efeito causal.

## Taxas Descritivas

### Entrada Ou Retorno

| Vizinhos participantes em `t-1` | Exposicoes | Eventos | Taxa |
|---|---:|---:|---:|
| 0% | 724.512 | 335 | 0,05% |
| 0-20% | 8.347 | 196 | 2,35% |
| 20-40% | 6.362 | 310 | 4,87% |
| 40-60% | 2.365 | 268 | 11,33% |
| 60-80% | 914 | 164 | 17,94% |
| Acima de 80% | 416 | 122 | 29,33% |

### Saida

| Vizinhos participantes em `t-1` | Exposicoes | Eventos | Taxa |
|---|---:|---:|---:|
| 0% | 734 | 179 | 24,39% |
| 0-20% | 927 | 127 | 13,70% |
| 20-40% | 2.364 | 218 | 9,22% |
| 40-60% | 2.821 | 209 | 7,41% |
| 60-80% | 2.685 | 132 | 4,92% |
| Acima de 80% | 3.311 | 101 | 3,05% |

## Sensibilidades

| Regra | OR entrada por +10 p.p. | OR saida por +10 p.p. |
|---|---:|---:|
| Total positivo | 2,22 | 0,79 |
| Somente corrente positivo | 2,23 | 0,80 |
| Total minimo R$ 100 | 2,22 | 0,79 |
| Total minimo R$ 1.000 | 2,24 | 0,80 |

Os resultados sao estaveis diante de restos a pagar e pagamentos pequenos. A associacao nao parece ser produzida por esses registros residuais.

## Conclusao Provisoria

Existe associacao espacial forte, monotona e robusta: municipios cercados por participantes apresentam mais movimentos de entrada e menos movimentos de saida. O resultado justifica avancar para modelos com controles municipais e areas de politica publica.

Ainda nao se deve afirmar que a vizinhanca causa adesao ou permanencia. O MIDES observa pagamentos, a consolidacao matriz/filial esta pendente e faltam controles socioeconomicos, fiscais, politicos e institucionais.
