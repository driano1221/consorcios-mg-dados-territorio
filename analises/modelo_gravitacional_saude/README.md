# Modelo Gravitacional De Saude

Este diretorio prepara o recorte de Minas Gerais definido na reuniao de
27/08/2026. O primeiro produto fecha o universo de consorcios com evidencia
explicita nas areas `saude`, `urgencia_emergencia` ou
`vigilancia_em_saude` da classificacao v0.5.

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

## Limite

Este passo identifica e organiza o universo. A entrada definitiva de cada
entidade no conjunto de risco do modelo depende do confronto documental,
MUNIC 2019, definicao do polo assistencial e integracao do CNES.
