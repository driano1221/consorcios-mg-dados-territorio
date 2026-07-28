# Metodologia - Base 1 2015/2019

**Projeto:** ideiaMides  
**Frente:** Base 1 - recorte temporal 2015/2019  
**Status:** experimento metodologico tangente ao painel principal v2  
**Ultima atualizacao:** 2026-06-10  

---

## 1. Objetivo

A Base 1 foi criada para responder a uma preocupacao metodologica discutida na reuniao de 2026-05-29:

> O painel principal v2 integra fontes com temporalidades diferentes. Por isso, ele e bom como retrato integrado de evidencias, mas nao deve ser tratado automaticamente como painel anual completo.

A Base 1 cria um recorte menor e mais comparavel, usando apenas os anos em que a MUNIC possui informacao util de participacao em consorcios:

- 2015;
- 2019.

O objetivo e separar duas perguntas:

1. **Vinculo:** o municipio aparece vinculado ao consorcio no MIDES e/ou na MUNIC?
2. **Validacao financeira:** o total financeiro observado no MIDES e compativel com o total declarado no SICONFI pelo municipio naquele ano?

---

## 2. Arquivos De Entrada

### 2.1 Cadastro IPEA

Arquivo:

`C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para analise/base_consorcios_v10_2026-04-30.xlsx`

Aba:

`Cadastro`

Dimensao conhecida:

- 1.194 consorcios;
- 25 variaveis.

Papel:

- catalogo mestre de consorcios;
- fornece CNPJ, razao social, sigla, UF, setores, situacao, ano de fundacao e flags documentais;
- define o recorte MG dos 223 consorcios usados no painel principal;
- define tambem o universo amplo de 1.194 CNPJs usado na validacao financeira contra SICONFI.

Uso na Base 1:

- para a base de vinculos, usa-se o recorte **MG = 223 consorcios**;
- para a validacao financeira SICONFI, usa-se o cadastro amplo **1.194 CNPJs**, porque o SICONFI nao informa o CNPJ/UF do consorcio destino.

---

### 2.2 MIDES

Arquivo intermediario usado:

`dados/processado/painel_mg_anual.rds`

Arquivo bruto de origem no projeto:

`dados/bruto/mides_mg_atualizado.rds`

Origem:

- BigQuery/Base dos Dados;
- tabela `world_wb_mides.pagamento`;
- dados de pagamentos municipais;
- filtrado para `sigla_uf == "MG"`;
- filtrado para `documento_credor` dentro dos 1.194 CNPJs do cadastro IPEA.

Estrutura original relevante:

- transacional;
- possui `data`;
- possui `ano`;
- possui `id_municipio`;
- possui `documento_credor`;
- possui indicador de restos a pagar;
- possui valores financeiros.

Estrutura usada na Base 1:

`painel_mg_anual.rds` ja esta agregado em:

> municipio x consorcio x ano

Colunas principais usadas:

| Coluna | Uso |
|---|---|
| `id_municipio` | codigo IBGE do municipio com 7 digitos |
| `documento_credor` | CNPJ do consorcio/credor |
| `ano` | ano do pagamento |
| `valor_corrente` | pagamentos correntes, sem restos |
| `valor_restos` | restos a pagar |
| `valor_total` | corrente + restos |
| `n_transacoes` | numero de transacoes agregadas |
| `tem_pagamento_corrente` | flag de pagamento corrente |
| `nome_credor_freq` | nome de credor mais frequente |

Intervalo disponivel no projeto:

- 2014 a 2021.

Intervalo usado na Base 1:

- 2015 e 2019.

Papel metodologico:

- fonte principal de evidencia financeira em nivel **municipio x consorcio x ano**;
- indica pagamento observado do municipio para um CNPJ de consorcio;
- permite construir valores anuais por par.

---

### 2.3 MUNIC

Arquivo:

`C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para analise/base_consorcios_v10_2026-04-30.xlsx`

Aba:

`MUNIC participacao`

Dimensao conhecida:

- 18.276 linhas;
- 10 variaveis;
- para MG: 1.637 linhas em 2015 e 1.650 linhas em 2019 antes/agregado conforme filtros.

Estrutura relevante:

> municipio x consorcio x ano x setor

Colunas principais usadas:

