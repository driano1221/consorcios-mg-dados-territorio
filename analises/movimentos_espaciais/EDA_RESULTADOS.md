# EDA E Validacao Dos Movimentos Espaciais MIDES

**Data:** 2026-07-28
**Escopo:** MIDES completo, 2014-2021.
**Unidade:** municipio x CNPJ de consorcio x ano.
**Regra de presenca:** valor total MIDES positivo.

## Conclusao

A base esta estruturalmente consistente e pode seguir para validacao substantiva. Nao foram encontrados valores negativos, duplicatas de chave, perda de valores na materializacao ou municipios sem vizinhos.

Os alertas encontrados nao invalidam a base, mas precisam ser considerados antes de uma analise estatistica ou publicacao:

1. movimentos gerados apenas por restos a pagar;
2. pagamentos positivos muito pequenos;
3. transicoes internas entre matriz e filial mantidas como CNPJs separados;
4. nomes MIDES muito ruidosos, inadequados como chave;
5. a expressao municipio_borda_t_1 tem semantica diferente para membros e candidatos externos e deve ser separada antes do uso no dashboard.

## Integridade

| Indicador | Resultado |
|---|---:|
| Linhas balanceadas | 22.680 |
| Pares municipio-CNPJ | 2.835 |
| Municipios | 853 |
| CNPJs | 161 |
| Anos | 8 |
| Duplicatas de chave | 0 |
| Valores negativos | 0 |
| Registros explicitos com valor zero | 4 |
| Linhas com presenca observada | 15.131 |
| Diferenca financeira contra a origem | R$ 0 |

## Movimento Anual

| Ano | Pares ativos | Entradas novas | Retornos | Saidas | Permanencias | Saldo |
|---:|---:|---:|---:|---:|---:|---:|
| 2014 | 1.442 | 0 | 0 | 0 | 0 | 0 |
| 2015 | 1.729 | 432 | 0 | 145 | 1.297 | +287 |
| 2016 | 1.751 | 149 | 44 | 171 | 1.558 | +22 |
| 2017 | 1.804 | 159 | 97 | 203 | 1.548 | +53 |
| 2018 | 1.936 | 144 | 89 | 101 | 1.703 | +132 |
| 2019 | 2.060 | 177 | 59 | 112 | 1.824 | +124 |
| 2020 | 2.120 | 100 | 52 | 92 | 1.968 | +60 |
| 2021 | 2.289 | 232 | 79 | 142 | 1.978 | +169 |

Entre 2014 e 2021, os pares ativos cresceram 58,7%. Foram observadas 1.393 entradas novas, 420 retornos e 966 saidas. O resultado descreve pagamentos observados e nao prova adesao ou desligamento juridico.

## Recorrencia

| Transicoes no par | Pares |
|---:|---:|
| 0 | 1.014 |
| 1 | 1.148 |
| 2 | 446 |
| 3 | 180 |
| 4 | 36 |
| 5 | 11 |

Ha 673 pares recorrentes, definidos por duas ou mais transicoes. O padrao mais frequente e presenca em todos os oito anos, com 1.014 pares.

## Resultado Espacial Descritivo

### Saida segundo integracao no ano anterior

| Vizinhos no mesmo consorcio em t-1 | Exposicoes | Saidas | Taxa |
|---|---:|---:|---:|
| 0% | 734 | 179 | 24,4% |
| 0-20% | 927 | 127 | 13,7% |
| 20-40% | 2.364 | 218 | 9,2% |
| 40-60% | 2.821 | 209 | 7,4% |
| 60-80% | 2.685 | 132 | 4,9% |
| Acima de 80% | 3.311 | 101 | 3,1% |

A associacao descritiva e monotona: quanto maior a proporcao de vizinhos participantes, menor a taxa de saida observada. Municipios isolados tiveram taxa de 24,4%, contra 2,8% para participantes sem fronteira externa. Isso e evidencia descritiva forte, mas ainda nao e causal.

### Entrada entre candidatos externos de borda

