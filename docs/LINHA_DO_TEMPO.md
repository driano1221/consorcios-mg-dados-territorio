# Linha do Tempo — Consórcios MG: Dados e Território
**Atualizado em:** 2026-05-14

---

## 2026-04-30 — Reunião IPEA + decisão de criar subprojeto

**Contexto:**
- Reunião com Paulo, Mauro e equipe definiu metodologia de 4 categorias de participação municipal
- Discutido que os 1.194 consórcios não são garantia de universo completo
- Objetivo real: mapear TODOS os consórcios num intervalo de 15–20 anos

**Decisões tomadas:**
- Piloto em Minas Gerais
- Usar MIDES como fonte primária de evidência de pagamento
- 4 categorias: membro+paga / membro+inadimplente / compra serviço / não participa
- Cruzar MIDES × MUNIC × documentos físicos
- Período-alvo: 2003–2023

**Arquivos criados:**
- `MEMORIA_ideiaMides.md` — memória estrutural do projeto
- `scripts/`, `dados/`, `outputs/` — estrutura de pastas

---

## 2026-05-05 — Investigação do BigQuery + preparação do download

### O que fizemos

**Passo 1 — Conexão ao BigQuery**
- Instalado pacote `basedosdados` (v0.2.3)
- Autenticado com conta `driano2012@gmail.com` (projeto `ipea-consorcios`)
- Tabela: `basedosdados.world_wb_mides.pagamento`
- Confirmado: tabela tem 25 colunas (diferente do arquivo do Anderson que tinha 11)

**Passo 2 — Exploração dos estados disponíveis**
```
CE: 13.9M linhas (2009–2022)
DF:  4.8M linhas (2009–2023)
MG: 64.1M linhas (2014–2021)  ← nosso foco
PB: 22.1M linhas (2003–2020)
PE: 21.4M linhas (2012–2020)
PR: 52.5M linhas (2013–2022)
RJ: 15.1M linhas (2002–2022)
RS: 105M linhas (1994–2021)
SC:  7.7M linhas (2021–2024)
SP: 85.6M linhas (2005–2021)
NA: 152k linhas — todas colunas NA, ignorar
```
- 5 estados ausentes vs. documentação (ES, GO, RN, RO, TO): BigQuery desatualizado
- Base antiga do Anderson (6 estados) era subconjunto — todos presentes no BigQuery atual
- BigQuery ganhou 4 novos desde Anderson: DF, PE, RJ, SC

**Passo 3 — Análise da tabela `pagamento` vs. `empenho`**
- São tabelas DIFERENTES do ciclo orçamentário
- `pagamento` = pagamento efetivo ✅ correto para inferir participação
- Anderson estava certo em usar `pagamento`

**Passo 4 — Investigação do `documento_credor` (CNPJ)**

Distribuição de tamanho em MG:
| nchar | Tipo | Qtd |
|---|---|---|
| 1 | Placeholder "0" | 5,2M |
| 3 | Códigos internos | 82k |
| 11 | CPF pessoa física | 11,6M |
| **14** | **CNPJ — nosso formato** | **46,9M** |
| 15 | Erro (+1 char) | 34 |
| 16 | Payroll/placeholders artificiais | 417k |

- 16-char: verificado — são folha de pagamento, INMETRO, indivíduos com zeros à esquerda. **Nenhum consórcio.**
- Filtro `documento_credor %in% cnpjs` é seguro e completo

**Passo 5 — Estimativa do download**
- Com filtro CNPJs nossos: **469.596 linhas**, **161 consórcios**, 2014–2021
- 161 de 223 consórcios MG no cadastro — os outros não aparecem no TCE-MG

**Passo 6 — Análise do `fonte`**
- 56 códigos distintos nos nossos consórcios MG
- `102` (68%) e `100` (26%) dominam — recursos próprios municipais
- **Decisão: não filtrar por fonte** — rateio pode vir de múltiplas fontes

**Passo 7 — `indicador_restos_pagar`**
- FALSE = pagamento corrente do exercício
- TRUE = dívida de anos anteriores sendo quitada agora
- **Decisão: baixar ambos**, com coluna para tratar depois
- Motivo: restos a pagar distorcem `ano_entrada_proxy` mas não devem ser descartados