| Coluna | Uso |
|---|---|
| `cod_ibge` | codigo IBGE municipal com 6 digitos |
| `municipio` | nome do municipio |
| `uf_mun` | UF do municipio |
| `ano` | ano da MUNIC |
| `setor` | area/setor declarado |
| `cnpj_consorcio` | CNPJ do consorcio declarado |
| `sigla` | sigla informada na fonte |
| `confianca` | classificacao herdada da base |

Intervalo util:

- 2015;
- 2019.

Observacao:

> A MUNIC e uma pesquisa de informacoes municipais. Para o tema consorcios, a estrutura util com municipio x CNPJ esta disponivel no pipeline apenas para 2015 e 2019.

Papel metodologico:

- fonte de vinculo declarado;
- entra como evidencia de participacao em consorcio;
- nao traz valor financeiro;
- pode ter mais de uma linha para o mesmo municipio x consorcio x ano quando ha multiplos setores.

Tratamento:

- filtro `uf_mun == "MG"`;
- filtro `ano %in% c(2015, 2019)`;
- filtro de CNPJs dentro dos 223 consorcios MG do cadastro IPEA;
- agregacao para uma linha por:

> municipio x consorcio x ano

As informacoes de setor sao consolidadas em:

- `setores_munic`;
- `n_setores_munic`.

---

### 2.4 SICONFI

Arquivo:

`C:/IPEA/dados servidor IPEA/IPEA arquivos servidor para analise/base_consorcios_v10_2026-04-30.xlsx`

Aba:

`SICONFI painel munic`

Dimensao conhecida:

- 70.944 linhas;
- 9 variaveis;
- cobertura na planilha: 2010 a 2025;
- anos classificados como `ok`: 2013 a 2024;
- 2025 marcado como `ano_incompleto`;
- 2010 a 2012 marcados como `pre_rubrica_71`.

Estrutura relevante:

> municipio x ano

Colunas principais usadas:

| Coluna | Uso |
|---|---|
| `cod_ibge` | codigo IBGE municipal |
| `municipio` | nome do municipio |
| `uf` | UF |
| `ano` | ano |
| `paga_consorcio` | flag se houve pagamento/transferencia para consorcio |
| `valor_cons_real` | valor real associado a consorcios |
| `valor_sflu_real` | valor real SFLU |
| `valor_total_real` | valor real total |
| `nota_cobertura` | qualidade/cobertura do ano |

Intervalo usado na Base 1:

- 2015;
- 2019;
- ambos com `nota_cobertura == "ok"`.

Ponto metodologico central:

> O SICONFI nao identifica o CNPJ do consorcio destino. Ele informa que o municipio declarou valor/transferencia associado a consorcios no ano, mas nao diz qual consorcio recebeu.

Consequencia:

- SICONFI nao cria par municipio x consorcio;
- SICONFI nao confirma diretamente um vinculo especifico;
- SICONFI e usado como validacao financeira agregada no nivel:

> municipio x ano

---

### 2.5 CNM

CNM nao entra na Base 1.

Motivo:

- CNM e retrato atual;
- nao permite reconstruir com seguranca o vinculo em 2015 ou 2019;
- incluir CNM misturaria temporalidades e prejudicaria o objetivo da Base 1.

---

## 3. Base De Vinculos 2015/2019

Script:

`analises/base_1_2015_2019/scripts/01_base_vinculos_2015_2019.R`

Output principal:

`analises/base_1_2015_2019/outputs/base_1_vinculos_2015_2019.csv`

Unidade:

> municipio x consorcio x ano

Dimensao atual:

- 4.046 linhas;
- 23 colunas.

Chave:

```text
ano + cod_ibge_6 + cnpj_consorcio
```

Fontes usadas:

- MIDES;
- MUNIC;
- Cadastro IPEA.

Fonte excluida:

- CNM.

SICONFI:

- nao entra nesta base de vinculos;
- entra apenas na validacao financeira posterior.

---

## 4. Como MIDES E MUNIC Foram Relacionados

### 4.1 Padronizacao De Chaves

Municipio:

- MIDES possui `id_municipio`, normalmente com 7 digitos;
- MUNIC possui `cod_ibge`, com 6 digitos;
- foi criada a chave `cod_ibge_6` usando os 6 primeiros digitos do MIDES.

CNPJ:

- CNPJs foram tratados como texto;
- padronizados para 14 digitos;
- sem pontuacao.

Ano:

- somente 2015 e 2019.

### 4.2 MIDES

No MIDES, para cada:

> municipio x consorcio x ano

foram somados:

- `valor_mides_corrente`;
- `valor_mides_restos`;
- `valor_mides_total`;
- `n_transacoes_mides`.

