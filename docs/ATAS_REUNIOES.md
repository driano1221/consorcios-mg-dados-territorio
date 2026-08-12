# Atas E Resumos De Reunioes

**Projeto:** Consórcios MG: Dados e Território
**Arquivo criado em:** 2026-06-10  
**Uso:** concentrar atas, resumos executivos e encaminhamentos de reunioes do projeto.

---

## Indice

| Data | Tema principal | Status |
|---|---|---|
| 2026-05-29 | Discussao metodologica sobre temporalidade das fontes, SICONFI e bases analiticas | Registrada |
| 2026-08-06 | Validacao dos movimentos MIDES, casos esparsos e universo do modelo | Data a confirmar; ata em `docs/reunioes/2026-08-06-validacao-mides-universo-modelo.md` |

> Novas atas devem ser criadas individualmente em `docs/reunioes/`. Este arquivo permanece como registro historico da ata de 29/05 e indice de compatibilidade.

---

## 2026-05-29 - Temporalidade Das Fontes, SICONFI E Bases Analiticas

**Participantes citados na transcricao:** Adriano, Paulo, Pedro.  
**Tipo de registro:** resumo a partir de transcricao automatica, com ruidos de audio e repeticoes removidos.  
**Status:** ata interpretativa; nao substitui decisao metodologica formal.

### Contexto

A reuniao discutiu uma preocupacao metodologica central: as fontes do projeto nao observam os mesmos anos nem possuem a mesma unidade de informacao.

Isso afeta diretamente a interpretacao da pontuacao total, sobretudo quando ela e lida como "retrato atual" ou como evidencia historica ano a ano.

### Periodos E Natureza Das Fontes

| Fonte | Periodo discutido | Unidade principal | Observacao metodologica |
|---|---|---|---|
| MIDES | 2014-2021 | municipio x consorcio | Melhor fonte longitudinal para pares; observa pagamentos correntes. |
| SICONFI | 2013-2024 | municipio x ano | Indica transferencia para consorcios, mas nao identifica o CNPJ/consorcio destino. |
| MUNIC | 2015 e 2019 | municipio x consorcio | Fonte pontual, util para anos especificos. |
| CNM | retrato atual, 2026 | municipio x consorcio | Boa para fotografia atual, mas nao reconstrui historico anual. |

### Ponto Principal Sobre Pontuacao

Foi discutido que a pontuacao maxima nao deve ser interpretada da mesma forma para todos os anos, porque nem todas as fontes existem ou sao observaveis em todos os anos.

Exemplo:

- a escala completa atual soma 15 pontos: MIDES=8, SICONFI=4, MUNIC=2, CNM=1;
- mas CNM e um retrato atual, nao uma serie historica anual;
- MUNIC so contribui diretamente em 2015 e 2019;
- portanto, a escala completa funciona melhor como **retrato integrado de evidencias**, nao como pontuacao anual perfeitamente comparavel.

### Discussao Sobre Bases Analiticas Possiveis

Foi sugerido separar o uso das fontes conforme a pergunta de pesquisa.

#### Base 1 - Painel com MUNIC

Possivel base focada nos anos **2015 e 2019**:

- MIDES;
- SICONFI;
- MUNIC;
- sem CNM, porque CNM nao permite saber o vinculo historico em 2015 ou 2019.

Uso possivel:

- comparar os dois anos em que MUNIC permite observacao de municipio x consorcio;
- avaliar evolucao entre 2015 e 2019;
- aceitar uma janela menor em troca de incluir MUNIC.

Limite:

- apenas dois anos de observacao;
- depende da qualidade e consistencia da MUNIC.

#### Base 2 - Painel longitudinal MIDES + SICONFI

Possivel base para periodo **2014-2021**:

- MIDES;
- SICONFI como apoio/validacao;
- sem MUNIC, para evitar limitar a analise a 2015 e 2019;
- sem CNM, por ser fotografia atual.

Uso possivel:

- acompanhar a trajetoria de pagamentos ao longo de oito anos;
- validar ou tensionar evidencias MIDES com informacao contábil agregada do SICONFI;
- trabalhar melhor a dimensao temporal.

Limite:

- SICONFI nao identifica o consorcio destino;
- nao confirma diretamente o par municipio x consorcio.

#### Base 3 - Retrato Atual Integrado