**Passo 8 — nome_credor**
- Mesmo CNPJ aparece com dezenas de variações de nome (cada município digita diferente)
- Confirma: CNPJ é a única chave confiável, nunca nome

### Conclusão da investigação
✅ Dados consistentes, sem problemas de formato  
✅ Filtro por CNPJ suficiente  
✅ Pronto para download  

### Arquivos criados
| Arquivo | Descrição |
|---|---|
| `scripts/01_baixar_mides_mg.R` | Script de download (a rodar) |
| `dados/mides_mg_atualizado.rds` | **A gerar** — saída do script acima |

### Cota BigQuery usada hoje
| Query | GB |
|---|---|
| count por estado | 1,57 |
| NAs exploração | 0,05 |
| Range anos | 4,71 |
| documento_credor distinct | 5,89 |
| Estimativa download (query 4) | 3,13 |
| nchar análise | 2,15 |
| Matches amostra | 5,89 |
| Fonte dos nossos CNPJs | 2,58 |
| 16-chars verificação | 5,89 |
| **Total usado hoje** | **~31,9 GB** |
| **Saldo restante (mês)** | **~968 GB** |

---

## 2026-05-05 — Painel de participação construído ✅

**Resultado do `scripts/02_painel_participacao.R`:**

| Métrica | Valor |
|---|---|
| Linhas no painel anual | 15.135 (município × consórcio × ano) |
| Pares únicos (município × consórcio) | **2.835** |
| Municípios | 853 |
| Consórcios | 161 |
| Período | 2014–2021 (máx. 8 anos correntes) |
| Pares ainda ativos em 2021 | 2.280 (80,4%) |
| Pares com possível saída (< 2021) | 555 (19,6%) |
| Pares apenas com restos a pagar | 19 → `confianca = "sem_evidencia"` |
| Arquivos salvos | `dados/painel_mg_anual.rds` e `dados/painel_mg_participacao.rds` |

**Distribuição de `ano_entrada_proxy`:**
```
2014: 1.429  ← CENSURA À ESQUERDA (MIDES começa em 2014, não são entradas reais)
2015:   420
2016:   149
2017:   161
2018:   144
2019:   180
2020:    99
2021:   234
  NA:    19  (só restos a pagar)
```

**⚠️ Nota metodológica — censura à esquerda:**
Os 1.429 pares com `ano_entrada_proxy = 2014` não entraram necessariamente em 2014.
O MIDES MG começa em 2014, então esses casos existiam antes mas não são observáveis.
A data real de entrada exige fonte adicional (MUNIC, documentos, SES-MG).

**Warnings na execução:** 38 avisos esperados (19 pares × 2 operações `min`/`max` de vetor vazio). Tratados via `is.infinite()` → `NA`. Não indicam erro.

**Bugs corrigidos nesta etapa:**

| # | Problema | Causa | Correção |
|---|---|---|---|
| 1 | `painel_anual` com 15.200 linhas em vez de 15.135 | `nome_credor` no `.by` duplicava linhas (mesmo CNPJ com grafias diferentes por município) | Removido `nome_credor` do `.by`; `nome_credor_freq` calculado dentro do `summarise` |
| 2 | `ano_entrada_proxy = Inf` em 19 pares | `min()` de vetor vazio (só restos, sem pagamento corrente) | `if_else(is.infinite(...), NA_real_, ...)` + `confianca = "sem_evidencia"` |
| 3 | `Error: object 'nome_credor' not found` no passo 3 | Coluna já renomeada para `nome_credor_freq` no passo 2 | Substituído por `first(nome_credor_freq)` |

**Lógica de confiança inicial (a enriquecer no script 03):**

| Valor | Significado |
|---|---|
| `"baixa"` | Só MIDES, sem confirmação MUNIC ou documento |
| `"sem_evidencia"` | Par aparece no dado mas APENAS via restos a pagar (19 casos) |

---

## 2026-05-07 — Reunião IPEA: Paulo, Pedro, Mauro, Adriano

### Decisões tomadas

**Mudança metodológica central:** sistema de 4 categorias fixas substituído por **sistema de pontuação acumulada por fonte**:

