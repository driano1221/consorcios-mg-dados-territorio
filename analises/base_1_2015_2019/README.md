# Base 1 - 2015/2019

**Status:** frente metodologica tangente ao painel principal  
**Criado em:** 2026-06-10  
**Escopo:** Minas Gerais, anos 2015 e 2019  

---

## Objetivo

Construir uma base experimental para testar a leitura temporal das fontes em anos comparaveis.

A Base 1 usa os anos em que a MUNIC possui informacao de participacao em consorcios:

- 2015;
- 2019.

CNM fica fora desta frente, porque e um retrato atual e nao permite reconstruir os vinculos de 2015/2019.

Metodologia completa:

`METODOLOGIA.md`

---

## Principio Metodologico

A base principal v2 segue como retrato integrado de evidencias.

Esta frente cria uma leitura separada:

> Base 1 = vinculos municipio x consorcio x ano observados em MIDES e/ou MUNIC, com SICONFI reservado para validacao financeira posterior no nivel municipio x ano.

SICONFI nao cria par municipio x consorcio, pois nao identifica o CNPJ destino.

---

## Estrutura

```text
base_1_2015_2019/
+-- README.md
+-- scripts/
|   +-- 01_base_vinculos_2015_2019.R
|   +-- 02_eda_base_vinculos_2015_2019.R
|   +-- 03_validacao_siconfi_2015_2019.R
|   +-- 04_auditoria_siconfi_origem.R
|   +-- 05_reconstruir_siconfi_base_dos_dados.R
|   +-- 06_validacao_siconfi_reconstruido_2015_2019.R
+-- outputs/
+-- checks/
+-- figures/
```

---

## Outputs Planejados

| Output | Unidade | Status |
|---|---|---|
| `base_1_vinculos_2015_2019.csv` | municipio x consorcio x ano | item 2 |
| `checks/EDA_base_1_vinculos_2015_2019.md` | diagnostico da base de vinculos | concluido |
| `checks/base_1_eda_vinculos_2015_2019.xlsx` | planilhas de checks e anomalias | concluido |
| `base_1_validacao_siconfi_2015_2019.csv` | municipio x ano | concluido |
| `base_1_resumo_executivo.csv` | metricas agregadas | concluido |
| `base_1_auditoria_siconfi_origem_2015_2019.csv` | municipio x ano | concluido |
| `checks/AUDITORIA_SICONFI_ORIGEM_2015_2019.md` | auditoria da definicao SICONFI | concluido |
| `base_1_siconfi_reconstruido_2015_2019.csv` | municipio x ano | concluido |
| `checks/RECONSTRUCAO_SICONFI_BASE_DOS_DADOS_2015_2019.md` | reconstrucao via Base dos Dados | concluido |
| `base_1_validacao_siconfi_reconstruido_2015_2019.csv` | municipio x ano | concluido |
| `base_1_validacao_siconfi_reconstruido_sensibilidade_5_10.csv` | municipio x ano x tolerancia | concluido |
| `checks/REVISAO_FONTES_MIDES_MUNIC_SICONFI.md` | revisao das fontes e scripts | concluido |
| `checks/base_1_materiais_reuniao.xlsx` | exemplos e resumo para reuniao | concluido |
| `checks/ROTEIRO_REUNIAO_BASE1.md` | roteiro de fala e perguntas | concluido |

---

## Fontes Usadas No Item 2

| Fonte | Arquivo | Papel |
|---|---|---|
| MIDES | `dados/processado/painel_mg_anual.rds` | pagamento observado por municipio x consorcio x ano |
| MUNIC | `base_consorcios_v10_2026-04-30.xlsx`, aba `MUNIC participacao` | vinculo declarado por municipio x consorcio x ano |
| Cadastro IPEA | mesma planilha, aba `Cadastro` | metadados dos consorcios e recorte MG |

---

## Regras Do Item 2

