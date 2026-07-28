# Registro de Etapas — ideiaMides MG
**Criado em:** 2026-05-14
**Projeto:** Painel longitudinal de participação municipal em consórcios intermunicipais — Piloto MG
**Escopo:** Etapas 6, 7 e 8 (nomenclatura interna: 6, 7 e 7b)

---

## Etapa 6 — CSV Base MIDES MG (2026-05-13)

### Objetivo

Enriquecer o `painel_mg_participacao.rds` (produto bruto do script 02) com variáveis analíticas e exportar o primeiro produto entregável do projeto: o CSV base MIDES MG.

### Inputs

| Arquivo | Descrição | Dimensão |
|---|---|---|
| `dados/processado/painel_mg_participacao.rds` | 1 linha por par município × consórcio | 2.835 × 11 |
| `dados/processado/painel_mg_anual.rds` | 1 linha por município × consórcio × ano | 15.135 × 9 |
| `geobr::read_municipality(year = 2020)` | Nomes oficiais dos municípios MG | — |

### Pipeline

```
painel_mg_participacao.rds  [2.835 × 11]
painel_mg_anual.rds         [15.135 × 9]
geobr (nomes municípios)
         ↓
    enriquecimento inline
         ↓
2026-05-13_csv_base_mides_mg_v1.csv/.xlsx  [2.835 × 15]
```

### Lógica das variáveis construídas

**`flag_continuo`**
```r
# Para cada par: pegar só pagamentos correntes
# Calcular n_anos (observados) e n_anos_esperado (intervalo completo)
# continuo    → n_anos == n_anos_esperado E n_anos > 1
# descontinuo → n_anos <  n_anos_esperado E n_anos > 1
# ponto_unico → n_anos == 1
# NA          → 19 pares sem_evidencia (sem pagamento corrente)
```

**`censura_esquerda`**
- `TRUE` se `ano_entrada_proxy == 2014`
- `NA` se sem_evidencia
- Motivo: MIDES MG começa em 2014; entrada real pode ser anterior

**`censura_direita`**
- `TRUE` se `ultimo_ano_corrente == 2021 & sem_evidencia_saida == TRUE`
- Motivo: base truncada em 2021; não sabemos se relação continua

**`sem_evidencia_saida`** (renomeado de `ainda_ativo`)
- `TRUE` = sem registro de parada no período observado
- Renomeação necessária: `ainda_ativo` implicava status real, mas era só truncamento da base

**`pontuacao_mides = 4L`** para todos os pares (base MIDES por definição)

### EDA — Verificações de integridade

| Verificação | Resultado |
|---|---|
| Duplicatas `cod_ibge × cnpj` | 0 ✅ |
| `ano_entrada > ultimo_ano` | 0 ✅ |
| Inconsistências `anos_pagamento × n_anos_pagamento` | 0 ✅ |
| Valores negativos ou zero em `valor_total` | 0 ✅ |

### Distribuições principais

| Variável | Breakdown |
|---|---|
| `flag_continuo` | continuo: 1.960 (69,1%) / descontinuo: 431 (15,2%) / ponto_unico: 425 (15%) / NA: 19 (0,7%) |
| `confianca` | baixa: 2.816 (99,3%) / sem_evidencia: 19 (0,7%) |
| `sem_evidencia_saida` | TRUE: 2.280 (80,4%) / FALSE: 555 (19,6%) |
| `ano_entrada_proxy` | 2014: 1.429 / 2015: 420 / 2016: 149 / 2017: 161 / 2018: 144 / 2019: 180 / 2020: 99 / 2021: 234 / NA: 19 |
| `n_anos_pagamento` | mín: 0 / mediana: 6 / média: 5,25 / máx: 8 |
| `valor_total` | mín: R$49 / mediana: R$218k / média: R$1,34M / máx: R$264M |

**Descontínuos — lacunas:**
- 1 ano: 235 pares
- 2 anos: 107 pares
- 3+ anos: 89 pares
- Média: 1,8 anos

### Bugs e anomalias encontradas