Tambem foi preservado:

- `tem_pagamento_corrente`;
- `nome_credor_freq`.

### 4.3 MUNIC

Na MUNIC, como um mesmo par pode aparecer em mais de um setor, as linhas foram agregadas para:

> municipio x consorcio x ano

Foram criadas:

- `tem_munic = TRUE`;
- `setores_munic`;
- `n_setores_munic`.

### 4.4 Uniao Das Fontes

A base final de vinculos e a uniao:

```text
MIDES 2015/2019
UNION
MUNIC 2015/2019
```

restrita aos 223 consorcios MG do cadastro IPEA.

Cada linha recebeu `grupo_vinculo`:

| Grupo | Definicao |
|---|---|
| `MIDES+MUNIC` | aparece no MIDES e na MUNIC no mesmo ano |
| `MIDES_only` | aparece no MIDES, mas nao na MUNIC naquele ano |
| `MUNIC_only` | aparece na MUNIC, mas nao no MIDES naquele ano |

---

## 5. Resultado Da Base De Vinculos

| Ano | Grupo | Linhas |
|---:|---|---:|
| 2015 | MIDES+MUNIC | 818 |
| 2015 | MIDES_only | 908 |
| 2015 | MUNIC_only | 166 |
| 2019 | MIDES+MUNIC | 993 |
| 2019 | MIDES_only | 1.065 |
| 2019 | MUNIC_only | 96 |

Total:

- 4.046 linhas;
- 851 municipios;
- 159 consorcios.

---

## 6. EDA E Checks Da Base De Vinculos

Arquivos:

- `checks/EDA_base_1_vinculos_2015_2019.md`;
- `checks/base_1_eda_vinculos_2015_2019.xlsx`.

Resultado:

- sem duplicatas na chave `ano + cod_ibge_6 + cnpj_consorcio`;
- sem codigos IBGE invalidos;
- sem CNPJs invalidos;
- sem valores negativos;
- todos os registros possuem `razao_social`;
- alguns registros sem `sigla`, por incompletude do cadastro;
- 2 registros MIDES em 2019 possuem transacoes e `tem_pagamento_corrente = TRUE`, mas valor total zero;
- 79 registros MIDES possuem valor positivo ate R$ 1.000.

Interpretacao dos pontos de atencao:

- os 2 valores zero devem ser tratados como anomalia residual na validacao financeira;
- os valores ate R$ 1.000 devem ser mantidos, mas podem representar taxas, registros residuais ou pagamentos muito baixos.

---

## 7. Validacao Financeira SICONFI

Script:

`analises/base_1_2015_2019/scripts/03_validacao_siconfi_2015_2019.R`

Outputs:

- `outputs/base_1_validacao_siconfi_2015_2019.csv`;
- `outputs/base_1_validacao_siconfi_2015_2019.xlsx`;
- `outputs/base_1_resumo_executivo.csv`;
- `checks/VALIDACAO_SICONFI_base_1_2015_2019.md`;
- `checks/base_1_checks_validacao_siconfi_2015_2019.xlsx`.

Unidade:

> municipio x ano

Por que a unidade muda?

Porque o SICONFI nao informa CNPJ do consorcio destino. Portanto, nao e possivel comparar SICONFI diretamente com um par municipio x consorcio.

---

## 8. Como A Comparacao Financeira Foi Feita

### 8.1 Lado MIDES

Para validacao financeira, foram usados os pagamentos MIDES dos municipios MG para os **1.194 CNPJs do cadastro IPEA**, e nao apenas os 223 consorcios MG.

Motivo:

> O SICONFI informa apenas o total municipal declarado para consorcios. Como ele nao informa o CNPJ/UF do consorcio destino, comparar apenas com os 223 consorcios MG poderia subestimar artificialmente o MIDES.

Variavel principal:

`valor_mides_corrente_cadastro_1194`

Variaveis de contexto:

- `valor_mides_restos_cadastro_1194`;
- `valor_mides_total_cadastro_1194`;
- `valor_mides_corrente_base1_223`;
- `valor_mides_total_base1_223`.

### 8.2 Lado SICONFI

Variavel principal:

`valor_siconfi_consorcio`

Origem:

`valor_cons_real`

Filtro:

- `uf == "MG"`;
- `ano %in% c(2015, 2019)`;
- `nota_cobertura == "ok"`.

### 8.2.1 Auditoria Da Definicao SICONFI

