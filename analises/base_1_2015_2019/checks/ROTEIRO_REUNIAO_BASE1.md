# Roteiro de reuniao - Base 1 2015/2019

## Mensagem central

> A Base 1 separa vinculo e validacao financeira. MIDES e MUNIC formam os pares municipio-consorcio nos anos comparaveis de 2015 e 2019. O SICONFI entra depois, apenas como validacao financeira agregada por municipio-ano, reprocessado com regra auditavel.

## Fala de 1 minuto

1. O painel principal integra evidencias de fontes com temporalidades diferentes; por isso criamos a Base 1 como recorte controlado.
2. A Base 1 usa 2015 e 2019 porque sao os anos em que a MUNIC tem estrutura operacional para vinculo municipio-CNPJ de consorcio.
3. MIDES entra como pagamento observado ao CNPJ do consorcio; MUNIC entra como declaracao de participacao; ambos formam a base de vinculos.
4. SICONFI nao identifica CNPJ destino. Por isso, ele nao cria vinculo; ele valida coerencia financeira no municipio-ano.
5. Reprocessamos o SICONFI via R/BigQuery com a regra `consorcio_pagas`, que e a mais comparavel ao MIDES porque mede despesas pagas em rubricas de consorcio.

## Resultado para mostrar

| Tolerancia | Ano | Congruente | Divergente | Taxa |
|---:|---:|---:|---:|---:|
| 5% | 2015 | 122 | 537 | 18,5% |
| 5% | 2019 | 325 | 459 | 41,5% |
| 10% | 2015 | 142 | 517 | 21,5% |
| 10% | 2019 | 373 | 411 | 47,6% |

## Slide-chave

Use o slide **"02 - Fontes"** como tela principal para explicar a metodologia:

- origem/processo de cada base;
- head conceitual de MIDES, MUNIC e SICONFI;
- como cada base foi usada;
- chave da uniao MIDES/MUNIC;
- onde o SICONFI entra.

## Leitura

- A regra de 10% e boa para apresentacao executiva.
- A regra de 5% funciona como teste conservador.
- A conclusao qualitativa nao muda: 2019 e mais congruente que 2015, mas ainda ha muitas divergencias.
- Essas divergencias viram agenda de auditoria, nao erro automatico.

## Pontos de validacao metodologica

1. Confirmar se a regra `consorcio_pagas` deve ser a regra oficial do SICONFI na Base 1.
2. Confirmar se 10% sera a tolerancia principal e 5% a sensibilidade conservadora.
3. Confirmar se a interpretacao de SICONFI como validacao agregada, e nao como vinculo especifico, esta adequada.

## Materiais

- `checks/base_1_materiais_reuniao.xlsx`
- `slides/2026-06-11_base1_reuniao_curta.html`
