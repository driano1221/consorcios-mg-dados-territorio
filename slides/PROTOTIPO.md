# Protótipo — Slides ideiaMides
**Atualizado em:** 2026-05-14 (v3 — slide HTML gerado ✅)
**Template:** Reveal.js 5.1 (estilo Signal — CDN)
**Output:** `slides/2026-05-14_apresentacao_ipea.html` ← **ENTREGUE**

---

## Estrutura completa (11 slides)

| # | Título (= takeaway Scherer) | Visual | Tipo | Chart R |
|---|---|---|---|---|
| 1 | *Capa* — projeto, IPEA, data | Só texto | HTML | — |
| 2 | **"Nenhuma fonte sozinha resolve — cada uma cobre um pedaço"** | Grid 2×2: 4 fontes + cobertura temporal + limitação | HTML | — |
| 3 | **"Triangulamos 4 fontes — máx 9 pts hoje, 10 com CNM"** | Tabela: fonte × pts × período × método × limitação | HTML | — |
| 4 | **"Da transação ao painel: 5 etapas automatizadas"** | Diagrama de fluxo: BigQuery → MIDES → CSV → Pontuação → Painel | HTML/SVG | — |
| 5 | **"161 de 223 consórcios MG têm pagamento confirmado pelo MIDES"** | Barras horizontais: MIDES 161 / MUNIC 149 / CNM 🔄 / total 223 | R → PNG | `cobertura_fontes.png` |
| 5b | **"Saúde domina — mas o painel cobre 12 setores e os maiores têm 20+ municípios"** | Painel duplo: top 10 consórcios × nº membros + top 5 setores MUNIC | R → PNG | `eda_distribuicao.png` |
| 5c | **"Mediana de R$219k — mas a dispersão vai de R$49 a R$264M"** | Boxplot/lollipop de valor por par + outlier Betim × CISMEP anotado | R → PNG | `eda_valor.png` |
| 6 | **"85% dos pares confirmados por 2+ fontes — 69% sem nenhuma interrupção"** | Histograma de pontuação (0–9) + stat card flag_continuo | R → PNG | `hist_pontuacao.png` |
| 7 | **"CODAP: 5 municípios com confiança máxima, 20 no total"** | Mapa MG: membros azul + resto cinza + mini-tabela 5×9/13×7/2×4 | R → PNG | `codap_map.png` |
| 8 | **"4 achados que só aparecem ao cruzar as fontes"** | 4 stat cards grandes | HTML | — |
| 9 | **"Em construção + 3 questões para Paulo"** | Tabela status + 3 perguntas | HTML | — |

---

## Slide 8 — Conteúdo dos stat cards (achados do cruzamento)

| Card | Número | Frase |
|---|---|---|
| 1 | **52** | pares de participação invisíveis ao MIDES — só o MUNIC enxergou |
| 2 | **~50%** | dos membros declarados no MUNIC não pagam via SICONFI → consórcios informais (≠ inadimplência) |
| 3 | **1.429** | pares com censura à esquerda — entraram antes de 2014, data real desconhecida |
| 4 | **32** | pares com pagamento < R$1.000 — provável adesão simbólica sem rateio efetivo |

---

## Slide 3 — Tabela de pontuação (conteúdo completo)

| Fonte | Pts | Período | Método | Limitação |
|---|---|---|---|---|
| MIDES | 4 | 2014–2021 | Pagamento efetivo via TCE-MG | Cobre só MG; truncado em 2021 |
| SICONFI | 3 | 2013–2024 | Rubrica .71. federal | Não identifica o consórcio destino |
| MUNIC | 2 | 2015 e 2019 | Autodeclaração IBGE | IBGE não coletou após 2019 |
| CNM | 1 | 1978–2025 | Lista de membros da plataforma | 🔄 scraping em construção |
| **Total** | **10** | — | — | **Atual: máx 9 pts** |

---

## Slide 5b — EDA: Distribuição (dados concretos)

**Top consórcios por nº de municípios pagantes (MIDES):**
| Consórcio | Municípios |
|---|---|
| CIMAMS | 21 |
| CONS. INTERMUNIC. DESENVOLVIMENTO | 20 |
| CISDESTE | 14 |
| CIS-URG OESTE | 11 |

