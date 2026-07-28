# Memoria Codex - 2026-05-29

## Conversas e decisoes

- Etapa 11 foi colocada em pausa por enquanto; nao vamos mexer com SICONV agora.
- CNM ja esta integrada ao painel v2 como confirmacao de vinculo, mas nao resolve sozinha o historico pre-2014.
- Para anos/duracao, a base usa principalmente MIDES:
  - `ano_entrada_proxy` = primeiro ano com pagamento corrente observado.
  - `ultimo_ano_corrente` = ultimo ano com pagamento corrente observado.
  - `n_anos_pagamento` = quantidade de anos distintos com pagamento corrente no MIDES.
  - `ainda_ativo` = TRUE quando ha pagamento corrente no ultimo ano da serie MIDES.
- A coluna `ANOS` mostrada no slide e `n_anos_pagamento`; nao e idade do consorcio nem duracao real do vinculo.
- Pares CNM-only ou MUNIC-only nao recebem ano MIDES inventado; ficam com `n_anos_pagamento = 0` quando nao ha pagamento MIDES.

## Mudancas feitas

- Criado `scripts/07_auditoria_fora_cadastro_mg.R`.
- Gerado `outputs/auditoria/2026-05-29_candidatos_fora_cadastro_mg.csv`.
- Auditoria fora do cadastro MG:
  - 143 CNPJs candidatos.
  - 843 pares municipio-consorcio unicos fora do painel principal.
  - Maior caso: CONECTAR, CNPJ `41774599000106`, com 414 vinculos CNM-MG.
- Atualizados registros/documentacao:
  - `docs/2026-05-14-HANDOFF.md`
  - `docs/MEMORIA_ideiaMides.md`
  - `C:\IPEA\dados cnm\PROXIMOS_PASSOS.md`
- Revisada e corrigida a apresentacao `slides/2026-05-14_apresentacao_ipea.html`.
- Correcoes principais no slide:
  - Pag. 3: removida ideia de pares com pontuacao zero no painel.
  - Pag. 3: exemplo trocado para `Cristiano Otoni x CODAP`.
  - Pag. 6: tabela de exemplo corrigida contra o CSV v2.
  - Pag. 13: CNM passou de etapa futura para fonte ja integrada.
  - Pag. 13: SICONV removido das proximas fontes visiveis.
  - Pag. 14: rotulos dos scripts `04` e `05` corrigidos para nao confundir com o painel v2.
- Observacao: o HTML atual tem 14 slides reais, embora memorias anteriores mencionem 15.

## Proximos passos

- A definir pelo usuario.
- Nao iniciar SICONV ate nova orientacao.
- Se voltar ao tema pre-2014, priorizar fontes com data historica clara, como CNM historico, SES-MG e PDFs do projeto.