| # | Problema | Causa | Correção |
|---|---|---|---|
| 🔴 | `ainda_ativo = TRUE` em 100% dos 2.280 pares — parecia "ativo hoje" | Era truncamento da base (MIDES MG termina em 2021) | Renomeado para `sem_evidencia_saida` + adicionados `censura_esquerda` e `censura_direita` |
| 🟡 | `flag_continuo = "continuo"` para 425 pares com 1 único pagamento | Matematicamente correto (1 == 1), mas semanticamente errado | Nova categoria `"ponto_unico"` quando `n_anos == 1` |
| 🟡 | 65 pares com `ponto_unico` e `censura_esquerda = TRUE` | Pagamento único em 2014 — não sabemos entrada nem saída | Tratados via `censura_esquerda + flag_continuo = ponto_unico` |
| 🟡 | 133 pares com saída aparente em 2020 | `ultimo_ano_corrente = 2020` — pode ser saída real ou gap | Identificáveis via `ultimo_ano_corrente < 2021` |
| 🟢 | Outlier Betim × CISMEP: R$264M | ~R$66M/ano 2014–2017, queda para R$3M em 2018 | Real — confirmado como mudança estrutural. CNPJ CISMEP: `05802877000110` |
| 🟢 | 19 `sem_evidencia` com `valor_total > 0` | Valor vem de restos a pagar (dívidas de anos anteriores) | Correto — identificáveis via `confianca == "sem_evidencia"` |

### Colunas do output

| Coluna | Tipo | Descrição |
|---|---|---|
| `cod_ibge` | chr | Código IBGE 7 dígitos |
| `nome_municipio` | chr | Nome oficial via geobr |
| `cnpj_consorcio` | chr | CNPJ 14 dígitos |
| `nome_consorcio` | chr | Nome mais frequente do consórcio no MIDES |
| `anos_pagamento` | chr | Ex: "2014, 2015, 2017, 2021" |
| `flag_continuo` | chr | `continuo` / `descontinuo` / `ponto_unico` / NA |
| `ano_entrada_proxy` | dbl | Primeiro ano com pagamento corrente |
| `ultimo_ano_corrente` | dbl | Último ano com pagamento corrente |
| `sem_evidencia_saida` | lgl | TRUE = sem registro de parada no período |
| `censura_esquerda` | lgl | TRUE = entrada proxy = 2014 |
| `censura_direita` | lgl | TRUE = último ano = 2021 e sem saída observada |
| `valor_total` | dbl | Soma pagamentos correntes + restos a pagar (R$ jan/2018) |
| `n_anos_pagamento` | int | Nº de anos com ao menos 1 pagamento corrente |
| `confianca` | chr | `baixa` / `sem_evidencia` |
| `pontuacao_mides` | int | 4 para todos |

### Output

```
outputs/csv_base/2026-05-13_csv_base_mides_mg_v1.csv   — 2.835 × 15
outputs/csv_base/2026-05-13_csv_base_mides_mg_v1.xlsx  — idem
```

---

## Etapa 7 — Sistema de Pontuação MIDES-ancorado (2026-05-14)

### Objetivo

Integrar SICONFI e MUNIC ao painel MIDES via sistema de pontuação acumulada por fonte. Cada par (município × consórcio) recebe pontos de acordo com quantas fontes independentes confirmam a relação.

**Sistema de pontuação (definido na reunião 07/05/2026):**
| Fonte | Pontos | Critério |
|---|---|---|
| MIDES | 4 | Pagamento efetivo via TCE-MG |
| SICONFI | 3 | Município pagou algum consórcio no mesmo ano (rubrica .71.) |
| MUNIC | 2 | Município declarou filiação em 2015 ou 2019 |
| CNM | 1 | Placeholder — Etapa 9 |

Máximo atual: **9 pts** (CNM ainda não implementado). Máximo futuro: 10 pts.

### Inputs

