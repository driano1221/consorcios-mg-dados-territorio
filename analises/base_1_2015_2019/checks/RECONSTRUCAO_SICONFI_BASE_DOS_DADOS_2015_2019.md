# Reconstrucao SICONFI - Base dos Dados 2015/2019

## Objetivo

Refazer o SICONFI em R com regras explicitas e comparar cada regra contra a aba herdada `SICONFI painel munic`.

## Fonte usada nesta execucao

- Fonte efetiva: `base_dos_dados_bigquery`.
- BigQuery/Base dos Dados executado com sucesso.
- Tabela alvo: `br_me_siconfi.municipio_despesas_orcamentarias`.
- Recorte: MG, anos 2015 e 2019.
- Valores: deflacionados para jan/2018 quando a fonte efetiva e BigQuery; no bruto local, os valores ja estavam deflacionados pelo script historico.

## Ranking das variantes

| variante | n_reconstruido_positivo | total_atual_mi | total_reconstruido_mi | diferenca_total_mi | soma_diferenca_abs_municipal_mi | n_fecha_exato | n_fecha_10k_ou_10pct |
|---|---|---|---|---|---|---|---|
| consorcio_pagas | 1.464 | 527,3 |   580,32 |    -53,02 |   303,49 | 76 | 291 |
| consorcio_liquidadas | 1.470 | 527,3 |   614,23 |    -86,92 |   311,15 | 79 | 280 |
| consorcio_empenhadas | 1.470 | 527,3 |   659,67 |   -132,36 |   318,15 | 80 | 268 |
| rateio_pagas | 1.424 | 527,3 |   261,18 |    266,12 |   568,60 | 73 | 168 |
| rateio_liquidadas | 1.431 | 527,3 |   278,93 |    248,37 |   573,68 | 71 | 169 |
| rateio_empenhadas | 1.432 | 527,3 |   286,68 |    240,63 |   578,69 | 71 | 171 |
| consorcio_sem_rp | 1.470 | 527,3 | 1.854,22 | -1.326,91 | 1.452,66 | 71 | 112 |
| consorcio_com_rp | 1.471 | 527,3 | 1.926,34 | -1.399,04 | 1.523,22 | 70 | 110 |
| original_gabriel_empenhadas | 1.663 | 527,3 | 5.394,41 | -4.867,11 | 4.867,11 | 78 | 126 |

## Tres melhores variantes por ano

| ano | variante | total_atual_mi | total_reconstruido_mi | diferenca_total_mi | soma_diferenca_abs_municipal_mi | n_fecha_10k_ou_10pct |
|---|---|---|---|---|---|---|
| 2015 | consorcio_pagas | 284,68 | 275,12 |   9,56 | 159,94 | 131 |
| 2015 | consorcio_empenhadas | 284,68 | 319,15 | -34,48 | 161,53 | 128 |
| 2015 | consorcio_liquidadas | 284,68 | 290,48 |  -5,80 | 163,11 | 134 |
| 2019 | consorcio_pagas | 242,63 | 305,21 | -62,58 | 143,55 | 160 |
| 2019 | consorcio_liquidadas | 242,63 | 323,75 | -81,12 | 148,04 | 146 |
| 2019 | consorcio_empenhadas | 242,63 | 340,51 | -97,89 | 156,62 | 140 |

## Melhor aproximacao

- Melhor variante por menor soma de diferencas absolutas municipais: `consorcio_pagas`.

## Leitura metodologica

- Esta reconstrucao transforma a duvida em um teste reproduzivel.
- Se a melhor variante ainda nao fechar bem com a aba atual, a conclusao e que a aba herdada nao deve ser tratada como regra oficial sem recuperar o SQL/script original.
- Nesse caso, a recomendacao e escolher explicitamente uma regra nova e reprocessar a validacao MIDES x SICONFI com ela.

## Outputs

- `analises/base_1_2015_2019/outputs/base_1_siconfi_reconstruido_2015_2019.csv`
- `analises/base_1_2015_2019/checks/base_1_siconfi_reconstruido_ranking_variantes.csv`
- `analises/base_1_2015_2019/checks/base_1_siconfi_reconstruido_2015_2019.xlsx`
