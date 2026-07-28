# Boas Práticas — Slides e DataViz
**Criado em:** 2026-05-14
**Fontes:**
- Cédric Scherer — *"Guide the View"* (2026) · `cedricscherer.com/slides/`
- Nicola Rennie — *"Five ggplot2 functions I wish I'd known about earlier"* · `nrennie.rbind.io/blog/`
- Template library: `github.com/zarazhangrui/beautiful-html-templates`

> Este arquivo registra princípios e técnicas que guiam a construção dos slides do projeto ideiaMides.
> Objetivo: slides bonitos, informativos e honestos — não apenas estéticos.

---

## 1. Filosofia central — "Guide the View" (Scherer)

O princípio unificador de Scherer: **o designer é um guia, não um arquivista**. Não basta mostrar os dados — é preciso conduzir o olho do leitor exatamente para onde a mensagem está.

### 1.1 Hierarquia visual intencional

| Elemento | Papel |
|---|---|
| **Cor de destaque** | Chama atenção para o dado mais importante — use UMA cor principal |
| **Cinza** | "Silencia" o contexto — tudo que não é a mensagem vira cinza |
| **Tamanho** | Hierarquia: elementos maiores = mais importantes |
| **Posição** | Elemento principal sempre no centro ou canto superior esquerdo (leitura natural) |
| **Anotações diretas** | Substituem legendas — o leitor não precisa sair do gráfico para entender |

### 1.2 O título é a mensagem, não a descrição

```
❌ Ruim: "Distribuição de pontuação por par município × consórcio"
✅ Bom:  "A maioria dos pares têm confirmação de pelo menos 2 fontes independentes"
✅ Bom:  "161 de 223 consórcios têm pagamento confirmado pelo MIDES"
```

O subtítulo pode trazer o "como" (fonte, período, universo). O título traz o "portanto".

### 1.3 Princípio do destaque único por gráfico

- **Uma cor de acento** (ex: azul, laranja) para o dado principal
- Todos os demais elementos em `"#AAAAAA"` (cinza médio) ou `"#DDDDDD"` (cinza claro)
- Legenda muitas vezes dispensável se há direct labels

```r
# Exemplo de paleta highlight
cores <- c(
  "destaque"  = "#1B6CA8",   # azul IPEA
  "contexto"  = "#AAAAAA",   # cinza para tudo mais
  "alerta"    = "#E05A3A"    # laranja para exceções
)
```

### 1.4 Redução de ruído visual (data-ink ratio)

Remover progressivamente:
1. Bordas do painel (`panel.border = element_blank()`)
2. Linhas de grade menores (`panel.grid.minor = element_blank()`)
3. Ticks desnecessários (`axis.ticks = element_blank()`)
4. Linhas de grade maiores quando o dado é categórico
5. Fundo do painel (`panel.background = element_blank()`)

```r
# Base theme para o projeto ideiaMides
theme_mides <- function() {
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 15),
    plot.title.position = "plot",           # alinha ao plot inteiro (ver seção 2.3)
    plot.subtitle    = element_text(color = "#555555", size = 11),
    plot.caption     = element_text(color = "#999999", size = 9),
    plot.caption.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#EEEEEE"),
    axis.ticks       = element_blank(),
    legend.position  = "none"              # preferir direct labels
  )
}
```

---

## 2. Técnicas R/ggplot2 (Nicola Rennie)

### 2.1 `guide_axis(check.overlap = TRUE)` — eixos limpos em facets

Quando há muitos rótulos no eixo x (anos, categorias longas), use dentro de `scale_x_*()`:

```r
g + scale_x_continuous(
  guide = guide_axis(check.overlap = TRUE)
)
```

Remove silenciosamente os rótulos sobrepostos, mantendo o primeiro, o último e o do meio.
**Aplicação no projeto:** ano no eixo x de gráficos de cobertura temporal (2013–2024).

---

### 2.2 `size.unit = "pt"` em `geom_text()` / `geom_label()`

O tamanho padrão em `geom_text()` é em **milímetros** — diferente do `theme()` que usa **pontos**.
Isso causa confusão quando você tenta igualar o tamanho do rótulo ao do título.

```r
# ❌ Errado — size=12 em mm fica gigante
geom_text(aes(label = pontuacao), size = 12)

# ✅ Correto — size=12 em pontos, consistente com theme(text = element_text(size=12))
geom_text(aes(label = pontuacao), size = 12, size.unit = "pt")
```

**Aplicação no projeto:** rótulos de pontuação nos gráficos de barras.

---

### 2.3 `plot.title.position = "plot"` — título alinhado ao gráfico inteiro

Por padrão, o título alinha ao **painel** (área interna). Com eixo y longo (nomes de municípios), o título fica deslocado para a direita.

```r
theme(
  plot.title.position   = "plot",   # alinha título + subtítulo ao plot inteiro
  plot.caption.position = "plot"    # mesma lógica para o caption/fonte
)
```

**Aplicação no projeto:** qualquer gráfico com nomes de consórcios ou municípios no eixo y.

---

### 2.4 `after_stat()` — estatísticas computadas sem transformação prévia

