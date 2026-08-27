# Comparacao dos snapshots CNM

**Snapshot anterior:** 2026-05-14
**Snapshot atual:** 2026-08-27

## Resumo

| indicador              |   maio |   agosto |   diferenca |
|:-----------------------|-------:|---------:|------------:|
| consorcios             |    728 |      727 |          -1 |
| municipios_unicos      |   4814 |     4816 |           2 |
| vinculos_brutos        |  13119 |    13133 |          14 |
| pares_unicos           |  13095 |    13109 |          14 |
| consorcios_adicionados |      0 |        0 |           0 |
| consorcios_removidos   |      1 |        0 |          -1 |
| vinculos_adicionados   |      0 |       23 |          23 |
| vinculos_removidos     |      9 |        0 |          -9 |

## Mudancas e auditorias

| Item | Registros |
|---|---:|
| Mudancas cadastrais campo a campo | 1 |
| Consorcios com mudanca de areas | 1 |
| CNPJs invalidos | 1 |
| CNPJs repetidos | 0 |
| Linhas com IBGE invalido | 0 |
| Linhas em pares repetidos | 48 |

Os vinculos sao comparados por `consorcio_uuid + municipio_ibge`. A comparacao identifica mudancas entre fotografias cadastrais; ela nao reconstrui a data exata da entrada ou saida do municipio.
