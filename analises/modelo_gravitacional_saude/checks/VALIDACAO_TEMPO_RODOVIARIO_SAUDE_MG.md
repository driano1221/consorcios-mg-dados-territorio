# Validacao: Tempo Rodoviario Da Oferta Fixa De Saude (MG)

- Fonte: [Zenodo 11400243](https://zenodo.org/records/11400243), publicada em 31/05/2024.
- MD5 validado: `39f71b10ddf9fda7c53e2b39fa6bd202`.
- OSRM/OpenStreetMap, perfil car; sedes municipais IBGE 2010; ida/volta simetricas.
- Relatorio regenerado pelo script 06 com a classificacao do script 05.

| Camada | Linhas | Destinos |
|---|---:|---:|
| Municipio x municipio de oferta | 53739 | 63 |
| Municipio x estrutura fixa candidata | 69946 | 82 |
| Municipio x entidade | 71652 | 84 |

- Entidades com tempo: 61; linhas sem tempo: 19619.
- Rotas entre municipios diferentes sem tempo: 0.

## Estatisticas Preliminares Dos Trajetos Intermunicipais

| Estatistica | Minutos |
|---|---:|
| 0% | 6.2 |
| 25% | 273 |
| 50% | 415.9 |
| 75% | 573 |
| 95% | 787.9 |
| 100% | 1162.3 |

## Exemplo E Limites

- Igarape x CISMEP: minimo 0; mediana 11.75; maximo 25.8 minutos.
- A correcao de 10/09 retirou 307 unidades de tipo movel da oferta fixa; os snapshots de 03/09 preservam a classificacao anterior.
- Estruturas nao moveis ainda exigem filtro clinico: central administrativa/regulatoria nao e hospital.
- Duas fichas com indicio nominal de mobilidade e tipo conflitante/ausente permanecem fora da oferta fixa.
- Tempo zero representa mesmo municipio; nao equivale a viagem porta a porta nula.
- A matriz e estatica, sem transito por horario nem rede viaria anual de 2014-2021.
- Grade estadual completa nao e conjunto final de alternativas; capacidade historica sera ligada no passo 6.