| Fonte | Pontos |
|---|---|
| MIDES | 4 |
| SICONFI | 3 |
| MUNIC (2015/2019) | 2 |
| CNM | 1 |

Par confirmado pelas 4 fontes = 10 pts (máxima confiança).

**Outras decisões:**
- Foco exclusivo em **MG** para próxima entrega
- **CODAP** = consórcio de referência para todos os testes e plots
- Nova variável: **contínuo/descontínuo** por par município × consórcio
- Produto imediato: **CSV base MIDES MG** (cod_ibge, município, consórcio, anos, contínuo/descontínuo, valor)
- Comparar contagem: base Ives (1.194) × MIDES (161 em MG) × CNM
- CNM entra como 4ª fonte — para depois

**Fluxo operacional definido:**
```
MIDES → SICONFI → MUNIC → CNM → documentos físicos
```

---

## 2026-05-13 — Revisão geral + mapas + atualização memórias

### O que foi feito

**Revisão dos arquivos RDS:**
- Head/tail + estatísticas confirmadas dos 3 arquivos
- `mides_mg_atualizado.rds`: R$ 3,8 bi total, 95% pagamentos correntes
- `painel_mg_anual.rds`: média 31 transações/linha-ano, R$ 3,52 bi corrente + R$ 0,28 bi restos
- `painel_mg_participacao.rds`: n_anos médio = 5,2 por par

**Censura à esquerda — números exatos:**
- 1.429 pares (50,4%) censurados → entrada = 2014
- 1.387 pares (48,9%) sem censura → data real observada
- 19 pares (0,7%) sem evidência → só restos a pagar

**Decisão sobre script 03:**
- Suspenso — em adaptação para o novo sistema de pontuação (reunião 07/05)
- Não faz sentido rodar com lógica antiga de 4 categorias

**Documentos físicos:**
- ~600 pastas obtidas (lote novo mai/2026)
- Pipeline OCR/IA planejado para extração → Tabela B

**Visualizações desenvolvidas (código pronto):**
- Mapa interativo Leaflet: municípios coloridos por nº de consórcios, popup com lista
- PDF cards por consórcio: cabeçalho azul + mapa MG + lista municípios participantes
- Formas de publicar: `saveWidget()` → HTML → Drive / RPubs / Quarto Pub

**SICONFI — confirmado das memórias:**
- Cobertura: todos os municípios BR, 2013–2024
- CNPJ presente é do município, não do consórcio
- Uso: diagnóstico de cobertura, não identificação de consórcio

### Próximos passos atualizados
~~1. CSV base MIDES MG: enriquecer painel + nome município + flag contínuo/descontínuo + exportar~~ ✅ feito (ver sessão 2026-05-13 completa abaixo)
~~2. Validar com CODAP (CNPJ a confirmar)~~ ✅ CNPJ confirmado: `08.753.385/0001-70`
~~3. Adaptar script 03 para sistema de pontuação~~ ✅ substituído pelos scripts 04 e 05
4. Pipeline OCR/IA → ~600 pastas → Tabela B (pendente)
5. CNM como 4ª fonte — Etapa 9 (pendente)

---

## 2026-05-05 — Download MG concluído ✅

**Resultado do `scripts/01_baixar_mides_mg.R`:**

| Métrica | Valor |
|---|---|
| Linhas baixadas | 469.596 |
| Consórcios únicos | 161 |
| Municípios únicos | **853** (= todos os municípios de MG) |
| Período | 2014–2021 |
| Restos a pagar (TRUE) | 23.270 linhas (4,95%) |
| Arquivo salvo | `dados/mides_mg_atualizado.rds` |
| Custo BigQuery | 11,30 GB (1ª vez) / 0 B (2ª — cache) |

**Achados relevantes:**
- 853 municípios = universo completo de MG — todos pagaram ao menos um consórcio em algum ano entre 2014–2021
- 161 de 223 consórcios MG do Cadastro aparecem recebendo via TCE-MG — os outros podem ser informais, inativos ou de setores sem cobertura
- 23.270 linhas de restos a pagar: não descartar, mas criar flag para tratar separadamente na análise de entrada/saída

**Cota BigQuery acumulada no mês:**
- Hoje: ~43 GB usados (31,9 exploração + 11,3 download)
- Saldo: ~957 GB restantes