Foi criada uma auditoria separada para verificar se o `valor_cons_real` da aba `SICONFI painel munic` e reproduzivel a partir do arquivo bruto local do SICONFI.

Script:

`analises/base_1_2015_2019/scripts/04_auditoria_siconfi_origem.R`

Relatorio:

`analises/base_1_2015_2019/checks/AUDITORIA_SICONFI_ORIGEM_2015_2019.md`

Foram comparadas tres definicoes:

| Definicao | Regra |
|---|---|
| Atual | `valor_cons_real` da aba `SICONFI painel munic` |
| Restrita/rateio | `Despesas Empenhadas` + rubricas com `consorcio` e `contrato de rateio` |
| Ampla/consorcio | `Despesas Empenhadas` + qualquer rubrica com `consorcio` |

Resultado agregado:

| Ano | Atual | Restrita/rateio | Ampla/consorcio |
|---:|---:|---:|---:|
| 2015 | R$ 284,68 mi | R$ 129,81 mi | R$ 319,15 mi |
| 2019 | R$ 242,63 mi | R$ 156,70 mi | R$ 340,35 mi |

Conclusao:

> A aba atual esta mecanicamente consistente como painel municipal anual, mas nao foi reproduzida exatamente pelas duas reconstrucoes simples feitas a partir do bruto local. Ela provavelmente deriva de uma regra intermediaria ou de uma etapa BigQuery/documentada que nao esta integralmente preservada como script local.

Implicacao:

> A comparacao MIDES x SICONFI deve ser apresentada como auditoria financeira exploratoria ate que a definicao oficial de `valor_cons_real` seja recuperada ou escolhida explicitamente.

### 8.2.2 Reconstrucao Via Base Dos Dados

Para validar a duvida, foi criada uma reconstrucao direta do SICONFI em R.

Script:

`analises/base_1_2015_2019/scripts/05_reconstruir_siconfi_base_dos_dados.R`

Relatorio:

`analises/base_1_2015_2019/checks/RECONSTRUCAO_SICONFI_BASE_DOS_DADOS_2015_2019.md`

Fonte:

- Base dos Dados / BigQuery;
- tabela `br_me_siconfi.municipio_despesas_orcamentarias`;
- billing `ipea-consorcios`;
- filtro `sigla_uf == "MG"`;
- anos 2015 e 2019;
- valores deflacionados para jan/2018.

O script testou diferentes regras contabeis:

| Variante | Regra |
|---|---|
| `consorcio_pagas` | qualquer rubrica com `consorcio`; somente despesas pagas |
| `consorcio_liquidadas` | qualquer rubrica com `consorcio`; somente despesas liquidadas |
| `consorcio_empenhadas` | qualquer rubrica com `consorcio`; somente despesas empenhadas |
| `rateio_pagas` | rubricas com `consorcio` e `contrato de rateio`; somente despesas pagas |
| `rateio_empenhadas` | rubricas com `consorcio` e `contrato de rateio`; somente despesas empenhadas |

Resultado agregado em 2015/2019:

| Variante | Total reconstruido | Diferenca contra aba atual |
|---|---:|---:|
| `consorcio_pagas` | R$ 580,32 mi | +R$ 53,02 mi |
| `consorcio_liquidadas` | R$ 614,23 mi | +R$ 86,92 mi |
| `consorcio_empenhadas` | R$ 659,67 mi | +R$ 132,36 mi |
| `rateio_pagas` | R$ 261,18 mi | -R$ 266,12 mi |
| `rateio_empenhadas` | R$ 286,68 mi | -R$ 240,63 mi |

Conclusao da reconstrucao:

> A melhor aproximacao reproduzivel foi `consorcio_pagas`, mas ela ainda nao reproduz exatamente a aba herdada `SICONFI painel munic`. Portanto, ha duas opcoes metodologicas: recuperar o script/SQL original da aba herdada ou substituir a validacao por uma regra nova, explicita e reprocessavel.

Recomendacao tecnica:

> Para a Base 1, usar uma regra SICONFI explicitamente escolhida e reprocessada em R. Se a prioridade for leitura financeira conservadora de desembolso efetivo, a candidata mais defensavel e `consorcio_pagas`. Se a prioridade for compromisso orcamentario, usar `consorcio_empenhadas`.

### 8.2.3 Regra SICONFI Recomendada Para A Base 1

Regra recomendada:

> `consorcio_pagas`: qualquer rubrica cujo nome contenha `consorcio`, mantendo apenas o estagio `Despesas Pagas`.

