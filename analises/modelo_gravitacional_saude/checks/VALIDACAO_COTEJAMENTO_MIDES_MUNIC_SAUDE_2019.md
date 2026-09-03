# Cotejamento MIDES X MUNIC - Consorcios De Saude Em MG, 2019

## Objetivo E Unidade

A comparacao usa a unidade `municipio x entidade consolidada` em 2019. Matriz e filiais foram reunidas pela raiz de oito digitos antes de comparar as fontes.

## Resultado Geral

| Indicador | Resultado |
|---|---:|
| Pares na uniao das fontes | 1311 |
| MIDES + MUNIC | 630 |
| Somente MIDES | 658 |
| Somente MUNIC | 23 |
| Municipios | 819 |
| Entidades com alguma evidencia em 2019 | 66 |
| Jaccard global | 48.1% |
| Pares MIDES tambem declarados na MUNIC | 48.9% |
| Pares MUNIC com pagamento MIDES | 96.5% |
| Valor MIDES em pares presentes nas duas fontes | 71.3% |

## Leitura Por Entidade

| Categoria | Entidades |
|---|---:|
| fontes_com_municipio_em_comum | 61 |
| sem_evidencia_2019 | 18 |
| somente_MIDES | 3 |
| duas_fontes_sem_municipio_em_comum | 1 |
| somente_MUNIC | 1 |

## Cobertura Documental Do Cadastro

Os indicadores abaixo mostram documentos existentes no cadastro. Eles nao comprovam que a composicao municipal documentada corresponde especificamente a 2019.

| Evidencia | Entidades |
|---|---:|
| Documento de municipios | 23 |
| Documento de rateio | 24 |
| Protocolo | 30 |
| Estatuto | 32 |
| Alguma evidencia documental | 42 |

## Maiores Divergencias Em Numero De Municipios

| CNPJ canonico | Sigla | Ambas | So MIDES | So MUNIC | Jaccard | Doc. municipios |
|---|---|---:|---:|---:|---:|---|
| `13985869000184` | CISSUL | 39 | 99 | 2 | 27.9% | Sim |
| `17813026000151` | CISDESTE | 15 | 77 | 0 | 16.3% | Sim |
| `13220150000152` | CISNORJE |  5 | 54 | 0 | 8.5% | Sim |
| `11636961000103` | CISRUN | 17 | 47 | 3 | 25.4% | Nao |
| `11938399000172` | CISRU-CENTRO SUL |  6 | 44 | 0 | 12.0% | Sim |
| `20059618000134` | CIS-URG OESTE | 18 | 36 | 0 | 33.3% | Nao |
| `20101246000167` | CONSURGE |  2 | 26 | 2 | 6.7% | Nao |
| `20310169000155` | CISTRISUL |  1 | 24 | 1 | 3.8% | Nao |
| `19455924000100` | CISTRI |  7 | 19 | 0 | 26.9% | Nao |
| `05802877000110` | CISMEP | 27 | 18 | 0 | 60.0% | Nao |
| `20433216000158` | CISREUNO |  0 | 17 | 0 | 0.0% | Nao |
| `97550393000149` | CIAS - CONSORCIO INTERMUNICIPAL DE SAUDE |  6 | 14 | 2 | 27.3% | Nao |

## Interpretacao

- `MIDES+MUNIC`: pagamento positivo e participacao declarada para o mesmo municipio e entidade em 2019.
- `somente_MIDES`: pagamento observado sem declaracao MUNIC correspondente; nao e erro automatico.
- `somente_MUNIC`: participacao declarada sem pagamento MIDES observado naquele ano; nao prova inatividade.
- A MUNIC confirma quase todos os seus pares no MIDES, mas cobre somente parte dos pares financeiros.
- Documentos cadastrais ajudam a revisar divergencias, mas nao devem ser retroagidos para 2019 sem data explicita.
- Nenhum resultado desta etapa altera o dashboard ou estima o modelo gravitacional.