---

## 2026-05-13 — CSV base MIDES MG v1 + EDA + scripts 04 iniciado

### CSV base MIDES MG v1 (Etapa 6) ✅

Enriquecimento do `painel_mg_participacao.rds`:
- Nome oficial do município via `geobr`
- Flag `flag_continuo`: `continuo` / `descontinuo` / `ponto_unico` / NA
- Flags de censura: `censura_esquerda` (entrada = 2014) e `censura_direita` (último ano = 2021)
- Renomeação `ainda_ativo` → `sem_evidencia_saida` (semântica mais precisa)
- `pontuacao_mides = 4L` para todos

**Output:** `2026-05-13_csv_base_mides_mg_v1.csv/.xlsx` — 2.835 × 15

**Bugs corrigidos no processo:**

| # | Problema | Correção |
|---|---|---|
| 1 | `ainda_ativo = TRUE` para 100% dos 2.280 — era truncamento, não status real | Renomeado para `sem_evidencia_saida` + censura_direita |
| 2 | `flag_continuo = "continuo"` para 425 pares com 1 único pagamento | Nova categoria `"ponto_unico"` quando `n_anos == 1` |

**EDA — achados principais:**
- `flag_continuo`: continuo 69,1% / descontinuo 15,2% / ponto_unico 15% / NA 0,7%
- 32 pares com `valor_atipico = TRUE` (total < R$1.000 — provável taxa simbólica)
- Outlier real confirmado: Betim × CISMEP (R$264M, 8 anos — ~R$66M/ano 2014–2017)
- 19 `sem_evidencia` com valor > 0: correto — vem de restos a pagar

**CODAP confirmado:** CNPJ `08.753.385/0001-70` — 13 grafias distintas na base.

### Investigações paralelas

**SICONFI (aba "SICONFI painel munic"):**
- Cobertura real: nota_cobertura = "ok" vai até **2024** (não 2022 como achávamos)
- Anos 2010–2012: `pre_rubrica_71` → excluir
- 2025: `ano_incompleto` → excluir
- `valor_cons_real` já deflacionado para jan/2018 (IPCA)
- SICONFI **não identifica qual consórcio** foi pago (sem CNPJ destino) — confirmação indireta

**MUNIC (aba "MUNIC participacao"):**
- 2021/2023: confirmado que seção "Articulação Intermunicipal" não foi coletada pelo IBGE
- Só 2015 e 2019 disponíveis — sem possibilidade de adicionar edições futuras

### Script 04 iniciado

`04_pontuacao_mg.R` construído: integra SICONFI e MUNIC ao painel MIDES como sistema de pontuação.

---

## 2026-05-14 — Script 04 finalizado + decisão de arquitetura + script 05 (painel universal)

### Script 04 — Pontuação MIDES-ancorada ✅

**Bug crítico corrigido:** join do MUNIC retornava 0 matches.
- Causa: `cod_ibge` no MUNIC tem 6 dígitos; `id_municipio` no painel tem 7 (com dígito verificador)
- Correção: `id_municipio_6 = substr(as.character(id_municipio), 1, 6)` + join por essa chave

**Resultado após correção:** 1.348 pares com MUNIC confirmado (era 0 antes do fix)

**Distribuição final (2.835 pares):**
| Pontuação | Combinação | Pares | % |
|---|---|---|---|
| 9 pts | MIDES + SICONFI + MUNIC | 1.198 | 42,3% |
| 7 pts | MIDES + SICONFI | 1.228 | 43,3% |
| 6 pts | MIDES + MUNIC | 150 | 5,3% |
| 4 pts | Só MIDES | 259 | 9,1% |

**Output:** `2026-05-14_csv_base_mides_mg_v2.csv/.xlsx` — 2.835 × 24

### Decisão de arquitetura — universo expandido

**Problema identificado:** script 04 é cego para municípios que declararam filiação no MUNIC mas nunca aparecem no MIDES (consórcios informais, inadimplentes, pré-2014).

**Decisão:** expandir o universo para **MIDES ∪ MUNIC**, restrito ao cadastro de 223 consórcios MG. Pares só MUNIC entram com 2 pts.