Justificativa:

- A pergunta da Base 1 e de validacao financeira, nao de execucao orcamentaria completa.
- O lado MIDES usado na comparacao e `valor_mides_corrente`, isto e, pagamento observado ao CNPJ do consorcio.
- Portanto, no SICONFI, a regra mais comparavel e a de valor pago, nao empenhado ou liquidado.
- O filtro por qualquer rubrica com `consorcio` e preferivel a restringir somente a `contrato de rateio`, porque o Manual Tecnico do Orcamento tambem reconhece outras modalidades associadas a consorcios publicos, como execucao orcamentaria delegada e modalidades especificas de saude.
- A regra `consorcio_pagas` foi a melhor aproximacao empirica da aba herdada entre as variantes testadas.

Comparacao das regras:

| Regra | O que mede | Vantagem | Limite | Uso recomendado |
|---|---|---|---|---|
| `consorcio_pagas` | Desembolso registrado como pago em rubricas de consorcio | Mais comparavel ao MIDES como pagamento observado | Pode deixar fora empenhos/liquidacoes ainda nao pagas | Regra principal da Base 1 |
| `consorcio_liquidadas` | Despesa liquidada em rubricas de consorcio | Aproxima servico/obrigacao reconhecida | Pode nao ter virado pagamento no ano | Analise de sensibilidade |
| `consorcio_empenhadas` | Compromisso orcamentario em rubricas de consorcio | Capta intencao/compromisso anual mais amplo | Superestima em relacao a pagamento efetivo | Sensibilidade orcamentaria |
| `rateio_pagas` | Pagamentos apenas em contrato de rateio | Definicao mais conservadora | Subestima consorcios com outras modalidades legitimas | Piso conservador |
| `rateio_empenhadas` | Empenhos apenas em contrato de rateio | Capta compromisso formal de rateio | Mistura compromisso e filtro estreito | Nao usar como regra principal |
| `original_gabriel_empenhadas` | Consorcio, multigovernamentais e SFLU em empenhadas | Reproduz criterio amplo do script historico | Inclui categorias que nao sao necessariamente consorcios | Apenas para rastrear historico |

Decisao metodologica:

> A validacao principal MIDES x SICONFI deve ser reprocessada com `consorcio_pagas`. A aba herdada `valor_cons_real` deve permanecer documentada como referencia historica, mas nao como regra oficial da Base 1.

### 8.3 Regra De Diferenca

Foi calculado:

```text
diferenca_abs = valor_siconfi_consorcio - valor_mides_corrente_cadastro_1194
diferenca_abs_modulo = abs(diferenca_abs)
diferenca_rel = diferenca_abs_modulo / max(valor_siconfi_consorcio, valor_mides_corrente_cadastro_1194)
```

Um caso e classificado como congruente quando:

```text
diferenca_abs_modulo <= 10.000
OU
diferenca_rel <= 10%
```

---

## 9. Classes De Validacao

| Classe | Definicao |
|---|---|
| `congruente` | MIDES e SICONFI positivos e dentro da tolerancia |
| `divergente_valor` | MIDES e SICONFI positivos, mas fora da tolerancia |
| `mides_sem_siconfi` | MIDES positivo e SICONFI zero/ausente |
| `siconfi_sem_mides` | SICONFI positivo e MIDES zero nos 1.194 CNPJs do cadastro |
| `munic_sem_fluxo_financeiro` | MUNIC declarou vinculo, mas MIDES e SICONFI nao mostram fluxo financeiro no municipio-ano |

---

## 10. Resultado Da Validacao SICONFI

### 10.1 Resultado Com Aba Herdada

| Ano | Municipio-ano | Congruente | Divergente valor | MIDES sem SICONFI | SICONFI sem MIDES | MUNIC sem fluxo | Congruencia entre ambos positivos |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 2015 | 838 | 85 | 505 | 217 | 25 | 6 | 14,4% |
| 2019 | 849 | 88 | 546 | 206 | 5 | 4 | 13,9% |

Valores totais:

| Ano | MIDES corrente - 1.194 CNPJs | MIDES corrente - 223 MG | SICONFI consorcios |
|---:|---:|---:|---:|
| 2015 | 324.112.853 | 324.002.107 | 284.677.033 |
| 2019 | 434.524.760 | 434.276.490 | 242.627.012 |

### 10.2 Resultado Oficial Com SICONFI Reconstruido

Script:

