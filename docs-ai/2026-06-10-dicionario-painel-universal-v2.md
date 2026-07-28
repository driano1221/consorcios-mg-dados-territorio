# Dicionario - `painel_universal_mg_v2`

**Ultima atualizacao:** 2026-06-10  
**Arquivo atual:** `outputs/csv_base/2026-05-21_painel_universal_mg_v2.csv`  
**Dimensoes:** **3.380 linhas x 32 colunas**  
**Unidade de observacao:** par **municipio x consorcio** em MG  
**Universo:** 223 consorcios MG do cadastro IPEA  

---

## Escala De Pontuacao

| Fonte | Coluna | Pontos |
|---|---|---:|
| MIDES | `pontuacao_mides` | 8 |
| SICONFI | `pontuacao_siconfi` | 4 |
| MUNIC | `pontuacao_munic` | 2 |
| CNM | `pontuacao_cnm` | 1 |

`pontuacao_total = pontuacao_mides + pontuacao_siconfi + pontuacao_munic + pontuacao_cnm`

Pontuacao maxima: **15 pts**.

---

## Variaveis

### Identificacao Do Par

| Coluna | Tipo esperado | Descricao |
|---|---|---|
| `cod_ibge_6` | character/integer | Codigo IBGE do municipio com 6 digitos, sem digito verificador. Chave principal para joins territoriais. |
| `id_municipio` | character/integer | Codigo IBGE completo com 7 digitos, quando existe no MIDES. Pode ficar ausente em pares CNM-only. |
| `cnpj_consorcio` | character | CNPJ do consorcio, 14 digitos sem pontuacao. Deve ser tratado como texto para preservar zeros a esquerda. |
| `nome_credor_freq` | character | Nome do credor mais frequente observado no MIDES para o par. Ausente quando nao ha MIDES. |

### Cadastro Do Consorcio

| Coluna | Tipo esperado | Descricao |
|---|---|---|
| `razao_social` | character | Razao social do consorcio no cadastro IPEA. |
| `sigla` | character | Sigla do consorcio no cadastro IPEA. |
| `setores` | character | Setores do cadastro IPEA. |
| `setores_consolidado` | character | Setor consolidado usado no painel; usa cadastro quando disponivel e MUNIC como fallback. |
| `situacao` | character | Situacao cadastral do consorcio no cadastro IPEA. |
| `ano_fundacao` | integer | Ano de fundacao do consorcio segundo cadastro IPEA. |
| `tem_evidencia` | logical | Flag do cadastro IPEA para existencia de evidencia documental/cadastral. |

### MIDES

| Coluna | Tipo esperado | Descricao |
|---|---|---|
| `pontuacao_mides` | integer | 8 quando o par tem evidencia MIDES; 0 quando nao tem. |
| `ano_entrada_proxy` | integer | Primeiro ano com pagamento corrente observado no MIDES. Proxy, nao data real de entrada. |
| `ultimo_ano_corrente` | integer | Ultimo ano com pagamento corrente observado no MIDES. |
| `ainda_ativo` | logical | TRUE se houve pagamento corrente no ultimo ano da serie MIDES disponivel. |
| `valor_total_periodo` | numeric | Soma dos valores observados no MIDES para o par, deflacionados conforme base. |
| `n_anos_pagamento` | integer | Quantidade de anos distintos com pagamento corrente no MIDES. Nos slides aparece como `ANOS`. |
| `valor_atipico` | logical | TRUE para valores muito baixos, usualmente abaixo do limiar de atipicidade definido no pipeline. |
| `confianca_mides` | character | Classificacao herdada do painel MIDES. Ex.: `baixa`, `sem_evidencia`. |

Observacao importante:

> `n_anos_pagamento` nao e idade do consorcio nem duracao real do vinculo. E apenas a quantidade de anos com pagamento corrente observado no MIDES.

### SICONFI