| Arquivo | Dimensão | Filtro aplicado |
|---|---|---|
| `dados/processado/painel_mg_participacao.rds` | 2.835 × 11 | — |
| `dados/processado/painel_mg_anual.rds` | 15.135 × 9 | — |
| `base_consorcios_v10.xlsx` aba "SICONFI painel munic" | 70.944 × 9 | uf == "MG" + nota_cobertura == "ok" → **9.975 linhas** (2013–2024) |
| `base_consorcios_v10.xlsx` aba "MUNIC participacao" | 18.276 × 10 | uf_mun == "MG" → **3.287 linhas** (2015 e 2019) |

**Nota SICONFI:** cobertura usada = `nota_cobertura == "ok"` (2013–2024).
Excluídos: `pre_rubrica_71` (2010–2012) e `ano_incompleto` (2025).

### Pipeline

```
painel_mg_participacao.rds  [2.835 pares]
painel_mg_anual.rds         [15.135 × ano]
         +
SICONFI MG ok               [9.975 linhas, 2013–2024]
MUNIC MG                    [3.287 linhas, 2015 e 2019]
         ↓
    04_pontuacao_mg.R
         ↓
2026-05-14_csv_base_mides_mg_v2.csv/.xlsx  [2.835 × 24]
```

### Lógica de pontuação por fonte

**MIDES (4 pts)**
```r
# Todos os 2.835 pares recebem 4 pts por definição —
# já estão na base porque o MIDES registrou pagamento
mutate(pontuacao_mides = 4L)
```

**SICONFI (3 pts) — confirmação indireta por ano**
```r
# Para cada par (município × consórcio):
# 1. Pega anos com pagamento CORRENTE no MIDES
# 2. Verifica se SICONFI confirma pagamento a ALGUM consórcio
#    no mesmo ano (rubrica .71.)
# 3. Se ao menos 1 ano bate → siconfi_confirma = TRUE → +3 pts

siconfi_score <- anual |>
  filter(tem_pagamento_corrente) |>
  select(id_municipio, documento_credor, ano) |>
  left_join(siconfi_mg |> rename(id_municipio = cod_ibge),
            by = join_by(id_municipio, ano)) |>
  summarise(
    siconfi_confirma   = any(paga_consorcio == TRUE, na.rm = TRUE),
    anos_siconfi_match = paste(sort(ano[paga_consorcio == TRUE ...]), collapse = ", "),
    n_anos_siconfi_match = sum(paga_consorcio == TRUE, na.rm = TRUE),
    .by = c(id_municipio, documento_credor)
  ) |>
  mutate(pontuacao_siconfi = if_else(siconfi_confirma, 3L, 0L))

# Nota: SICONFI não identifica qual consórcio foi pago —
# confirmação é INDIRETA. Chance de coincidência é baixa
# quando MIDES e SICONFI batem no mesmo ano.
```

**MUNIC (2 pts) — declaração de filiação**
```r
# Para cada par (município × consórcio):
# Verifica se declarou participação em QUALQUER corte (2015 ou 2019)
# Sem cruzamento por ano — declaração vale para o par inteiro

munic_score <- munic_mg |>
  summarise(
    munic_confirma = TRUE,
    anos_munic     = paste(sort(unique(ano)), collapse = ", "),
    setores_munic  = paste(sort(unique(setor)), collapse = ", "),
    .by = c(cod_ibge, cnpj_consorcio)
  ) |>
  mutate(pontuacao_munic = 2L)
```

### Bug crítico corrigido — chave de join do MUNIC

**Problema:** `cod_ibge` no MUNIC tem **6 dígitos** (ex: `310020`), enquanto `id_municipio` no painel MIDES tem **7 dígitos** (ex: `3100203` — com dígito verificador IBGE). O join direto retornava **0 matches**.

**Correção:**
```r
mutate(id_municipio_6 = substr(as.character(id_municipio), 1, 6)) |>
left_join(munic_score,
          by = join_by(id_municipio_6 == id_municipio, documento_credor)) |>
select(-id_municipio_6)  # remover coluna auxiliar após join
```

**Impacto:** de 0 para **1.348 pares com MUNIC confirmado**.

### Resultados

**Distribuição de pontuação total:**