| Vizinhos ja participantes em t-1 | Candidatos | Entradas | Taxa |
|---|---:|---:|---:|
| Ate 20% | 8.347 | 196 | 2,4% |
| 20-40% | 6.362 | 310 | 4,9% |
| 40-60% | 2.365 | 268 | 11,3% |
| 60-80% | 914 | 164 | 17,9% |
| Acima de 80% | 416 | 122 | 29,3% |

Das 1.813 entradas ou retornos, 1.060 (58,5%) ocorreram em municipios que ja faziam fronteira com algum participante do consorcio no ano anterior. As outras 753 ocorreram sem vizinho participante em t-1, portanto a expansao nao e explicada apenas por contiguidade territorial.

## Alertas De Qualidade

| Alerta | Dimensao | Interpretacao |
|---|---:|---|
| Linhas positivas apenas com restos a pagar | 252 | Representam 1,67% das presencas anuais. |
| Entradas/retornos apenas por restos | 62 | Podem refletir obrigacao antiga, nao atividade corrente. |
| Pares que so possuem restos no periodo | 19 | Exigem leitura cautelosa como vinculo historico. |
| Valores positivos abaixo de R$ 100 | 13 | Contam como presenca pela regra aprovada, mas merecem sensibilidade. |
| Valores positivos abaixo de R$ 1.000 | 184 | Podem ser pagamentos residuais ou registros validos de baixo valor. |
| Raizes com mais de um CNPJ no MIDES | 5 | Matriz e filial continuam separadas. |
| Transicoes em raizes com varios CNPJs | 180 | 25 parecem troca interna de CNPJ enquanto a raiz permaneceu ativa. |
| Municipio-raiz-ano com dois CNPJs ativos | 21 | Pode haver duplicidade institucional antes da consolidacao. |
| CNPJs com mais de um nome MIDES | 150 de 161 | Nome e texto declarado; CNPJ deve continuar como chave. |
| Alias evidentemente invalido | 1 | O CNPJ 19746706000125 aparece com nome "." em ao menos um registro. |
| Registros explicitos com valor zero | 4 | Foram corretamente classificados como ausencia pela regra valor_total > 0. |

## Amostra Aleatoria Reproduzivel

Semente utilizada: 20260728.

| Evento | Ano | Municipio | CNPJ | Leitura |
|---|---:|---|---|---|
| Entrada | 2021 | Pote | 13220150000152 | Todos os vizinhos ja participavam; forte exposicao territorial. |
| Entrada | 2018 | Conselheiro Pena | 30249525000126 | Sem vizinho participante em t-1; entrada nao contigua. |
| Entrada | 2019 | Abaete | 05802877000110 | 20% dos vizinhos participavam no ano anterior. |
| Retorno | 2017 | Mathias Lobato | 01311508000173 | Retorno apos lacuna; 66,7% dos vizinhos participavam. |
| Retorno | 2018 | Ibiracatu | 21505692000108 | Retorno cercado por vizinhos participantes. |
| Saida | 2018 | Itapeva | 01990521000104 | Nenhum vizinho no mesmo consorcio; caso espacialmente isolado. |
| Saida | 2019 | Vespasiano | 97550393000149 | 42,9% dos vizinhos permaneciam no consorcio. |
| Saida | 2021 | Santa Rita do Itueto | 23304346000189 | 40% dos vizinhos participavam em t-1. |

A amostra apresentou sequencias coerentes com as regras. Os casos estranhos encontrados sao explicados principalmente por pagamentos pequenos, restos a pagar, nomes declarados ruins ou alternancia entre CNPJs relacionados.

## Ajustes Recomendados Antes Do Dashboard

1. Manter a base principal como esta, pois sua integridade foi confirmada.
2. Criar uma analise de sensibilidade excluindo presencas formadas somente por restos e valores abaixo de um limite definido, sem substituir a regra principal.
3. Renomear/separar municipio_borda_t_1:
   - para membro: participante com vizinho externo;
   - para candidato: municipio externo adjacente ao consorcio.
4. Usar nome canonico do cadastro para exibicao e preservar o nome MIDES apenas como campo de auditoria.
5. Manter o alerta matriz/filial e comparar resultados antes/depois da futura consolidacao.
6. Somente depois estimar modelos ou integrar os resultados ao dashboard.