| Coluna | Tipo esperado | Descricao |
|---|---|---|
| `pontuacao_siconfi` | integer | 4 quando SICONFI confirma; 0 quando nao confirma. |
| `siconfi_confirma` | logical | TRUE se houve pelo menos um match SICONFI nos anos de ancora. |
| `ancora` | character | Fonte usada para definir anos de comparacao. Em geral `mides`, `munic` ou `sem_ancora`. |
| `anos_siconfi_match` | character | Lista de anos em que houve match SICONFI. |
| `n_anos_siconfi_match` | integer | Numero de anos com match SICONFI. |

Regras:

- SICONFI pontua com 4 pts se houver **ao menos um match**.
- A quantidade de anos nao aumenta a pontuacao, mas fica registrada em `n_anos_siconfi_match`.
- SICONFI nao identifica o CNPJ destino; confirma que o municipio pagou algum consorcio no ano.
- Periodo valido usado no pipeline: **2013-2024** (`nota_cobertura = "ok"`).

Nota metodologica apos reuniao de 2026-05-29:

> SICONFI deve ser lido como evidencia municipal indireta. Ele reforca que o municipio declarou transferencia para consorcios, mas nao confirma sozinho qual par municipio x consorcio recebeu o recurso. Para interpretacao detalhada, ver `docs/ATAS_REUNIOES.md`.

### MUNIC

| Coluna | Tipo esperado | Descricao |
|---|---|---|
| `pontuacao_munic` | integer | 2 quando MUNIC confirma; 0 quando nao confirma. |
| `munic_confirma` | logical | TRUE quando o municipio declarou participar do consorcio. |
| `anos_munic` | character | Anos MUNIC em que o par aparece. No pipeline atual: 2015 e/ou 2019. |
| `setores_munic` | character | Setores declarados no MUNIC para aquele par. |

Regra:

> MUNIC e autodeclaratorio e so tem estrutura util de municipio x CNPJ em 2015 e 2019.

### Total E CNM

| Coluna | Tipo esperado | Descricao |
|---|---|---|
| `pontuacao_total` | integer | Soma das quatro fontes na escala atual. Maximo 15. |
| `n_fontes` | integer | Numero de fontes que confirmam o par. Vai de 1 a 4. |
| `cnm_confirma` | logical | TRUE quando a Plataforma CNM confirma o vinculo municipio x consorcio. |
| `pontuacao_cnm` | integer | 1 quando CNM confirma; 0 quando nao confirma. |

---

## Exemplos

### Abaete x COMASF

| Campo | Valor |
|---|---|
| `cod_ibge_6` | 310020 |
| `sigla` | COMASF |
| `pontuacao_total` | 15 |
| `pontuacao_mides` | 8 |
| `pontuacao_siconfi` | 4 |
| `pontuacao_munic` | 2 |
| `pontuacao_cnm` | 1 |
| `n_anos_pagamento` | 8 |
| `anos_siconfi_match` | 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021 |
| `anos_munic` | 2015, 2019 |

Interpretacao:

> O par aparece nas quatro fontes. Os 8 anos indicam pagamento corrente observado no MIDES de 2014 a 2021, nao idade real do vinculo.

---

## Distribuicoes De Referencia

| Indicador | Valor |
|---|---:|
| Total de pares | 3.380 |
| Pares com CNM | 2.657 |
| Pares sem CNM | 723 |
| Pares CNM-only | 493 |
| Pares com 4 fontes | 1.037 |
| Pares com 3 fontes | 1.124 |
| Pares com 2 fontes | 615 |
| Pares com 1 fonte | 604 |

---

## Auditoria Externa Ao Universo

Arquivo complementar:

`outputs/auditoria/2026-05-29_candidatos_fora_cadastro_mg.csv`

Contem CNPJs/vinculos que aparecem em MUNIC/CNM com municipios MG, mas ficam fora do painel principal por nao pertencerem aos 223 consorcios MG do cadastro IPEA.

Resumo:

- 143 CNPJs candidatos.
- 843 pares municipio x consorcio.
- Maior caso: CONECTAR, sede DF, 414 vinculos CNM-MG.

Esses registros nao entram no `painel_universal_mg_v2` sem revisao metodologica do universo.