**Impacto:**
- Antes (MIDES-ancorado): 2.835 pares, 161 consórcios
- Depois (universal): 2.887 pares, 223 consórcios (+52 pares só MUNIC)

**134 CNPJs do MUNIC fora do cadastro:** descartados por falta de metadados. Documentado como ponto para discussão com Paulo — o mesmo problema ocorrerá com o CNM.

### Script 05 — Painel Universal ✅

`05_painel_universal_mg.R` construído com lógica de dupla âncora para SICONFI:
- **Âncora MIDES:** anos com pagamento corrente no MIDES (para os 2.835 pares com MIDES)
- **Âncora MUNIC:** cortes 2015/2019 (para os 52 pares só MUNIC)

**Bugs encontrados e corrigidos:**

| # | Bug | Como foi detectado | Correção |
|---|---|---|---|
| 1 | SICONFI `cod_ibge` de 7 dígitos — join com universo 6 dígitos retornava 0 | Revisão pré-execução | `mutate(cod_ibge_6 = substr(as.character(cod_ibge), 1, 6))` no carregamento |
| 2 | `ancora = NA` para 19 pares `sem_evidencia` | Revisão pré-execução | `ancora = if_else(is.na(ancora), "sem_ancora", ancora)` |
| 3 | `n_anos_siconfi_match = 12` (impossível — MIDES max = 8 anos) | **EDA pós-execução** | `distinct(cod_ibge_6, cnpj_consorcio, ano)` antes do join — `munic_mg` tem 1 linha por setor |

⚠️ O bug 3 (duplicatas por setor em `munic_mg`) **não foi detectado na revisão pré-execução** — só apareceu no EDA. Lição: sempre verificar granularidade do `munic_mg` antes de joins.

**Output:** `2026-05-14_painel_universal_mg_v1.csv/.xlsx` — 2.887 × 32

**CODAP no painel universal (20 pares — sem novos pares MUNIC-only):**
- 5 municípios → 9 pts CSV / **14 pts apresentação** (MIDES + SICONFI + MUNIC)
- 13 municípios → 7 pts CSV / **12 pts apresentação** (MIDES + SICONFI)
- 2 municípios → 4 pts CSV / **8 pts apresentação** (só MIDES — SICONFI não confirma)

> Escala CSV = original (4+3+2). Escala apresentação = geométrica (8+4+2), recalculada em `scripts_viz.R`.

### Documentação atualizada
- `docs/2026-05-13-prep-reuniao-14-05.md` — seções Etapa 7, Etapa 7b, pontos para reunião, CODAP atualizado
- `docs/2026-05-14-registro-etapas-6-7-8.md` — registro técnico completo das 3 etapas
- `docs/2026-05-14-HANDOFF.md` — handoff completo para retomada futura
- `README.md`, `MEMORIA_ideiaMides.md`, `LINHA_DO_TEMPO.md` — todos atualizados
- Arquivos movidos: `MEMORIA` e `LINHA_DO_TEMPO` migrados para `docs/` (junto com demais .md)

---

## 2026-05-14 (noite) — Investigação da fonte CNM

### Objetivo
Mapear a fonte CNM (Confederação Nacional de Municípios) para preparar a Etapa 9 (incorporar CNM como 4ª fonte, +1 pt).

### Método
Buscas na web + testes de acesso HTTP + exploração da base_consorcios.

### Achados

**Plataforma encontrada:** `consorcios.cnm.org.br` — Plataforma Nacional de Consórcios Públicos Intermunicipais

**Acesso programático:**
- HTTP direto retorna 403 (Cloudflare protege todas as rotas)
- É um **SPA (Single Page App)** — dados carregados via JavaScript
- **Solução:** browser automation (Playwright ou RSelenium)
- Acesso de **leitura é público** — não requer login

**Estrutura dos dados (observada via browser):**
| Campo | Exemplo |
|---|---|
| CNPJ do consórcio | `11.636.961/0001-03` ✅ |
| Nome | CISRUN |
| Natureza Jurídica | Público |
| Lei 11.107/2005 | Sim/Não |
| Data de constituição | 23/02/2010 |
| Município sede | Montes Claros/MG |
| Municípios membros | Lista por nome + UF (ex: "Várzea da Palma/MG") |

