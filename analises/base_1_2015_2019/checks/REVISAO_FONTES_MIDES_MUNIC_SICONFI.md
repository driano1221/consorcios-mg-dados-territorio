# Revisao das fontes - MIDES, MUNIC e SICONFI

**Data:** 2026-06-11  
**Escopo:** Base 1 2015/2019  

---

## Conclusao Executiva

A logica geral da Base 1 esta correta:

- **MIDES** deve ser usado como evidencia financeira direta em `municipio x consorcio x ano`, pois identifica o CNPJ do credor.
- **MUNIC** deve ser usada como evidencia declaratoria de participacao em `municipio x consorcio x ano`, sem valor financeiro.
- **SICONFI** deve ser usado apenas como validacao financeira agregada em `municipio x ano`, pois nao identifica o CNPJ do consorcio destino.

A principal revisao metodologica e no SICONFI: a regra oficial da Base 1 deve ser reprocessavel. A recomendacao e usar `consorcio_pagas`.

---

## MIDES

Fonte documentada:

- Base dos Dados: `world_wb_mides.pagamento`.
- Projeto MiDES: microdados de despesas de entes subnacionais, com dados harmonizados de execucao orcamentaria e pagamentos locais.
- Documentacao externa consultada: Base dos Dados e pagina do projeto MiDES/World Bank.

Uso no projeto:

- Script de download: `scripts/01_baixar_mides_mg.R`.
- Script de agregacao: `scripts/02_painel_participacao.R`.
- Base usada na Base 1: `dados/processado/painel_mg_anual.rds`.

Regra local:

- Filtra `sigla_uf == "MG"`.
- Filtra `documento_credor` dentro dos 1.194 CNPJs do cadastro IPEA.
- Mantem pagamentos correntes e restos a pagar.
- Agrega em `id_municipio x documento_credor x ano`.

Leitura:

- Correto para criar pares `municipio x consorcio x ano`.
- Correto usar `valor_corrente` como principal na comparacao com SICONFI quando a pergunta e desembolso corrente.
- `valor_restos` deve ficar como contexto, nao como definidor principal de entrada/validacao.

Ponto de atencao:

- O MIDES e transacional e identifica CNPJ, mas depende da cobertura dos TCEs/entes disponiveis na base.
- A serie local do projeto para MG vai ate 2021; logo, nao deve ser lida como idade real do vinculo.

---

## MUNIC

Fonte documentada:

- IBGE, Pesquisa de Informacoes Basicas Municipais - MUNIC.
- A MUNIC e levantamento municipal sobre estrutura, dinamica e funcionamento das instituicoes publicas municipais.
- Unidade de investigacao: municipio; informante principal: prefeitura.

Uso no projeto:

- Base herdada: `base_consorcios_v10_2026-04-30.xlsx`.
- Aba: `MUNIC participacao`.
- Script da Base 1: `analises/base_1_2015_2019/scripts/01_base_vinculos_2015_2019.R`.

Regra local:

- Filtra `uf_mun == "MG"`.
- Filtra anos 2015 e 2019.
- Padroniza `cod_ibge` para 6 digitos.
- Padroniza `cnpj_consorcio` para 14 digitos.
- Restringe aos 223 consorcios MG do cadastro IPEA.
- Agrega multiplos setores em uma linha por `ano x cod_ibge_6 x cnpj_consorcio`.

Leitura:

- Correto usar MUNIC como vinculo declarado.
- Correto nao usar MUNIC como fonte financeira.
- Correto usar apenas 2015 e 2019 na Base 1, porque sao os anos em que o pipeline tem estrutura operacional util de `municipio x CNPJ de consorcio`.

Ponto de atencao:

- A MUNIC depende de declaracao municipal; pode haver omissao, erro de CNPJ, diferenca de nomenclatura e multiplos setores para o mesmo par.
- A base de 2019 teve erratas em temas da MUNIC no portal do IBGE; para este uso, manter a versao herdada documentada e rastreavel.

---

## SICONFI

Fonte documentada:

- SICONFI/STN via Base dos Dados: `br_me_siconfi.municipio_despesas_orcamentarias`.
- O SICONFI e sistema contabil/fiscal; sua informacao e municipal agregada, nao identifica o CNPJ destino.
- O Manual Tecnico do Orcamento reconhece modalidades associadas a consorcios, incluindo:
  - 71: transferencias a consorcios publicos mediante contrato de rateio;
  - 72: execucao orcamentaria delegada a consorcios publicos;
  - 73/74: modalidades especificas de rateio ligadas a recursos de saude.

Uso anterior:

- Aba herdada: `SICONFI painel munic`.
- Variavel usada: `valor_cons_real`.
- Unidade: `municipio x ano`.

Auditoria feita:

- `scripts/04_auditoria_siconfi_origem.R`.
- `scripts/05_reconstruir_siconfi_base_dos_dados.R`.

Resultado:

- A aba herdada e mecanicamente consistente, mas sua regra exata nao foi reproduzida.
- A melhor regra reprocessavel testada foi `consorcio_pagas`.

Regra recomendada:

> `consorcio_pagas` = qualquer rubrica com `consorcio`, mantendo apenas `Despesas Pagas`.

Justificativa:

- O lado MIDES da comparacao e pagamento observado.
- Despesas pagas sao mais comparaveis a desembolso efetivo do que empenhadas/liquidadas.
- Restringir somente a contrato de rateio subestima o fenomeno, pois ha outras modalidades oficiais de consorcios.

---

## Decisao Recomendada

Para a validacao oficial da Base 1:

1. manter a base de vinculos MIDES/MUNIC como esta;
2. reprocessar a validacao financeira usando `consorcio_pagas`;
3. manter a aba herdada `valor_cons_real` apenas como referencia historica/auditoria;
4. reportar resultados de sensibilidade com `consorcio_empenhadas` e `rateio_pagas`.

---

## Fontes Consultadas

- Base dos Dados - MiDES: https://basedosdados.org/dataset/d3874769-bcbd-4ece-a38a-157ba1021514
- Projeto MiDES/World Bank: https://municipal-budget-execution.github.io/mides/
- IBGE - MUNIC: https://www.ibge.gov.br/estatisticas/sociais/saude/10586-pesquisa-de-informacoes-basicas-municipais.html
- Base dos Dados - MUNIC: https://basedosdados.org/dataset/218ae306-29ac-4a83-836d-95bfdb9683fe
- Base dos Dados - SICONFI: https://basedosdados.org/dataset/5a3dec52-8740-460e-b31d-0e0347979da0
- Tesouro Transparente - SICONFI: https://www.tesourotransparente.gov.br/temas/contabilidade-e-custos/relatorios-contabeis-e-fiscais-de-estados-df-e-municipios
- Manual Tecnico do Orcamento - modalidades de aplicacao: https://www1.siop.planejamento.gov.br/mto/doku.php/mto%3Acap4
