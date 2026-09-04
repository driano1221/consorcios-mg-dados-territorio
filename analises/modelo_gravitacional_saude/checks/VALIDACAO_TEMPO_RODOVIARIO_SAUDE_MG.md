# Validacao: Tempo Rodoviario Da Oferta Fixa De Saude (MG)

- Fonte: [Zenodo 11400243](https://zenodo.org/records/11400243), publicado em
  31/05/2024.
- Metodo da fonte: OSRM/OpenStreetMap, perfil `car`, entre sedes municipais do
  IBGE 2010.
- Arquivo: `dist_brasil.rds`, 71.011.704 bytes.
- MD5 validado: `39f71b10ddf9fda7c53e2b39fa6bd202`.
- A fonte assume ida igual a volta e nao considera transito por horario.

## Cobertura

| Camada | Linhas | Origens | Destinos/alternativas |
|---|---:|---:|---:|
| Municipio x municipio de oferta | 203.014 | 853 | 238 municipios |
| Municipio x unidade CNES fixa | 331.817 | 853 | 389 unidades |
| Municipio x entidade completa | 71.652 | 853 | 84 entidades |

- 61 entidades possuem tempo para ao menos uma unidade fixa: 52.033 linhas.
- 21 entidades sem unidade direta e duas somente moveis permanecem com tempo
  `NA`: 19.619 linhas.
- A fonte contem os 363.378 pares internos de MG (`choose(853, 2)`), sem rota
  ausente.

## EDA Dos Tempos

### Municipio Ate Municipio De Oferta, Excluindo O Mesmo Municipio

| Estatistica | Minutos |
|---|---:|
| Minimo | 5,2 |
| P25 | 279,4 |
| Mediana | 428,7 |
| P75 | 596,2 |
| P95 | 821,0 |
| Maximo | 1.219,0 |

### Menor Tempo Por Entidade

| Estatistica | Minutos |
|---|---:|
| Minimo | 0,0 |
| P25 | 261,1 |
| Mediana | 410,4 |
| P75 | 565,6 |
| P95 | 777,7 |
| Maximo | 1.162,3 |

Os tempos elevados nao sao falha de cobertura: a grade combina todos os 853
municipios com todas as entidades de oferta fixa em MG. Ela ainda nao define
quais consorcios formam o conjunto de escolha plausivel de cada municipio.

## Controles De Plausibilidade

- Nenhuma rota entre municipios distintos possui tempo ou distancia zero.
- Nao ha distancia ou duracao ausente em MG.
- A velocidade implicita varia de 25,4 a 85,9 km/h, com mediana de 69,1 km/h;
  nao foram encontrados valores abaixo de 10 ou acima de 130 km/h.
- Os 56.644 trajetos entre os 238 municipios de oferta reproduzem exatamente a
  simetria declarada pela fonte, incluindo a diagonal.
- Existem 277 combinacoes entidade x municipio de oferta fixa. Para essas
  combinacoes, o tempo intermunicipal e zero quando a origem coincide com o
  municipio da unidade.

## Exemplos Reais

| Origem | Entidade | Destino fixo mais proximo | Minimo | Mediana | Maximo |
|---|---|---|---:|---:|---:|
| Abaete | CISMEP | Igarape | 170,9 min | 171,3 min | 171,7 min |
| Abaete | CISVER | Sao Joao del Rei | 252,2 min | 252,2 min | 252,2 min |
| Itajuba | CISMAS | Itajuba | 0,0 min | 0,0 min | 0,0 min |
| Para de Minas | CISMEP | Sao Joaquim de Bicas | 58,3 min | 59,0 min | 59,8 min |
| Pocos de Caldas | CISMARPA | Pocos de Caldas | 0,0 min | 0,0 min | 0,0 min |

O zero nos dois ultimos casos locais nao e tempo porta a porta. Ele indica que
origem e unidade estao no mesmo municipio e que a fonte mede apenas deslocamento
entre sedes municipais.

## Redes Com Maior Extensao Direta

| Entidade | Municipios de oferta fixa | Unidades fixas |
|---|---:|---:|
| CISDESTE | 48 | 71 |
| CISNORJE | 39 | 48 |
| CIS-URG OESTE | 36 | 52 |
| CONSURGE | 28 | 41 |
| CISRU-CENTRO SUL | 19 | 25 |

O minimo ate a rede e util como acessibilidade inicial, mas pode apontar para
uma unidade que nao oferece a especialidade relevante. Por isso, a camada por
unidade permanece como fonte principal e minimo, mediana e maximo sao mantidos
para sensibilidade.

## Limites

- Sede municipal, nao endereco exato do estabelecimento.
- Duracao estatica do OSRM, sem saida especifica as 10h30 de sabado.
- Ida e volta simetricas por construcao da fonte.
- Infraestrutura rodoviaria e sedes nao formam uma serie anual 2014-2021.
- A grade estadual completa nao equivale ao conjunto de consorcios que cada
  municipio realmente poderia escolher.
