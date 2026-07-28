# ideiaMides

Painel longitudinal de participacao municipal em consorcios intermunicipais. O piloto atual cobre Minas Gerais e combina MIDES, MUNIC, SICONFI, cadastro IPEA e, no painel universal historico, CNM.

## Comece Aqui

| Para que | Arquivo ou pasta |
|---|---|
| Estado atual e decisoes | `docs/MEMORIA_ideiaMides.md` |
| Proximos passos | `docs/PROXIMOS_PASSOS.md` |
| Indice dos documentos | `docs/DICIONARIO_MEMORIAS.md` |
| Base 1 2015/2019 | `analises/base_1_2015_2019/` |
| Classificacao de politicas | `docs/METODOLOGIA_CLASSIFICACAO_ATUAL.md` |
| Dashboard publicado | `dashboards/base1_shiny/` |
| Estrutura e versionamento | `docs/ESTRUTURA_REPOSITORIO.md` |

## Produtos Atuais

1. **Painel universal MG v2**: produto historico integrado, com MIDES, SICONFI, MUNIC e CNM. Unidade: `municipio x consorcio`.
2. **Base 1 2015/2019**: recorte comparavel MIDES-MUNIC. SICONFI e validacao financeira no nivel `municipio x ano`, nao fonte de par.
3. **Dashboard Shiny**: consulta da Base 1, MIDES completo, transicao 2015-2019, auditorias e documentacao metodologica.
4. **Classificacao de areas de politica publica v0.5**: 217 CNPJs ativos, com fonte, regra e status rastreaveis.

Dashboard: <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>

## Estrutura

```text
ideiaMides/
├── analises/
│   ├── base_1_2015_2019/          # Scripts, checks e metodologia do recorte 2015/2019
│   └── classificacao_politicas/   # Taxonomia e camadas v0.1-v0.5
├── dados/                         # Bases locais pesadas: fora do Git
├── dashboards/base1_shiny/        # App Shiny e arquivos de deploy
├── docs/                          # Memoria, metodologia, atas e decisoes
├── outputs/                       # Produtos historicos e mapas gerados: fora do Git
├── scripts/                       # Pipeline do painel universal MG
└── slides/                        # Apresentacoes e scripts de visualizacao
```

## Regras De Versionamento

- Codigo, metodologia, decisoes e pequenos arquivos de configuracao entram no Git.
- Dados brutos, RDS, CSVs de output, logs, bundles de deploy e mapas gerados ficam locais e estao no `.gitignore`.
- Cada mudanca metodologica relevante deve atualizar `docs/MEMORIA_ideiaMides.md`, `docs/PROXIMOS_PASSOS.md` e, quando aplicavel, a metodologia especifica da analise.
- Nao consolidar valores financeiros de matriz/filial sem decisao metodologica expressa.

## Estado Metodologico Atual

- `provisoria_coerente`, `provisoria_cadastro` e `provisoria_nome` foram validadas para uso analitico na v0.5.
- Classificacao de filial herda apenas tipo e area da matriz pela raiz de 8 digitos do CNPJ.
- Valores MIDES, SICONFI, pares e movimentos continuam sem consolidacao matriz/filial.
- A frente seguinte, ainda nao iniciada, e a base anual analitica de movimentos no MIDES completo.
