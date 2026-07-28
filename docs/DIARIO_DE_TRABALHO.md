# Diario De Trabalho - ideiaMides

**Uso:** registro breve por data de trabalho. Complementa as atas e a memoria consolidada: documenta o que foi alterado, validado e deixado pendente.

## Como Registrar

Ao encerrar uma sessao relevante, adicionar uma entrada com:

1. decisoes recebidas;
2. entregas e arquivos alterados;
3. validacoes executadas;
4. pendencias que permanecem abertas.

---

## 2026-07-28 - Classificacao v0.5, Documentacao E Repositorio

### Decisoes Incorporadas

- Validar os 94 casos `provisoria_coerente` para uso analitico.
- Manter a regra matriz-filial apenas para classificacao de area e perfil; nao consolidar pagamentos, pares ou movimentos.
- Manter 16 multifinalitarios/multissetoriais apenas como perfil institucional quando nao houver area setorial explicita.
- Retirar da camada analitica ativa os seis CNPJs inaptos ou baixados, preservando-os na camada tecnica.

### Entregas

- Criada a camada analitica `v0.5` por `analises/classificacao_politicas/07_consolidar_classificacao_v0_5.R`.
- Resultado v0.5: 217 CNPJs ativos; 94 coerentes validados; 63 validados por cadastro/nome; 34 confirmados; 7 com area explicita por nome/alias; 16 perfis sem area; 2 filiais herdadas; 1 fora do escopo.
- Criada a referencia central `docs/METODOLOGIA_CLASSIFICACAO_ATUAL.md`.
- A aba `Definicoes` do dashboard foi substituida por `Documentacao`, com Guia do painel, Conceitos e Classificacao de areas.
- Adicionados 16 icones `i` com tooltip aos filtros das tres telas analiticas: Recorte 2015/2019, MIDES completo e 2015 vs 2019.
- Reescrito `README.md` como porta de entrada e criado `docs/ESTRUTURA_REPOSITORIO.md`.
- Repositorio Git local inicializado; dados pesados, outputs, logs, dependencias e artefatos gerados foram colocados no `.gitignore`.

### Validacoes

- Script v0.5 reexecutado: 217 CNPJs ativos, 94 coerentes validados e 16 perfis sem area.
- `dashboards/base1_shiny/app.R` carregado com sucesso por R.
- Verificacao no navegador local: aba Documentacao e suas tres subabas renderizaram; 16 tooltips encontrados com texto e descricao acessivel.
- Dashboard republicado e respondendo: <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>.

### Commits

- `ff19f0f chore: organizar base inicial do ideiaMides`
- `98c5a0d dashboard: adicionar ajuda contextual aos filtros`

### Pendencias Mantidas

- Decidir se matriz/filial sera consolidada financeiramente e nos movimentos.
- Nao iniciar ainda a frente 3: base anual formal de movimentos municipio x consorcio x ano.

---

## 2026-07-28 - Integracao v0.5 ao MIDES completo

### Decisao e escopo

- A classificacao v0.5 passou a integrar a tela `MIDES completo` exclusivamente como atributo do CNPJ do consorcio.
- A integracao e feita por `left_join`: nenhum pagamento, par municipio-consorcio, ano ou movimento foi removido, agregado ou reclassificado.
- CNPJs sem classificacao ativa continuam no painel sob o rotulo `Sem classificacao ativa`; portanto, o filtro nao reduz silenciosamente o universo historico.

### Entregas

- Incluidos os filtros multiplos `Area de politica publica`, `Macrogrupo` e `Perfil institucional` na tela MIDES completo.
- Incluidas as tres colunas correspondentes na tabela detalhada MIDES.
- Criados `dashboards/base1_shiny/preparar_classificacao_v0_5.R` e `dashboards/base1_shiny/tests/test_classificacao_v0_5.R`.
- O script de deploy passou a usar caminho relativo ao repositorio, sem depender de diretorios locais alternativos.

### Validacoes

- Camada v0.5 preparada com 223 CNPJs tecnicos, 217 ativos e 94 casos coerentes validados.
- Teste automatizado aprovado: preservacao de 15.135 linhas MIDES e 161 CNPJs, filtros por area, macrogrupo, perfil e sem classificacao ativa, mapa e base de movimentos.
- Teste visual local aprovado: os filtros alteram KPIs e mapa; `Limpar MIDES` restaura o universo; o mapa de movimentos permanece renderizavel com os atributos aplicados.

### Publicacao e versionamento

- Dashboard republicado em <https://kl5ug0-adriano-pires.shinyapps.io/base1-mides-munic-siconfi/>.
- Repositorio remoto privado criado em <https://github.com/driano1221/ideiaMides>.
- Regra operacional definida: ao concluir uma sessao relevante, atualizar este diario, criar commit e enviar para `origin`.
