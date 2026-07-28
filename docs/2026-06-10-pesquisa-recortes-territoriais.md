# Pesquisa - Recortes Territoriais E Institucionais

**Data de registro:** 2026-06-10  
**Projeto:** ideiaMides  
**Status:** pesquisa exploratoria para proximas etapas; nao implementada ainda  

---

## Resumo Executivo

As quatro frentes sugeridas sao viaveis, mas em niveis diferentes.

| Prioridade | Recorte | Viabilidade | Motivo |
|---:|---|---|---|
| 1 | Regioes de Saude SUS | Alta | Dados oficiais por municipio existem e combinam bem com consorcios de saude. |
| 2 | Bacias Hidrograficas | Alta/media | Ha base cartografica IGAM/SISEMA, mas municipios podem cruzar mais de uma bacia. |
| 3 | Associacoes Microrregionais AMM | Media | A AMM lista microrregionais, mas a composicao municipio a municipio precisa ser obtida. |
| 4 | Votos/deputados | Media/baixa | Dados TSE existem, mas a interpretacao causal e mais delicada. |

Recomendacao inicial:

1. Comecar por **Regioes de Saude SUS** e **Bacias Hidrograficas**.
2. Tratar **AMM microrregionais** como frente exploratoria/historica.
3. Deixar **votos/deputados** por ultimo, com desenho metodologico cauteloso.

---

## Medida Estatistica Sugerida

Criar uma medida comum para todos os recortes:

> **coerencia territorial do consorcio** = percentual de pares de municipios do mesmo consorcio que pertencem ao mesmo recorte territorial.

Exemplo:

- um consorcio com 10 municipios gera 45 pares municipio-municipio;
- se 30 desses pares estao na mesma regiao de saude;
- coerencia territorial = 30 / 45 = 66,7%.

Depois, comparar o valor observado contra sorteios aleatorios de municipios do mesmo tamanho.

Assim, a interpretacao fica:

> este consorcio e mais concentrado territorialmente do que seria esperado ao acaso?

Tabela de entrega sugerida:

| consorcio | n_municipios | recorte | regiao_dominante | pct_na_regiao_dominante | coerencia_observada | coerencia_aleatoria_media | p_valor_permutacao |
|---|---:|---|---|---:|---:|---:|---:|

---

## 1. Regioes De Saude SUS

**Viabilidade:** alta.

A SES-MG disponibiliza materiais do PDR com relacao de municipios por Unidades Regionais, Microrregioes e Macrorregioes de Saude, alem de mapas de regionalizacao. O Ministerio da Saude tambem registra a estrutura de Minas Gerais com macrorregioes e regioes de saude.

O que da para fazer:

- juntar `cod_ibge_6` do painel com macro/micro/regiao de saude;
- calcular concentracao dos consorcios por regiao de saude;
- separar consorcios de saude e consorcios nao saude;
- testar se consorcios de saude seguem mais a regionalizacao SUS que os demais.

Uso principal:

- consorcios de saude;
- comparacao entre setor declarado do consorcio e desenho territorial do SUS.

---

## 2. Bacias Hidrograficas

**Viabilidade:** alta/media.

O IGAM/SISEMA possui bases cartograficas de bacias federais e estaduais. Minas tambem e organizada em UPGRHs/circunscricoes hidrograficas.

Ponto tecnico:

> municipio nao pertence necessariamente a uma unica bacia se usarmos area total; pode atravessar divisores hidrograficos.

Caminhos possiveis:

| Metodo | Descricao | Vantagem | Limite |
|---|---|---|---|
| Centroide/sede | Classificar municipio pela bacia do centroide ou sede municipal | Simples e rapido | Pode errar municipios cortados por bacias |
| Bacia predominante | Calcular qual bacia ocupa maior area do municipio | Melhor regra unica | Exige processamento espacial |
| Pesos por area | Permitir multiplas bacias por municipio com percentual de area | Mais completo | Mais complexo de explicar e operacionalizar |

Serve especialmente para:

- saneamento;
- meio ambiente;
- residuos solidos;
- desenvolvimento regional;
- recursos hidricos.

---

## 3. Associacoes Microrregionais AMM

**Viabilidade:** media.

A hipotese e boa, mas a base ainda nao esta pronta. A AMM possui listagens publicas de microrregionais com sigla, nome, sede, contato e dirigentes. O problema e que a composicao municipio a municipio nem sempre aparece em uma tabela unica e limpa.

O que e viavel agora:

- mapear siglas e sedes das microrregionais;
- procurar relacao municipio-microrregional nos sites de cada associacao;
- consultar estatutos, PDFs, paginas proprias e materiais historicos;
- comparar nomes/siglas com consorcios, como AMAPI, AMESP, AMVA, AMEG etc.

Limite metodologico:

> Para testar se consorcios "nascem a partir" das associacoes, nao basta sobreposicao territorial. Precisamos de evidencia historica: data da associacao, data do consorcio, estatuto, ata, sede, dirigentes e municipios fundadores.

---

## 4. Votos E Deputados

**Viabilidade:** media/baixa.

O TSE possui dados de votacao nominal por municipio, zona e secao. Portanto, tecnicamente e possivel construir territorios eleitorais aproximados de deputados estaduais e federais.

O que da para fazer:

- para cada deputado, calcular municipios onde teve maior votacao relativa;
- criar uma medida de "base eleitoral forte";
- medir se consorcios se concentram em areas de votacao de um ou mais deputados;
- comparar deputados estaduais e federais;
- observar eleicoes de 2014, 2018 e 2022, conforme o periodo dos consorcios.

Cuidados:

- zona eleitoral nao e territorio politico do deputado; e unidade administrativa da Justica Eleitoral;
- correlacao pode refletir populacao, regiao, partido, base municipal, saude, distancia ou outros fatores;
- e a frente com maior risco de interpretacao politica indevida.

Recomendacao:

> Tratar como analise exploratoria de sobreposicao territorial, nao como evidencia direta de causalidade politica.

---

## Ordem Recomendada De Implementacao

1. **Regioes de Saude SUS**: melhor custo-beneficio e dados oficiais mais prontos.
2. **Bacias Hidrograficas**: tambem forte, mas exige decisao espacial sobre municipio em multiplas bacias.
3. **AMM microrregionais**: boa hipotese institucional, mas demanda montagem de base propria.
4. **Votos/deputados**: deixar por ultimo, com cautela metodologica e comunicacao muito cuidadosa.

