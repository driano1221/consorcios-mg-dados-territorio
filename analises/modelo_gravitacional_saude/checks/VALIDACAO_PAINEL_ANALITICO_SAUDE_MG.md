# Validacao: Painel Analitico De Saude (MG)

- Grade completa: **573.216** linhas.
- Municipios: **853**; entidades: **84**; anos: **8**.
- Linhas MIDES de saude antes da consolidacao: **10.080**; linhas municipio-entidade-ano consolidadas: **10.059**.
- Valor MIDES conservado: **R$ 3.101.980.422,83**.

## Eventos

| Evento | Linhas |
|---|---:|
| ausencia | 492.165 |
| ausencia_inicial_2014 | 70.460 |
| permanencia | 8.188 |
| estoque_inicial_2014 | 1.192 |
| interrupcao_observada | 533 |
| primeiro_pagamento_observado | 426 |
| retorno_observado | 252 |

## Universos Preliminares

| Universo | Linhas | Eventos positivos |
|---|---:|---:|
| primeiro_pagamento | 317.644 | 329 |
| entrada_ou_retorno | 318.588 | 553 |
| retorno | 944 | 224 |
| interrupcao | 8.524 | 530 |
| interrupcao_com_tempo | 8.111 | 427 |
| intensidade_observada | 9.828 | NA |
| intensidade_com_tempo | 9.386 | NA |

## Regras Protegidas

- `estoque_inicial_2014` nao e tratado como entrada: o inicio real pode ser anterior a janela.
- `presente_mides` significa pagamento positivo, nao filiacao juridica.
- matriz e filiais sao consolidadas antes de calcular movimentos; o valor financeiro e conservado.
- entidades sem unidade fixa permanecem no painel, com tempo e capacidade nao observados.
- os universos de risco sao exploratorios; o conjunto final de alternativas ainda depende de regra territorial ou de tempo.
- populacao, RCL, regiao de saude, bacia e mandato ainda nao foram integrados porque nao ha fonte anual validada nesta trilha.

## Leitura Do Produto

O RDS completo preserva inclusive os zeros. Os CSVs sao recortes auditaveis de eventos, pares e resumos, evitando um CSV integral muito grande e redundante.