| Pontuação | Combinação | Pares | % |
|---|---|---|---|
| **9 pts** | MIDES + SICONFI + MUNIC | 1.198 | 42,3% |
| **7 pts** | MIDES + SICONFI | 1.228 | 43,3% |
| **6 pts** | MIDES + MUNIC (sem SICONFI) | 150 | 5,3% |
| **4 pts** | Só MIDES | 259 | 9,1% |

**Por número de fontes:**
- 3 fontes: 1.198 pares (42,3%)
- 2 fontes: 1.378 pares (48,6%)
- 1 fonte:    259 pares (9,1%)

**SICONFI:** confirmou 2.426 de 2.816 pares elegíveis (86,1%)

**MUNIC:** confirmou 1.348 pares (47,5%)
- 627 pares: declarados em 2015 e 2019
- 423 pares: só em 2019
- 298 pares: só em 2015

**MUNIC por setor (top 5):**
| Setor | Pares |
|---|---|
| saude | 869 |
| manejo_res_solido | 263 |
| des_urbano | 179 |
| saneam_basico | 156 |
| meio_ambiente | 155 |

**Estatísticas de valor_total_periodo (R$ deflacionado jan/2018):**
| min | p25 | mediana | média | p75 | p95 | max |
|---|---|---|---|---|---|---|
| R$49 | R$54k | R$219k | R$1,3M | R$947k | R$4,1M | R$264M |

**32 pares** com `valor_atipico = TRUE` (total < R$1.000 — prováveis taxas simbólicas de adesão).

**Top consórcios por nº de municípios pagantes:**
| CNPJ | Nome | Municípios |
|---|---|---|
| 21505692000108 | CIMAMS | 21 |
| 19193527000108 | CONS. INTERMUNIC. DESENVOLVIMENTO... | 20 |
| 17813026000151 | CISDESTE | 14 |
| 20059618000134 | CIS-URG OESTE | 11 |

> ⚠️ **Errata (verificado 2026-05-15):** estes números foram calculados em EDA intermediário e estão **incorretos**. A contagem definitiva, feita diretamente no `painel_universal_mg_v1.csv`, mostra valores muito maiores: CISSUL 150 / CISDESTE 94 / CIMAMS 89 / CISRUN 83. A causa provável é que o EDA foi rodado com algum filtro não documentado ou sobre um subconjunto dos dados. Usar sempre o CSV final como fonte de verdade.

**Top municípios por nº de consórcios:**
| Município (IBGE) | Nº consórcios |
|---|---|
| 3111200 | 9 |
| 3135407 | 8 |
| 3109204 | 7 |
| 3123908 | 7 |

### Colunas do output (24 no total)

| Coluna | Tipo | Descrição |
|---|---|---|
| `id_municipio` | chr | IBGE 7 dígitos |
| `documento_credor` | chr | CNPJ 14 dígitos |
| `nome_credor_freq` | chr | Nome mais frequente no MIDES |
| `pontuacao_mides` | int | Sempre 4 |
| `ano_entrada_proxy` | dbl | Primeiro ano com pagamento corrente |
| `ultimo_ano_corrente` | dbl | Último ano com pagamento corrente |
| `ainda_ativo` | lgl | TRUE = pagava em 2021 |
| `valor_total_periodo` | dbl | Soma pagamentos (R$ jan/2018) |
| `n_anos_pagamento` | int | Nº de anos com pagamento corrente |
| `valor_atipico` | lgl | TRUE = total < R$1.000 |
| `pontuacao_siconfi` | int | 3 ou 0 |
| `siconfi_confirma` | lgl | TRUE/FALSE |
| `anos_siconfi_match` | chr | Ex: "2015, 2017, 2019" |
| `n_anos_siconfi_match` | int | Nº de anos que batem |
| `pontuacao_munic` | int | 2 ou 0 |
| `munic_confirma` | lgl | TRUE/FALSE |
| `anos_munic` | chr | Ex: "2015, 2019" |
| `setores_munic` | chr | Ex: "saude, saneam_basico" |
| `pontuacao_cnm` | int | 0 (placeholder) |
| `cnm_confirma` | lgl | NA |
| `pontuacao_total` | int | Soma (máx atual: 9) |
| `n_fontes` | int | Nº de fontes que confirmam |
| `confianca` | chr | "baixa" / "sem_evidencia" |
| `fonte` | chr | "MIDES" |