- anos restritos a 2015 e 2019;
- universo restrito aos 223 consorcios MG do cadastro IPEA;
- pares podem vir de MIDES, MUNIC ou ambos;
- linhas da MUNIC repetidas por setor sao agregadas em uma linha por par/ano;
- valores financeiros do MIDES usam `valor_corrente` e `valor_total`;
- nomes de municipios foram adicionados a partir de MUNIC/SICONFI para facilitar revisao;
- `setores_consolidado` usa o cadastro quando existe e MUNIC como fallback;
- CNM nao entra;
- SICONFI nao entra ainda, entra na validacao financeira posterior.

---

## EDA Inicial

Resultado geral:

- base estruturalmente consistente;
- sem duplicatas na chave `ano + cod_ibge_6 + cnpj_consorcio`;
- sem CNPJ ou codigo IBGE invalido;
- sem valores negativos;
- todos os registros possuem `razao_social`;
- 2 registros MIDES em 2019 possuem transacoes e `tem_pagamento_corrente = TRUE`, mas valor total igual a zero; devem ser tratados como anomalia residual na validacao financeira;
- 79 registros MIDES possuem valor positivo ate R$ 1.000; devem ser mantidos, mas revisados como possiveis taxas, registros residuais ou pagamentos muito baixos.

---

## Validacao SICONFI

Script:

`scripts/03_validacao_siconfi_2015_2019.R`

Outputs:

- `outputs/base_1_validacao_siconfi_2015_2019.csv`
- `outputs/base_1_validacao_siconfi_2015_2019.xlsx`
- `outputs/base_1_resumo_executivo.csv`
- `checks/VALIDACAO_SICONFI_base_1_2015_2019.md`
- `checks/base_1_checks_validacao_siconfi_2015_2019.xlsx`

Regra:

- unidade: `municipio x ano`;
- comparacao principal: `valor_mides_corrente_cadastro_1194` vs `valor_cons_real` do SICONFI;
- `valor_mides_corrente_base1_223` fica no output como contexto do recorte de vinculos MG;
- tolerancia: ate R$ 10.000 ou ate 10% de diferenca relativa;
- SICONFI nao cria par municipio x consorcio.

Resultado inicial:

| Ano | Municipio-ano | Congruente | Divergente valor | MIDES sem SICONFI | SICONFI sem MIDES | MUNIC sem fluxo | Congruencia entre ambos positivos |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 2015 | 838 | 85 | 505 | 217 | 25 | 6 | 14,4% |
| 2019 | 849 | 88 | 546 | 206 | 5 | 4 | 13,9% |

Leitura:

> A congruencia financeira direta e baixa. Isso reforca que o SICONFI deve ser usado como diagnostico financeiro agregado por municipio-ano, nao como confirmacao automatica de par municipio x consorcio.

Nota de revisao:

> A validacao financeira usa os 1.194 CNPJs do cadastro IPEA no MIDES, nao apenas os 223 consorcios MG da Base 1. Isso e metodologicamente mais coerente porque o SICONFI nao informa o CNPJ/UF do consorcio destino.

---

## Auditoria Da Origem SICONFI

Script:

`scripts/04_auditoria_siconfi_origem.R`

Outputs:

- `outputs/base_1_auditoria_siconfi_origem_2015_2019.csv`
- `checks/base_1_auditoria_siconfi_origem_2015_2019.xlsx`
- `checks/AUDITORIA_SICONFI_ORIGEM_2015_2019.md`

Resultado:

| Ano | Atual | Restrita/rateio | Ampla/consorcio |
|---:|---:|---:|---:|
| 2015 | R$ 284,68 mi | R$ 129,81 mi | R$ 319,15 mi |
| 2019 | R$ 242,63 mi | R$ 156,70 mi | R$ 340,35 mi |

Leitura:

