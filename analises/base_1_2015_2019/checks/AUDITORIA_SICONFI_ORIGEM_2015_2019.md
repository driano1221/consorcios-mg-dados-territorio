# Auditoria SICONFI - origem e definicoes 2015/2019

## Pergunta

A base `SICONFI painel munic` usada na Base 1 e reproduzivel a partir dos arquivos brutos locais? E qual definicao de valor de consorcio ela parece representar?

## Arquivos usados

- Base mestre: `base_consorcios_v10_2026-04-30.xlsx` / aba `SICONFI painel munic`.
- Bruto local: `Tabelas/Siconfi/Siconfi_municipios.xlsx`.
- Recorte: MG, anos 2015 e 2019.
- Unidade: municipio x ano.

## Definicoes comparadas

| Definicao | Como foi calculada | Interpretacao |
|---|---|---|
| Atual | `valor_cons_real` da aba `SICONFI painel munic` | Valor usado hoje no projeto |
| Restrita/rateio | `Despesas Empenhadas` + rubricas com `consorcio` e `contrato de rateio` | Leitura conservadora |
| Ampla/consorcio | `Despesas Empenhadas` + qualquer rubrica com `consorcio` | Leitura abrangente de consorcios |

## Resumo por ano

| ano | n_municipio_ano | n_atual_positivo | n_restrito_positivo | n_amplo_positivo | total_atual_mi | total_restrito_rateio_mi | total_amplo_consorcio_mi | atual_vs_restrito_pct | atual_vs_amplo_pct |
|---|---|---|---|---|---|---|---|---|---|
| 2015 | 822 | 615 | 658 | 680 | 284,68 | 129,81 | 319,15 | 119,30 | -10,80 |
| 2019 | 841 | 639 | 774 | 790 | 242,63 | 156,70 | 340,35 |  54,83 | -28,71 |

## Resumo por classe

| ano | classe_auditoria | n_municipio_ano | total_atual_mi | total_restrito_rateio_mi | total_amplo_consorcio_mi |
|---|---|---|---|---|---|
| 2015 | atual_sem_raw_consorcio | 114 |  23,93 |   0,00 |   0,00 |
| 2015 | fecha_amplo |   5 |  11,02 |   0,00 |  11,02 |
| 2015 | nao_fecha | 675 | 249,73 | 129,81 | 308,13 |
| 2015 | zero_nas_tres |  28 |   0,00 |   0,00 |   0,00 |
| 2019 | atual_sem_raw_consorcio |  39 |   8,42 |   0,00 |   0,00 |
| 2019 | fecha_amplo |   4 |   1,19 |   0,00 |   1,19 |
| 2019 | nao_fecha | 786 | 233,02 | 156,70 | 339,16 |
| 2019 | zero_nas_tres |  12 |   0,00 |   0,00 |   0,00 |

## Leitura tecnica

- A aba atual esta mecanicamente consistente como painel municipal anual, mas nao foi reproduzida exatamente pelas duas reconstrucoes simples feitas a partir do bruto local.
- Em 2015, a base atual fica 119,3% acima da definicao restrita e 10,8% abaixo da definicao ampla.
- Em 2019, a base atual fica 54,8% acima da definicao restrita e 28,7% abaixo da definicao ampla.
- Portanto, a base atual provavelmente deriva de uma regra intermediaria ou de uma etapa BigQuery/documentada que nao esta integralmente preservada como script local.

## Implicacao para a Base 1

A comparacao MIDES x SICONFI pode continuar como auditoria financeira exploratoria, mas nao deve ser apresentada como validacao definitiva ate que a regra exata de `valor_cons_real` seja reconstruida ou escolhida explicitamente.

## Recomendacao

Para a proxima versao metodologica, escolher uma definicao oficial e reprocessar a Base 1 com ela:

1. conservadora: apenas contrato de rateio;
2. abrangente: todas as rubricas de consorcio;
3. ou recuperar o SQL/script original que gerou `valor_cons_publico`.

CSV detalhado: `analises/base_1_2015_2019/outputs/base_1_auditoria_siconfi_origem_2015_2019.csv`
XLSX de checks: `analises/base_1_2015_2019/checks/base_1_auditoria_siconfi_origem_2015_2019.xlsx`