### Output

```
outputs/csv_base/2026-05-14_csv_base_mides_mg_v2.csv   — 2.835 × 24
outputs/csv_base/2026-05-14_csv_base_mides_mg_v2.xlsx  — idem
```

---

## Etapa 8 — Painel Universal MG (2026-05-14)

### Objetivo

Expandir o universo de pares do sistema de pontuação. Em vez de ancorar no MIDES (2.835 pares), usar a **união de MIDES + MUNIC** como universo, restrita aos 223 consórcios do cadastro MG. Pares que existem apenas no MUNIC (sem evidência MIDES) passam a ser incluídos com pontuação mínima de 2 pts.

### Por que a expansão é necessária

O script 04 era cego para municípios que declararam filiação no MUNIC mas nunca aparecem no MIDES. Isso ocorre em três situações reais:
1. **Consórcio informal** — não regido pela Lei 11.107/2005 → sem rubrica .71. no SICONFI → pode não aparecer no TCE-MG
2. **Inadimplência** — município declarou filiação mas não pagou o rateio
3. **Pré-2014** — relação existia antes do MIDES MG começar

### Decisão sobre CNPJs fora do cadastro

O MUNIC MG tem 286 CNPJs declarados pelos municípios. Desses:
- 149 estão no cadastro MG (usados)
- 3 estão no cadastro em outro estado — SP, ES (descartados)
- **134 não estão no cadastro de 1.194** (descartados por falta de metadados)

Decisão: restringir o universo ao cadastro de 1.194. CNPJs sem metadados são descartados. O mesmo critério valerá para o CNM (Etapa 9).

### Inputs

| Arquivo | Dimensão | Uso |
|---|---|---|
| `dados/processado/painel_mg_participacao.rds` | 2.835 × 11 | Pares MIDES |
| `dados/processado/painel_mg_anual.rds` | 15.135 × 9 | Âncora SICONFI para pares MIDES |
| `base_consorcios_v10.xlsx` aba "Cadastro" | 1.194 × 25 | Restrição do universo (223 MG) + metadados |
| `base_consorcios_v10.xlsx` aba "SICONFI painel munic" | → 9.975 linhas MG ok | Confirmação por ano |
| `base_consorcios_v10.xlsx` aba "MUNIC participacao" | → 3.287 linhas MG | Pares MUNIC + confirmação |

### Pipeline

```
painel_mg_participacao.rds  [2.835 pares MIDES]
painel_mg_anual.rds         [15.135 × ano]
         +
Cadastro MG                 [223 consórcios — filtro e metadados]
SICONFI MG ok               [9.975 linhas, 2013–2024]
MUNIC MG                    [3.287 linhas, 2015 e 2019]
         ↓
    05_painel_universal_mg.R
         ↓
2026-05-14_painel_universal_mg_v1.csv/.xlsx  [2.887 × 32]
```

### Lógica de construção do universo

```r
# Pares MIDES
pares_mides <- painel_mg_participacao |>
  mutate(cod_ibge_6 = substr(as.character(id_municipio), 1, 6),
         cnpj_consorcio = documento_credor,
         origem = "mides")

# Pares MUNIC — restritos ao cadastro MG
pares_munic <- munic_mg |>
  filter(cnpj_consorcio %in% cnpjs_cadastro_mg) |>  # descarta 134 fora do cadastro
  mutate(origem = "munic")

# União → 1 linha por (cod_ibge_6 × cnpj_consorcio)
universo <- bind_rows(pares_mides, pares_munic) |>
  summarise(
    tem_mides     = any(origem == "mides"),
    tem_munic_par = any(origem == "munic"),
    .by = c(cod_ibge_6, cnpj_consorcio)
  )
# Resultado: 2.887 pares (2.835 com MIDES + 52 só MUNIC)
```