Permite usar variáveis computadas pela camada geom diretamente no `aes()`:

```r
# Frequência relativa sem precisar criar coluna % antes
ggplot(painel, aes(x = pontuacao_total)) +
  geom_bar(aes(y = after_stat(count / sum(count)))) +
  scale_y_continuous(labels = scales::label_percent())
```

Evita criar uma coluna intermediária só para plotar proporções.

---

### 2.5 `ggsave(bg = "white")` — fundo transparente em slides escuros

Temas como `theme_minimal()` podem gerar PNG com fundo transparente. Em slides com fundo colorido (ex: Signal — navy), o gráfico aparece com fundo preto/transparente.

```r
# Sempre especificar bg ao salvar para slides
ggsave(
  "outputs/viz/histograma_pontuacao.png",
  plot   = p,
  width  = 8,
  height = 5,
  dpi    = 150,
  bg     = "white"   # ou a cor de fundo do slide
)
```

**Regra geral:** sempre use `bg = "white"` para outputs do projeto, a menos que o template do slide tenha fundo branco garantido.

---

### 2.6 Bônus: `scale_y_symmetric()` do pacote `lemon`

Para dados divergentes (ex: variação, resíduos), garante que o zero fique no centro visual:

```r
library(lemon)
g + scale_y_symmetric()
```

Útil em visualizações comparativas (ex: municípios acima/abaixo da média de consórcios).

---

## 3. Design de slides — princípios gerais

### 3.1 Estrutura de cada slide

```
[Título = takeaway em 1 linha]
[Subtítulo = contexto: fonte, período, universo]

[Visual principal — ocupa 70-80% da área]

[Caption pequeno: fonte dos dados]
```

- **Um ponto por slide** — se você precisa explicar mais de uma coisa, faça dois slides
- **Nunca bullet points longos** — prefira visual + rótulos diretos

### 3.2 Progressão narrativa sugerida para ideiaMides

```
1. O problema   → "Quem participa de quais consórcios? Nenhuma fonte sabe sozinha."
2. A solução    → "Triangulamos 4 fontes independentes com sistema de pontuação."
3. O pipeline   → Diagrama: BigQuery → MIDES → CSV → Pontuação → Painel
4. Os números   → "2.887 pares / 223 consórcios / max 9 pts"
5. O sistema    → Tabela: fonte × pts × cobertura
6. Cobertura    → Barras: MIDES 161 / MUNIC 149 / CNM (em breve) / total 223
7. Exemplo real → CODAP: mapa + distribuição de pontuação
8. Descobertas  → 52 novos pares via MUNIC, 1.429 censurados, 134 fora do cadastro
9. Dúvidas      → 3 questões para Paulo
10. Próximos    → CNM robot → pré-2014 → output final → outros estados
```

### 3.3 Paleta de cores sugerida para o projeto (compatível com template Signal)

| Papel | Hex | Uso |
|---|---|---|
| Primária | `#1B6CA8` | MIDES — fonte principal |
| Secundária | `#2E8B57` | SICONFI |
| Terciária | `#E07B39` | MUNIC |
| Quaternária | `#8B6BAE` | CNM |
| Contexto | `#AAAAAA` | dados sem destaque |
| Alerta | `#E05A3A` | alertas, limitações |
| Fundo claro | `#F8F6F2` | paper Signal |
| Texto principal | `#1A1A2E` | navy Signal |

### 3.4 Tipografia

- **Títulos dos slides:** peso bold, 28-36pt
- **Takeaway do gráfico (labs(title)):** bold, 14-16pt
- **Rótulos de dados:** 10-12pt, `size.unit = "pt"`
- **Caption/fonte:** 8-9pt, cor `#999999`
- **Nunca mais de 3 níveis de hierarquia** num mesmo visual

---

## 4. Template HTML escolhido

**Template:** `Signal` — `github.com/zarazhangrui/beautiful-html-templates/tree/main/templates/signal`

Características:
- Deep navy canvas com papel bone e acento gold/muted
- Tom institucional — adequado para apresentação IPEA
- HTML puro → abre em qualquer browser, fácil de compartilhar
- Segue o manual `AGENTS.md` do repositório para customização por agente

**Workflow de construção:**
1. Gerar plots R → `ggsave(..., bg = "white")` em `outputs/viz/`
2. Clonar template Signal
3. Embutir plots como `<img src="...">` ou base64
4. Ajustar conteúdo textual seguindo estrutura da seção 3.2

---

## 5. Checklist antes de exportar

- [ ] Título de cada gráfico = takeaway (não descrição)
- [ ] Máximo 1 cor de destaque por gráfico
- [ ] `plot.title.position = "plot"` em todos os plots
- [ ] `ggsave(bg = "white")` em todos os saves
- [ ] `size.unit = "pt"` em todos os `geom_text()`/`geom_label()`
- [ ] Fonte dos dados no caption de cada gráfico
- [ ] `guide_axis(check.overlap = TRUE)` em gráficos com muitos rótulos de eixo
- [ ] Legenda substituída por direct labels onde possível
- [ ] Slides sem bullet points longos — visual + rótulo é o padrão
