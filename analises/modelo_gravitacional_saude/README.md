# Modelo Gravitacional De Saude

Este diretorio prepara o recorte de Minas Gerais definido na reuniao de
27/08/2026. O primeiro produto fecha o universo de consorcios com evidencia
explicita nas areas `saude`, `urgencia_emergencia` ou
`vigilancia_em_saude` da classificacao v0.5.

Resumo breve das fontes, do pipeline e dos resultados dos dois primeiros
passos: [`METODOLOGIA_PASSOS_1_2.md`](METODOLOGIA_PASSOS_1_2.md).

## Camadas Do Universo

| Camada | Definicao |
|---|---|
| Cadastral ampla | Toda raiz de CNPJ com classificacao explicita de saude. |
| MIDES observada | Entidade com pagamento positivo de municipio mineiro entre 2014 e 2021. |
| Nucleo setorial preliminar | Entidade observada cuja classificacao contem somente areas de saude. |
| Sensibilidade multiarea | Entidade observada com saude e outras areas explicitas. |

A situacao atual da matriz e preservada, mas nao e tratada como situacao
historica. Um CNPJ hoje inapto pode ter recebido pagamentos durante a janela do
MIDES.

## Execucao

Na raiz do repositorio:

```powershell
Rscript analises/modelo_gravitacional_saude/01_fechar_universo_saude_mg.R
Rscript analises/modelo_gravitacional_saude/tests/01_validar_universo_saude_mg.R
```

Os CSVs e RDS sao gravados em `outputs/`, mantido fora do Git. O relatorio
auditavel fica em `checks/VALIDACAO_UNIVERSO_SAUDE_MG.md`.

## Cotejamento MIDES X MUNIC Em 2019

O segundo passo compara a uniao dos pares observados nas duas fontes depois da
consolidacao matriz-filial:

```powershell
Rscript analises/modelo_gravitacional_saude/02_cotejar_mides_munic_saude_2019.R
Rscript analises/modelo_gravitacional_saude/tests/02_validar_cotejamento_mides_munic_saude_2019.R
```

A documentacao existente no cadastro contextualiza a revisao, mas nao e
interpretada como prova de composicao municipal especificamente em 2019 quando
o documento nao possui referencia temporal explicita. Os resultados locais
incluem tabela detalhada, resumo por entidade, divergencias e uma amostra de 50
pares prioritarios. O relatorio auditavel fica em
`checks/VALIDACAO_COTEJAMENTO_MIDES_MUNIC_SAUDE_2019.md`.

### Revisao Documental Das Divergencias

A amostra prioritaria do passo 2 foi qualificada com fontes institucionais e
documentos publicos. A revisao distingue evidencia temporal ate 2019,
corroboracao apenas posterior, relacao financeira sem filiacao comprovada e
casos ainda dependentes de revisao humana.

```powershell
Rscript analises/modelo_gravitacional_saude/03_revisar_divergencias_documentais_2019.R
Rscript analises/modelo_gravitacional_saude/tests/03_validar_revisao_documental_2019.R
```

O catalogo de fontes fica em
`evidencias/catalogo_revisao_documental_2019.csv`; o relatorio auditavel fica
em `checks/VALIDACAO_DOCUMENTAL_DIVERGENCIAS_2019.md`.

## Limite

Este passo identifica e organiza o universo. A entrada definitiva de cada
entidade no conjunto de risco do modelo depende do confronto documental,
MUNIC 2019, definicao do polo assistencial e integracao do CNES.