Base atual do projeto:

`outputs/csv_base/2026-05-21_painel_universal_mg_v2.csv`

Caracteristicas:

- integra MIDES, SICONFI, MUNIC e CNM;
- unidade principal: par municipio x consorcio;
- 3.380 pares;
- 32 variaveis;
- pontuacao maxima de 15 pontos.

Uso adequado:

- retrato integrado de evidencias;
- comunicacao institucional;
- identificacao de pares mais fortemente confirmados;
- analises exploratorias por setor e cobertura de fontes.

Limite:

- nao deve ser tratada automaticamente como painel anual completo;
- mistura fontes com temporalidades diferentes.

### Discussao Especifica Sobre SICONFI

Foi reforcado um ponto critico:

> SICONFI informa que o municipio declarou transferencia para consorcio, mas nao identifica qual consorcio recebeu.

Consequencia:

- SICONFI nao e uma fonte independente de par municipio x consorcio;
- ele nao deve ser usado sozinho para criar vinculos com CNPJ especifico;
- quando associado a um par MIDES, ele funciona mais como reforco indireto ou alerta de consistencia;
- pode ser util para investigar municipios que declaram transferencias para consorcios no SICONFI, mas nao aparecem em outras fontes.

Risco discutido:

> Se um municipio aparece no MIDES com tres consorcios, e o SICONFI so diz que houve transferencia para consorcio, nao e possivel afirmar que o SICONFI confirmou os tres pares individualmente.

Encaminhamento metodologico sugerido:

- tratar SICONFI como apoio residual, validacao ou sinal de alerta;
- evitar apresentar SICONFI como confirmacao plena do par municipio x consorcio;
- nas analises de intersecao entre fontes, explicitar que SICONFI nao tem a mesma granularidade das demais.

### Discussao Sobre Pares E Contagens

Foi reafirmada a unidade conceitual do projeto:

> um par = um municipio vinculado a um consorcio.

Pontos esclarecidos:

- os numeros dos graficos nao representam municipios unicos;
- um mesmo municipio pode aparecer em mais de um consorcio;
- um mesmo par pode aparecer em mais de uma fonte;
- macroareas CNM podem somar mais que o total de pares CNM, porque um par pode atuar em mais de uma area tematica.

Exemplo discutido:

- 1.707 pares em saude nao significa 1.707 municipios unicos;
- significa pares municipio x consorcio classificados em saude;
- como Minas tem 853 municipios, isso indica que muitos municipios participam de mais de um consorcio de saude.

### Observacoes Sobre MUNIC

Houve percepcao de que a intersecao da MUNIC com outras fontes pode ser pequena em alguns cortes.

Pontos levantados:

- MUNIC e util por trabalhar com par municipio x consorcio;
- mas sua cobertura temporal e restrita a 2015 e 2019;
- a consistencia com MIDES e CNM deve ser analisada com cautela;
- para algumas perguntas, pode reduzir demais a janela de observacao.

### Encaminhamentos

1. Manter a base atual v2 como **retrato integrado de evidencias**, nao como painel anual completo.
2. Considerar uma separacao metodologica entre:
   - base 2015/2019 com MIDES + SICONFI + MUNIC;
   - base 2014/2021 com MIDES + SICONFI;
   - retrato atual com MIDES + SICONFI + MUNIC + CNM.
3. Reavaliar a comunicacao sobre SICONFI:
   - nao afirmar que ele confirma diretamente o par;
   - explicar que ele confirma transferencia municipal para consorcios, sem CNPJ destino.
4. Nos slides e documentos, deixar claro quando a contagem e de pares e quando seria de municipios.
5. Tratar a pontuacao total como indice de evidencia integrada, nao como medida anual uniforme.

### Pontos Para Revisao Futura

- Verificar se a coluna `pontuacao_siconfi` deve continuar com o mesmo peso em analises de intersecao.
- Avaliar se os slides devem distinguir visualmente "fontes de par" e "fonte municipal agregada".
- Criar, se necessario, versoes analiticas separadas da base:
  - `painel_2015_2019_mides_siconfi_munic`;
  - `painel_2014_2021_mides_siconfi`;
  - `retrato_atual_integrado_v2`.
- Revisar textos que possam sugerir que CNM retroage historicamente para 2019.
