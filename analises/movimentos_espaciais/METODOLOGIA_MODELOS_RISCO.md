# Metodologia Dos Modelos De Entrada E Saida MIDES

**Data:** 2026-07-28
**Escopo:** Minas Gerais, 2014-2021.
**Unidade:** municipio x CNPJ de consorcio x ano.

## Interpretacao

A presenca anual e definida por pagamento observado no MIDES. Portanto:

- `entrada_observada` significa inicio de pagamento na janela;
- `retorno_observado` significa pagamento apos uma lacuna;
- `saida_observada` significa ausencia de pagamento depois de um ano com pagamento;
- nenhum desses eventos prova adesao, desligamento ou extincao juridica.

CNPJs de matriz e filial continuam separados, conforme decisao vigente.

## Regra Principal E Sensibilidades

| Regra | Presenca anual |
|---|---|
| Principal | `valor_total > 0` |
| Sem restos isolados | `valor_corrente > 0` |
| Valor minimo 100 | `valor_total >= 100` |
| Valor minimo 1.000 | `valor_total >= 1.000` |

As sensibilidades nao substituem a regra principal. Elas verificam se pagamentos residuais ou restos a pagar determinam os resultados.

## Vizinhanca

- Fonte: malha municipal geobr/IBGE 2020 completa.
- Universo: 853 municipios de Minas Gerais.
- Regra: dois municipios sao vizinhos quando compartilham uma linha de fronteira com comprimento positivo.
- Contato apenas em um ponto nao e considerado.
- Resultado: 2.375 fronteiras municipais nao direcionadas.

## Universo De Saida

Para cada ano `t` entre 2015 e 2021:

1. selecionar todos os pares municipio-CNPJ com pagamento em `t-1`;
2. observar se o pagamento permanece em `t`;
3. classificar ausencia em `t` como `saida_observada`.

Todos os pares ativos em `t-1` estao expostos ao risco de saida. Na regra principal, o universo contem 12.842 exposicoes e 966 saidas.

## Universo De Entrada

Para cada CNPJ que tinha ao menos um municipio ativo em `t-1`:

1. cruzar o CNPJ com os 853 municipios mineiros;
2. excluir os municipios que ja pagavam ao CNPJ em `t-1`;
3. observar se cada nao membro passa a pagar em `t`;
4. calcular sua exposicao aos vizinhos que ja pagavam em `t-1`.

O universo principal contem 742.916 exposicoes e 1.395 entradas ou retornos. Destas, 1.060 ocorreram em municipios adjacentes a pelo menos um participante anterior.

Eventos em que o CNPJ inteiro nao tinha municipio ativo em `t-1` ficam fora do modelo espacial: 387 pertencem ao primeiro aparecimento do CNPJ na janela e 31 a reaparecimentos depois de uma lacuna completa. Sem membros anteriores, nao existe exposicao territorial interna a medir.

## Entrada Nova E Retorno

- **Entrada nova observada:** o par nao havia apresentado pagamento anteriormente na janela.
- **Retorno observado:** o par ja havia apresentado pagamento, ficou ausente e voltou.

Os modelos separados usam conjuntos de risco proprios:

- entrada nova: pares sem presenca anterior;
- retorno: pares com presenca anterior, mas inativos em `t-1`.

## Features Principais

| Feature | Interpretacao |
|---|---|
| `prop_vizinhos_no_consorcio_t_1` | Proporcao dos vizinhos que pagavam ao mesmo CNPJ no ano anterior. |
| `candidato_externo_adjacente_t_1` | Nao membro com pelo menos um vizinho participante em `t-1`. |
| `participante_isolado_t_1` | Participante sem vizinho no mesmo CNPJ em `t-1`. |
| `participante_na_borda_t_1` | Participante com pelo menos um vizinho fora do CNPJ em `t-1`. |

As contagens e os comprimentos de fronteira permanecem na base tecnica, mas nao entram simultaneamente no modelo principal para evitar redundancia entre medidas derivadas da mesma vizinhanca.

## Modelos

Foram estimadas regressoes logisticas exploratorias:

```text
evento em t ~ exposicao espacial em t-1
              + log(1 + membros do consorcio em t-1)
              + numero total de vizinhos do municipio
              + efeitos fixos de ano
```

Os erros-padrao foram agrupados em duas dimensoes: municipio e CNPJ. O efeito da proporcao e apresentado para aumento de 10 pontos percentuais.

Os modelos medem associacao condicional, nao causalidade. Ainda nao controlam populacao, capacidade fiscal, mandato municipal, area de politica publica nem regras institucionais do consorcio.

## Validacoes

- nenhuma duplicata nas chaves dos universos;
- em cada CNPJ-ano elegivel, entrada e saida particionam exatamente os 853 municipios;
- as 966 saidas originais foram recompostas;
- 1.395 eventos modelados mais 418 sem exposicao anterior recompuseram os 1.813 movimentos de entrada/retorno;
- 500 observacoes tiveram a exposicao espacial recalculada diretamente e coincidiram integralmente;
- os sinais se mantiveram nas quatro regras de presenca.