`analises/base_1_2015_2019/scripts/06_validacao_siconfi_reconstruido_2015_2019.R`

Regra SICONFI:

> `consorcio_pagas`: qualquer rubrica com `consorcio` + `Despesas Pagas`.

| Ano | Municipio-ano | Congruente | Divergente valor | MIDES sem SICONFI | SICONFI sem MIDES | MUNIC sem fluxo | Congruencia entre ambos positivos |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 2015 | 835 | 142 | 517 | 148 | 17 | 11 | 21,5% |
| 2019 | 847 | 373 | 411 | 56 | 4 | 3 | 47,6% |

Valores totais:

| Ano | MIDES corrente - 1.194 CNPJs | MIDES corrente - 223 MG | SICONFI reconstruido |
|---:|---:|---:|---:|
| 2015 | 324.112.853 | 324.002.107 | 275.118.819 |
| 2019 | 434.524.760 | 434.276.490 | 305.205.132 |

Leitura:

> A regra reconstruida melhora a comparabilidade com o MIDES porque usa despesas pagas, mas a validacao continua agregada por municipio-ano. Ela nao confirma CNPJ destino.

### 10.3 Sensibilidade Da Tolerancia Relativa

Script:

`analises/base_1_2015_2019/scripts/07_validacao_siconfi_reconstruido_sensibilidade.R`

Regra fixa:

- SICONFI: `consorcio_pagas`;
- tolerancia absoluta: R$ 10.000;
- tolerancia relativa testada: 5% e 10%.

| Tolerancia | Ano | Municipio-ano | Congruente | Divergente valor | MIDES sem SICONFI | SICONFI sem MIDES | Taxa entre ambos positivos |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 5% | 2015 | 835 | 122 | 537 | 148 | 17 | 18,5% |
| 5% | 2019 | 847 | 325 | 459 | 56 | 4 | 41,5% |
| 10% | 2015 | 835 | 142 | 517 | 148 | 17 | 21,5% |
| 10% | 2019 | 847 | 373 | 411 | 56 | 4 | 47,6% |

Leitura:

> A conclusao qualitativa nao muda entre 5% e 10%: 2019 e substancialmente mais congruente que 2015, e ainda ha volume relevante de divergencias. A tolerancia de 10% e mais adequada para apresentacao executiva; a de 5% funciona como teste conservador.

---

## 11. Interpretacao

A congruencia financeira direta ainda nao e plena, mesmo com tolerancia de R$ 10.000 ou 10%. Com a regra reconstruida, a leitura melhora em relacao a aba herdada, especialmente em 2019.

Isso nao invalida a Base 1. A leitura correta e:

> SICONFI e util como diagnostico financeiro agregado por municipio x ano, mas nao como confirmacao automatica de vinculo municipio x consorcio.

Possiveis razoes para divergencia:

- SICONFI e contabil/fiscal e agregado por municipio/ano;
- a definicao exata de `valor_cons_real` ainda esta em auditoria;
- MIDES e transacional e identifica CNPJ do credor;
- SICONFI nao informa CNPJ destino;
- classificacoes contabeis podem nao bater perfeitamente;
- alguns pagamentos podem ser registrados como restos no MIDES;
- alguns consorcios podem nao estar cobertos na mesma forma pelas duas fontes;
- diferencas de criterio entre valor pago, liquidado, transferido e registrado contabilmente.

---

## 12. Como Usar Esta Base

Uso recomendado:

- analisar convergencia e divergencia entre MIDES e MUNIC em 2015/2019;
- identificar pares `MIDES+MUNIC`, `MIDES_only` e `MUNIC_only`;
- usar SICONFI para diagnosticar consistencia financeira agregada por municipio/ano;
- produzir slides de virada metodologica.

Uso nao recomendado:

- usar SICONFI para criar pares municipio x consorcio;
- interpretar congruencia financeira como prova definitiva de vinculo;
- misturar CNM nesta base temporal;
- tratar a Base 1 como substituta do painel principal v2.

---

## 13. Proximos Passos

1. Produzir resumo visual para apresentacao.
2. Escolher 3 a 5 exemplos concretos por classe de validacao.
3. Revisar os maiores casos `divergente_valor`.
4. Revisar casos `siconfi_sem_mides`, pois podem indicar pagamento a consorcios fora do universo capturado ou classificacao distinta.
5. Decidir se a tolerancia de R$ 10.000 ou 10% sera mantida como regra oficial do experimento.