**Top 5 setores no MUNIC (1.348 pares confirmados):**
| Setor | Pares | % |
|---|---|---|
| Saúde | 869 | 64% |
| Resíduos sólidos | 263 | 20% |
| Des. urbano | 179 | 13% |
| Saneamento | 156 | 12% |
| Meio ambiente | 155 | 12% |

**Top municípios por nº de consórcios:**
| IBGE | Nº consórcios |
|---|---|
| 3111200 | 9 |
| 3135407 | 8 |
| 3109204 e 3123908 | 7 |

---

## Slide 5c — EDA: Valor pago (dados concretos)

**Estatísticas de `valor_total_periodo` (R$ deflacionado jan/2018):**
| p25 | Mediana | Média | p75 | p95 | Máx |
|---|---|---|---|---|---|
| R$54k | **R$219k** | R$1,3M | R$947k | R$4,1M | **R$264M** |

**Outlier confirmado e real:** Betim × CISMEP — R$264M total (~R$66M/ano 2014–2017, queda abrupta em 2018 → mudança estrutural)

**32 pares com `valor_atipico = TRUE`** (total < R$1.000): provável adesão simbólica sem rateio efetivo

---

## Slide 6 — EDA: Pontuação e continuidade (dados concretos)

**Distribuição de pontuação (2.835 pares MIDES + 52 MUNIC-only):**
| Pontuação | Combinação | Pares | % |
|---|---|---|---|
| 9 pts | MIDES + SICONFI + MUNIC | 1.198 | 42,3% |
| 7 pts | MIDES + SICONFI | 1.228 | 43,3% |
| 6 pts | MIDES + MUNIC | 150 | 5,3% |
| 4 pts | Só MIDES | 259 | 9,1% |
| 2 pts | Só MUNIC | 52 | 1,8% |

**`flag_continuo`:**
- Contínuo: 1.960 (69,1%)
- Descontínuo: 431 (15,2%) — lacuna média de 1,8 anos
- Ponto único: 425 (15%)
- Sem evidência: 19 (0,7%)

**`n_anos_pagamento`:** mediana = 6 anos / máx = 8 anos

---

## Charts R a gerar (5 no total) → `assets/`

| Arquivo | Dados | Takeaway | Boas práticas |
|---|---|---|---|
| `cobertura_fontes.png` | Contagens fixas | MIDES destaque, resto cinza | `plot.title.position="plot"`, `ggsave(bg="white")` |
| `eda_distribuicao.png` | Painel_universal + contagens setor | Dois painéis: top consórcios + setores | `guide_axis(check.overlap=TRUE)`, direct labels |
| `eda_valor.png` | `valor_total_periodo` do CSV v2 | Outlier Betim anotado em destaque | `size.unit="pt"` nas anotações |
| `hist_pontuacao.png` | `pontuacao_total` | Barras coloridas por faixa | Direct labels em cada barra |
| `codap_map.png` | Painel_universal + `geobr` | Membros azul `#1B6CA8`, MG `#DDDDDD` | `ggsave(bg="white")` |

---

## Paleta (compatível com template Signal)

| Papel | Hex |
|---|---|
| Destaque principal / MIDES | `#1B6CA8` |
| SICONFI | `#2E8B57` |
| MUNIC | `#E07B39` |
| CNM (pendente) | `#8B6BAE` |
| Contexto / cinza | `#AAAAAA` |
| Fundo dos charts | `#FFFFFF` |

---

## Estrutura de arquivos

```
slides/
├── PROTOTIPO.md                          ← este arquivo (planejamento)
├── 2026-05-14_apresentacao_ipea.html     ← slide final (a criar)
├── assets/
│   ├── cobertura_fontes.png
│   ├── eda_distribuicao.png
│   ├── eda_valor.png
│   ├── hist_pontuacao.png
│   └── codap_map.png
└── scripts_viz.R                         ← script R para os 5 charts
```

---

## Ordem de execução

1. ✅ `scripts_viz.R` → 5 PNGs em `assets/`
2. ✅ HTML gerado com Reveal.js 5.1 (CDN) — estilo Signal
3. ✅ PNGs embutidos via `<img src="assets/...">`
4. ⬜ Testar no browser + ajustes visuais finais