### Lógica SICONFI — dupla âncora

SICONFI não identifica o consórcio destinatário. A confirmação depende de saber em quais anos o município deveria ter pago aquele consórcio.

**Âncora MIDES** (2.835 pares com MIDES):
```
Anos âncora = anos com pagamento corrente no MIDES
Se SICONFI confirma pagamento a "algum consórcio" em ao menos
1 desses anos → siconfi_confirma = TRUE → +3 pts
```

**Âncora MUNIC** (52 pares só MUNIC):
```
Anos âncora = cortes disponíveis (2015 e/ou 2019)
Mesma lógica: se SICONFI confirma em ao menos 1 desses anos
→ siconfi_confirma = TRUE → +3 pts
```

**Coluna `ancora`:** identifica qual âncora foi usada para cada par
- `"mides"` — âncora via pagamentos correntes MIDES
- `"munic"` — âncora via cortes MUNIC 2015/2019
- `"sem_ancora"` — 19 pares sem_evidencia (sem pagamento corrente e origem MIDES)

### Bugs encontrados e corrigidos

| # | Bug | Como detectado | Correção |
|---|---|---|---|
| 1 | SICONFI `cod_ibge` de 7 dígitos — join com universo 6 dígitos → 0 matches | Revisão pré-execução | `mutate(cod_ibge_6 = substr(as.character(cod_ibge), 1, 6))` no carregamento do SICONFI |
| 2 | `ancora = NA` para 19 pares `sem_evidencia` | Revisão pré-execução | `ancora = if_else(is.na(ancora), "sem_ancora", ancora)` |
| 3 | `n_anos_siconfi_match = 12` (impossível — MIDES max = 8 anos) | **EDA pós-execução** | `distinct(cod_ibge_6, cnpj_consorcio, ano)` antes do join — `munic_mg` tem 1 linha por setor, consórcio multissetorial com 12 setores gerava 12 linhas |

> ⚠️ O bug 3 (duplicatas por setor) **não foi detectado na revisão pré-execução** — só apareceu no EDA quando o valor máximo 12 foi identificado como impossível (MIDES MG cobre no máximo 8 anos). **Regra aprendida:** sempre verificar `count(cod_ibge, cnpj_consorcio, ano) |> filter(n > 1)` antes de qualquer join com `munic_mg`.

### EDA — Verificações de integridade

| Verificação | Resultado |
|---|---|
| Duplicatas `cod_ibge_6 × cnpj_consorcio` | 0 ✅ |
| `n_anos_siconfi_match > 8` após fix | 0 ✅ |
| Pares com `pontuacao_total = 0` | 0 ✅ (mínimo = 2 pts) |
| `ancora = NA` após fix | 0 ✅ |

### Resultados

**Universo:**
| | Pares | Consórcios |
|---|---|---|
| Só MIDES (script 04) | 2.835 | 161 |
| Painel universal | **2.887** | **223** |
| Pares novos (só MUNIC) | +52 | — |

**Distribuição por pontuação:**

| Pontuação | Combinação | Pares (aprox.) |
|---|---|---|
| 9 pts | MIDES + SICONFI + MUNIC | ~1.198 |
| 7 pts | MIDES + SICONFI | ~1.228 |
| 6 pts | MIDES + MUNIC | ~150 |
| 5 pts | SICONFI + MUNIC (âncora MUNIC) | ~n |
| 4 pts | Só MIDES | ~259 |
| 2 pts | Só MUNIC | ~52 |

**CODAP (consórcio de referência) — 20 pares, nenhum MUNIC-only novo:**
```
9 pts → 5 municípios  (MIDES + SICONFI + MUNIC)
         3120409, 3135407, 3142304, 3145901, 3160900

7 pts → 13 municípios (MIDES + SICONFI, sem MUNIC)
         3106408, 3109006, 3113107, 3118007, 3118308,
         3123908, 3131908, 3137908, 3140008, 3153808,
         3155208, 3159108, 3166008

4 pts → 2 municípios  (só MIDES — SICONFI não confirma)
         3115408, 3121408
```