> A aba SICONFI atual esta consistente como painel municipal anual, mas sua regra exata de composicao nao foi reproduzida integralmente a partir do bruto local. Por enquanto, ela deve ser apresentada como auditoria financeira exploratoria, nao como validacao definitiva.

---

## Reconstrucao SICONFI Via Base Dos Dados

Script:

`scripts/05_reconstruir_siconfi_base_dos_dados.R`

Outputs:

- `outputs/base_1_siconfi_reconstruido_2015_2019.csv`
- `checks/base_1_siconfi_reconstruido_ranking_variantes.csv`
- `checks/base_1_siconfi_reconstruido_2015_2019.xlsx`
- `checks/RECONSTRUCAO_SICONFI_BASE_DOS_DADOS_2015_2019.md`

Fonte executada:

- `br_me_siconfi.municipio_despesas_orcamentarias`;
- BigQuery/Base dos Dados com billing `ipea-consorcios`;
- MG, anos 2015 e 2019;
- valores deflacionados para jan/2018.

Resultado:

| Variante | Total reconstruido | Diferenca contra aba atual |
|---|---:|---:|
| `consorcio_pagas` | R$ 580,32 mi | +R$ 53,02 mi |
| `consorcio_liquidadas` | R$ 614,23 mi | +R$ 86,92 mi |
| `consorcio_empenhadas` | R$ 659,67 mi | +R$ 132,36 mi |
| `rateio_pagas` | R$ 261,18 mi | -R$ 266,12 mi |

Leitura:

> A melhor aproximacao reproduzivel foi `consorcio_pagas`, mas ela ainda nao reproduz exatamente a aba herdada. Assim, a solucao metodologica mais limpa e escolher explicitamente uma regra SICONFI reprocessavel para a Base 1, em vez de depender da aba herdada sem script completo.

---

## Base Final MIDES + MUNIC + SICONFI

Script:

`scripts/06_validacao_siconfi_reconstruido_2015_2019.R`

Outputs:

- `outputs/base_1_validacao_siconfi_reconstruido_2015_2019.csv`
- `outputs/base_1_validacao_siconfi_reconstruido_2015_2019.xlsx`
- `outputs/base_1_resumo_executivo_siconfi_reconstruido.csv`
- `checks/VALIDACAO_SICONFI_RECONSTRUIDO_base_1_2015_2019.md`
- `checks/base_1_checks_validacao_siconfi_reconstruido_2015_2019.xlsx`

Regra:

> MIDES e MUNIC formam os vinculos em `municipio x consorcio x ano`; SICONFI entra depois, em `municipio x ano`, como validacao financeira agregada pela regra `consorcio_pagas`.

Resultado:

| Ano | Municipio-ano | Congruente | Divergente valor | MIDES sem SICONFI | SICONFI sem MIDES | MUNIC sem fluxo | Congruencia entre ambos positivos |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 2015 | 835 | 142 | 517 | 148 | 17 | 11 | 21,5% |
| 2019 | 847 | 373 | 411 | 56 | 4 | 3 | 47,6% |

Sensibilidade da tolerancia relativa:

| Tolerancia | Ano | Congruente | Divergente valor | Taxa entre ambos positivos |
|---:|---:|---:|---:|---:|
| 5% | 2015 | 122 | 537 | 18,5% |
| 5% | 2019 | 325 | 459 | 41,5% |
| 10% | 2015 | 142 | 517 | 21,5% |
| 10% | 2019 | 373 | 411 | 47,6% |

---

## Materiais Para Reuniao

Slide curto:

`slides/2026-06-11_base1_reuniao_curta.html`

Materiais de apoio:

- `checks/base_1_materiais_reuniao.xlsx`
- `checks/ROTEIRO_REUNIAO_BASE1.md`

Conteudo:

- mensagem central;
- estrutura das 3 bases;
- pipeline de uniao;
- regra SICONFI;
- resultado 5% vs 10%;
- perguntas de decisao para a reuniao.
