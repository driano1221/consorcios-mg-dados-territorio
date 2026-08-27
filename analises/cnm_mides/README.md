# CNM x Cadastro IPEA x MIDES

Esta frente versiona fotografias cadastrais da CNM, constrói a identidade institucional com o Cadastro IPEA e coteja a composição CNM atual com pagamentos anuais observados no MIDES.

## Regra temporal

A CNM é uma fotografia na data da raspagem. `data_constituicao` informa a criação do consórcio; não informa a composição municipal em cada ano. A lista atual de municípios nunca é retroagida como filiação histórica.

## Pipeline

1. `01_comparar_snapshots_cnm.py`: compara maio e agosto e executa auditorias.
2. `02_construir_crosswalk_cnm_ipea.R`: identifica CNPJs exatos, raízes e sugestões nominais.
3. `03_cotejar_cnm_mides_mg.R`: cria o piloto MG por município, consórcio e ano.
4. `04_normalizar_exportacoes.py`: normaliza Unicode nas saídas produzidas pelo R no Windows.

Somente pareamentos por CNPJ exato ou raiz entram automaticamente no cotejamento. Sugestões por nome exigem revisão humana.

## Execução

```powershell
$env:CNM_WORKDIR = "C:\IPEA\dados cnm\snapshots\2026-08-27"
Set-Location analises/cnm_mides/scraper
npm ci
npm run scrape
npm run build:unified
npm run build:areas
npm run eda
Set-Location ../../..

python analises/cnm_mides/scripts/01_comparar_snapshots_cnm.py
$env:CNM_ANALYSIS_EXPORT_ROOT = "C:\IPEA\dados cnm\exports\cnm_mides_2026-08-27"
Rscript analises/cnm_mides/scripts/02_construir_crosswalk_cnm_ipea.R
Rscript analises/cnm_mides/scripts/03_cotejar_cnm_mides_mg.R
python analises/cnm_mides/scripts/04_normalizar_exportacoes.py
python analises/cnm_mides/tests/testar_produtos.py
```

O diretório auxiliar sem acentos evita uma limitação de locale do R 4.3.1 no Windows. Os produtos finais são copiados para `outputs/` e `checks/`.

## Produtos principais

- `crosswalk_cnm_ipea_cnpj`: identidade institucional CNM x cadastro IPEA.
- `cnm_mides_mg_municipio_consorcio_ano`: tabela analítica do piloto.
- `cnm_mides_mg_pares_periodo`: síntese por par no período 2014-2021.
- `cnm_mides_mg_resumo_consorcio`: síntese por identidade canônica de consórcio.
- `cnm_mides_mg_linha_tempo`: contagens anuais por situação das fontes.
- `checks/figures`: mapa de predominância e linha do tempo.

Leia [RELATORIO_ENTREGA_1_3.md](RELATORIO_ENTREGA_1_3.md) antes de interpretar os resultados.