### `setores_consolidado` — coluna de fallback

```r
setores_consolidado = case_when(
  !is.na(setores)       ~ setores,                          # cadastro tem precedência
  !is.na(setores_munic) ~ paste0(setores_munic, " [via MUNIC]"),
  TRUE                  ~ NA_character_
)
```

### Colunas principais do output (32 no total)

| Coluna | Descrição |
|---|---|
| `cod_ibge_6` | IBGE 6 dígitos (chave universal de join) |
| `id_municipio` | IBGE 7 dígitos (quando disponível via MIDES) |
| `cnpj_consorcio` | CNPJ 14 dígitos |
| `nome_credor_freq` | Nome mais frequente (MIDES) |
| `razao_social` / `sigla` | Do cadastro |
| `setores` | Setor do cadastro |
| `setores_consolidado` | Cadastro se disponível, senão MUNIC |
| `situacao` / `ano_fundacao` | Do cadastro |
| `tem_evidencia` | Flag consolidada de evidência |
| `pontuacao_mides` | 4 ou 0 |
| `pontuacao_siconfi` | 3 ou 0 |
| `pontuacao_munic` | 2 ou 0 |
| `pontuacao_cnm` | 0 (placeholder) |
| `pontuacao_total` | Soma (máx atual: 9) |
| `n_fontes` | Nº de fontes que confirmam |
| `ancora` | `"mides"` / `"munic"` / `"sem_ancora"` |
| `siconfi_confirma` | TRUE/FALSE |
| `munic_confirma` | TRUE/FALSE |
| `anos_siconfi_match` | Anos em que SICONFI e âncora batem |
| `n_anos_siconfi_match` | Nº de anos que batem |
| `anos_munic` | Cortes MUNIC onde o par aparece |
| `setores_munic` | Setores declarados no MUNIC |
| `ano_entrada_proxy` | Primeiro ano com pagamento corrente (MIDES) |
| `ultimo_ano_corrente` | Último ano com pagamento corrente |
| `valor_total_periodo` | Soma pagamentos (R$ jan/2018) |
| `n_anos_pagamento` | Nº anos com pagamento corrente |
| `valor_atipico` | TRUE = total < R$1.000 |
| `confianca_mides` | "baixa" / "sem_evidencia" |

### Output

```
outputs/csv_base/2026-05-14_painel_universal_mg_v1.csv   — 2.887 × 32
outputs/csv_base/2026-05-14_painel_universal_mg_v1.xlsx  — idem
```

**Produto principal atual do projeto.**

---

## Errata e dívidas técnicas (registradas em 2026-05-15)

| # | Tipo | Onde | Descrição | Impacto | Status |
|---|---|---|---|---|---|
| 1 | 🔴 Bug de leitura | Qualquer script que use `read.csv()` ou `read_csv()` sem `col_types` | CNPJs lidos como `double` perdem zero inicial e dígitos finais (ex: `"05802877000110"` → `5.802877e+12`). Busca por string falha. | Filtros por CNPJ retornam 0 linhas erroneamente | Corrigido em `slides/scripts_viz.R` com `col_character()` explícito. Verificar todos os scripts futuros. |
| 2 | 🟡 Dívida técnica | Script 05 (`05_painel_universal_mg.R`) | `flag_continuo` não foi incluída no painel universal. Existe no v1 mas não no universal (32 cols). Requer join externo com v1 para recuperar. | Charts e análises que precisem de `flag_continuo` exigem join adicional | Workaround em `slides/scripts_viz.R`. Corrigir no script 05 na próxima iteração. |
| 3 | 🟢 Errata de EDA | Etapa 7 — Resultados (top consórcios) | Top consórcios com 21/20/14/11 municípios são incorretos — calculados em EDA intermediário com filtro não documentado. Valores corretos (do CSV final): CISSUL 150 / CISDESTE 94 / CIMAMS 89 / CISRUN 83. | Números incorretos registrados no documento | Anotado com errata na seção de resultados acima. |