**Cobertura:**
- 728 consórcios / 4.814 municípios / 1978–2025 (irregular)
- Sudeste: 276 / Sul: 193 / Nordeste: 164 / Centro-Oeste: 69 / Norte: 26

**⚠️ Ponto de atenção para o join:** municípios identificados por **nome + UF**, não por CNPJ nem código IBGE. Precisará de normalização + join com tabela IBGE para obter `cod_ibge`.

**Não há arquivos CNM** em nenhum diretório do servidor IPEA.

### Plano para amanhã (2026-05-15)
1. Construir robô de scraping com Playwright/RSelenium
2. Extrair todos os 728 consórcios e seus municípios membros
3. EDA na base bruta
4. Join nome município → cod_ibge
5. Script `06_cnm_mg.R` → `painel_universal_mg_v2`

---

## 2026-05-14 — Reunião de apresentação (Paulo, Pedro, Mauro, Adriano)

### Apresentação do painel + mapas

Adriano apresentou o `painel_universal_mg_v1` e os mapas por consórcio (polígonos dos municípios membros de cada consórcio em MG, gerados com MIDS + geobr). Recepção muito positiva — Paulo: "nota mil".

**Mapas por consórcio:** já produzidos (baseados no MIDS). Mostram quais municípios fazem parte de cada consórcio, com zoom individual. Paulo havia pedido isso em reunião anterior. Produto ainda não formalizado como entregável.

### Decisões confirmadas

| Decisão | Detalhe |
|---|---|
| **Escala geométrica confirmada** | Paulo validou: MIDES=8, SICONFI=4, MUNIC=2, **CNM=1** |
| **CNM como 4ª fonte** | Adriano coletando dados durante a reunião. Meta: painel v2 |
| **Plano de trabalho CNM** | Paulo vai preencher documento e enviar a Adriano para encaminhar à CNM |

### Descobertas e discussões

**Inconsistência interna na CNM:**
- Montes Claros aparece como sede de 6 consórcios em uma tela e 2 em outra
- A base não é consistente internamente — problema conhecido para o join
- Parte da inconsistência explicada por atualizações incrementais (ex: CIMANS atualizado em 2022, após o corte de 2021 do MIDS)

**Constantino deixou o projeto IPEA de consórcios municipais:**
- Novo coordenador da área: Sérgio (Brasília)
- Bolsista de sócios municipais pediu desligamento
- Só resta uma bolsista trabalhando com consórcios estaduais
- Constantino mudou de tema (desenvolvimento territorial)
- Implicação: projeto paralelo encerrado — sem sobreposição, mas também sem colaborador natural

**Análise de valores transferidos — dois recortes:**
- Completo (161 consórcios): mediana alta, inflada por outliers
- Filtro `flag_continuo` (todos os anos): cai para **83 consórcios**, mediana mais realista
- Pedro observou: o filtro deveria ser "todos os anos *desde a fundação*" — consórcios criados após 2014 não deveriam ser penalizados

**Receita Federal como fonte complementar:**
- CNPJs "baixados" = consórcios extintos formalmente
- Permitiria filtrar o cadastro de 223 pelos que estavam ativos no período 2014–2021
- Tornaria as bases comparáveis temporalmente

**Solicitação de Paulo — slide do cadastro:**
- Deixar explícita a origem dos 223 consórcios: cadastro de CNPJs (dígitos identificadores de consórcio) + MUNIC + revisão manual (falsos positivos e negativos)

### CNM em MG — estimativa Adriano
- ~163 consórcios na CNM para MG (raspagem parcial durante a reunião)
- Convergindo com os 161 do MIDS → número real de consórcios ativos em MG provavelmente entre 150–165

### Próximos passos definidos

| Prioridade | Tarefa |
|---|---|
| 🔴 | Finalizar scraping CNM → script `06_cnm_mg.R` → `painel_universal_mg_v2` |
| 🔴 | Aguardar plano de trabalho de Paulo e encaminhar à CNM |
| 🟡 | Receita Federal: consultar CNPJs baixados para filtrar extintos |
| 🟡 | Refinar `flag_continuo`: "todos os anos desde ano de criação" |
| 🟡 | Atualizar slide de origem do cadastro de 223 |
| 🟢 | Formalizar mapas por consórcio como entregável |
