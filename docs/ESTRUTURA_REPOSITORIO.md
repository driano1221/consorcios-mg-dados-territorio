# Estrutura E Versionamento Do Repositorio

## Objetivo

Manter codigo, metodologia e decisoes do projeto Consorcios MG: Dados e Territorio em uma unica trilha versionada, sem duplicar bases pesadas nem alterar caminhos usados pelo dashboard e pelas analises existentes.

## O Que Entra No Git

| Tipo | Exemplos |
|---|---|
| Codigo | `scripts/*.R`, `analises/**/scripts/*.R`, `dashboards/base1_shiny/app.R` |
| Documentacao | `README.md`, `docs/*.md`, metodologias e atas |
| Configuracao | `.gitignore`, `deploy_app.R`, `.rscignore` |
| Pequenos insumos decisorios | CSVs de decisao humana em `analises/classificacao_politicas/inputs/` |

## O Que Fica Local

| Tipo | Motivo |
|---|---|
| Dados brutos e processados | Tamanho, sensibilidade e reprodutibilidade local |
| Outputs CSV/RDS/XLSX | Sao derivados por scripts e podem ser grandes |
| Dados internos do app Shiny | Fazem parte do bundle de deploy e sao pesados |
| Logs, previews e arquivos temporarios | Nao sao fonte de verdade metodologica |
| Dependencias Node e artefatos de slides | Podem ser recriados a partir dos scripts/fontes e aumentariam muito o historico |

Essas regras estao em `.gitignore`.

## Pastas Existentes

| Pasta | Papel | Regra |
|---|---|---|
| `scripts/` | Pipeline historico do painel universal MG | Preservar como legado reprodutivel |
| `analises/base_1_2015_2019/` | Recorte comparavel e validacao SICONFI | Usar para Base 1; nao substitui painel universal |
| `analises/classificacao_politicas/` | Taxonomia e auditoria setorial | v0.5 e camada analitica atual |
| `analises/modelo_gravitacional_saude/` | Preparacao separada do recorte saude-MG | Manter scripts, testes e relatorios fora do dashboard ate validacao final |
| `dashboards/base1_shiny/` | Aplicacao publicada | Nao mover `app.R` ou `data/` sem atualizar deploy |
| `docs/` | Fonte de verdade para decisoes e memoria | Atualizar ao concluir frente relevante |
| `dados/` e `outputs/` | Insumos e resultados locais | Nao versionar arquivos pesados |
| `slides/` | Materiais de reuniao | Preservar fontes e scripts; HTMLs sao artefatos de entrega |
| `docs/reunioes/` | Atas individuais, indice e template das reunioes semanais | Versionar atas sanitizadas; encaminhamentos abertos tambem devem atualizar `PROXIMOS_PASSOS.md` |

## Rotina De Atualizacao

1. Alterar codigo ou metodologia.
2. Reexecutar e validar o script afetado.
3. Atualizar a memoria, proximos passos e o diario de trabalho quando a sessao for relevante.
4. Revisar `git status` para garantir que bases pesadas nao entraram por engano.
5. Atualizar `docs/DIARIO_DE_TRABALHO.md` com decisao, arquivos alterados, validacoes e pendencias.
6. Criar um commit com mensagem objetiva, por exemplo: `classificacao: validar casos coerentes v0.5`.
7. Enviar o commit para `origin` ao encerrar a sessao.

## Remoto

Repositório público: <https://github.com/driano1221/consorcios-mg-dados-territorio>.

O repositório público contém código, testes e documentação. As bases locais pesadas e os outputs derivados continuam excluídos pelo `.gitignore`.

## Limite Atual

Este repositorio organiza o que ja existe; nao moveu dados nem reescreveu caminhos do app. Uma reorganizacao fisica de dados so deve ocorrer depois de um teste completo de scripts e deploy, para evitar quebrar a reproducibilidade atual.

O projeto ainda não possui `renv.lock`. Portanto, as versões exatas das dependências R não estão congeladas e essa limitação deve ser considerada em novas máquinas.
