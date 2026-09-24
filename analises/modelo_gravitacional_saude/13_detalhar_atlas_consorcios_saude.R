# Cruza a revisao de fronteira com MIDES e gera atlas local por entidade/ano.
# Execute com --consultar-mides para obter as 15 raizes CNM fora do cadastro.
# Reexecucoes sem essa opcao usam o cache; nenhum produto 01-11 e sobrescrito.
invisible(Sys.setlocale('LC_ALL','Portuguese_Brazil.utf8'))
suppressPackageStartupMessages({
  library(dplyr); library(sf); library(leaflet); library(htmlwidgets)
  library(htmltools); library(jsonlite); library(stringi)
})
root <- utils::shortPathName(normalizePath(getwd(), winslash="\\"))
here <- file.path(root, 'analises/modelo_gravitacional_saude')
out <- file.path(here, 'outputs')
read_chars <- function(name) as.data.frame(readr::read_csv(file.path(out,name),
  col_types=readr::cols(.default='c'),show_col_types=FALSE,name_repair='minimal'))
decode <- function(x) vapply(x, function(s) {
  if(is.na(s)) return('')
  hits <- gregexpr('<U\\+[0-9A-Fa-f]{4,6}>',s,perl=TRUE)
  tokens <- regmatches(s,hits)[[1]]
  if(length(tokens)) regmatches(s,hits) <- list(vapply(tokens,function(z) intToUtf8(strtoi(sub('>','',sub('<U\\+','',z)),16)),''))
  s
},'')
front <- read_chars('fronteira_universo_cadastro.csv')
cache <- file.path(out,'fronteira_mides_complementar.csv')
new_roots <- sort(front$cnpj_raiz_8[front$origem=='somente_cnm_mg'])
if('--consultar-mides' %in% commandArgs(TRUE)) {
  bigrquery::bq_auth(email=TRUE)
  stopifnot(all(grepl('^[0-9]{8}$',new_roots)),length(new_roots)==15)
  sql <- paste0("SELECT ano,id_municipio,documento_credor, SUM(valor_final) AS valor_total, COUNT(*) AS n_transacoes ",
    "FROM `basedosdados.world_wb_mides.pagamento` WHERE sigla_uf='MG' AND ano BETWEEN 2014 AND 2021 ",
    "AND SUBSTR(documento_credor,1,8) IN ('",paste(new_roots,collapse="','"),"') ",
    "AND LENGTH(documento_credor)=14 GROUP BY ano,id_municipio,documento_credor")
  writeLines(sql,file.path(out,'fronteira_consulta_mides.sql'))
  job <- bigrquery::bq_perform_query(sql,billing=Sys.getenv('MIDES_BILLING_ID','ipea-consorcios'),maximumBytesBilled='100000000000')
  bigrquery::bq_job_wait(job,quiet=TRUE)
  meta <- bigrquery::bq_job_meta(job)
  dest <- meta$configuration$query$destinationTable
  downloaded <- bigrquery::bq_table_download(bigrquery::bq_table(dest$projectId,dest$datasetId,dest$tableId),quiet=TRUE)
  write.csv(downloaded,cache,row.names=FALSE,na='',fileEncoding='UTF-8')
  write_json(list(data_consulta=as.character(Sys.Date()),raizes=new_roots,
    n_linhas=nrow(downloaded),estatisticas=meta$statistics),
    file.path(out,'fronteira_consulta_mides_manifesto.json'),pretty=TRUE,auto_unbox=TRUE)
  cat('MIDES complementar:',nrow(downloaded),'linhas agregadas\n')
}
if(!file.exists(cache)) stop('Execute com --consultar-mides antes de gerar o atlas.')
if('--somente-consulta' %in% commandArgs(TRUE)) quit(status=0)

original <- read_chars('universo_saude_mg_entidades.csv')
decisions <- read.csv(file.path(here,'evidencias/revisao_fora_84_2026_09_16.csv'),colClasses='character')
stopifnot(!anyDuplicated(decisions$cnpj_raiz_8))
financial <- readRDS(file.path(root,'dados/processado/painel_mg_anual.rds')) |>
  select(ano,id_municipio,documento_credor,valor_total,n_transacoes)
extra <- read.csv(cache,colClasses=c(documento_credor='character',id_municipio='character'))
stopifnot(!any(substr(financial$documento_credor,1,8) %in% new_roots))
payments <- bind_rows(financial,extra) |>
  mutate(cnpj_raiz_8=substr(documento_credor,1,8),codigo_ibge_6=substr(id_municipio,1,6)) |>
  filter(cnpj_raiz_8 %in% c(original$cnpj_raiz_8,front$cnpj_raiz_8),ano %in% 2014:2021) |>
  summarise(valor=sum(valor_total),n_transacoes=sum(n_transacoes),.by=c(cnpj_raiz_8,codigo_ibge_6,ano))
positive <- payments |> filter(valor>0)
summary <- positive |> summarise(n_anos_mides=n_distinct(ano),n_municipios_mides=n_distinct(codigo_ibge_6),
  valor_mides=sum(valor),anos_mides=paste(sort(unique(ano)),collapse=' | '),.by=cnpj_raiz_8)
audit <- front |> left_join(decisions,by='cnpj_raiz_8',relationship='one-to-one') |>
  left_join(summary,by='cnpj_raiz_8',relationship='one-to-one') |>
  mutate(n_unidades_ano_cnes=as.integer(n_unidades_ano_cnes),
    n_anos_mides=coalesce(n_anos_mides,0L),n_municipios_mides=coalesce(n_municipios_mides,0L),
    valor_mides=coalesce(valor_mides,0),anos_mides=coalesce(anos_mides,''),
    revisao_documental=!is.na(decisao),
    decisao=coalesce(decisao,'nao_incluir_sem_sinal_nas_fontes_cruzadas'),
    evidencia=coalesce(evidencia,'Triagem cadastro v0.5 + CNM + oito dezembros CNES; nenhum sinal selecionado de atendimento humano. Nao comprova inexistencia de rede indireta.'),
    fonte=coalesce(fonte,'cadastro IPEA MG; snapshot CNM 2026-08-27; DATASUS/STMG dezembro 2014-2021'),
    limite=coalesce(limite,'Triagem sistematica; nao corresponde a auditoria de todos os contratos da entidade.'),
    status_mides=if_else(origem=='somente_cnm_mg','consulta_complementar_por_raiz','extracao_original_cnpjs_cadastro'))
stopifnot(nrow(audit)==137,!anyDuplicated(audit$cnpj_raiz_8),
  all(audit$revisao_documental[audit$cnm_saude=='1' | audit$n_unidades_ano_cnes>0]))
write.csv(audit,file.path(out,'revisao_fora_84_resultado.csv'),row.names=FALSE,na='',fileEncoding='UTF-8')
write.csv(payments,file.path(out,'atlas_pagamentos_entidade_municipio_ano.csv'),row.names=FALSE,fileEncoding='UTF-8')

mg <- readRDS(file.path(root,'dashboards/base1_shiny/data/mg_municipios_sf_web.rds')) |>
  mutate(codigo_ibge_6=substr(as.character(cod_ibge_6),1,6),municipio=decode(municipio_geo)) |>
  select(codigo_ibge_6,municipio) |> st_transform(4326)
points <- suppressWarnings(st_point_on_surface(st_transform(mg,5880))) |> st_transform(4326)
xy <- st_coordinates(points)
lookup <- st_drop_geometry(mg) |> mutate(lon=xy[,1],lat=xy[,2])
current <- read_chars('elegibilidade_assistencial_unidades_atuais_saude_mg.csv') |>
  transmute(cnpj_raiz_8,ano='atual',cnes,codigo_ibge_6,nome=nome_estabelecimento_cnes,
    tipo=tipo_estabelecimento_cnes,funcao=funcao_assistencial,fonte='CNES atual; coleta 03/09/2026')
types <- c('04'='Policlinica','05'='Hospital geral','22'='Consultorio isolado','36'='Clinica/centro de especialidade',
  '39'='SADT isolado','62'='Hospital/dia','70'='Centro de atencao psicossocial',
  '32'='Unidade movel fluvial','40'='Unidade movel terrestre','42'='Unidade movel pre-hospitalar',
  '64'='Central regulacao','68'='Central gestao saude','76'='Central regulacao medica urgencias','81'='Central regulacao acesso')
historical <- bind_rows(read_chars('elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv'),
  read_chars('fronteira_cnes_unidades_2014_2021.csv')) |>
  transmute(cnpj_raiz_8,ano,cnes,codigo_ibge_6,nome=paste('CNES',cnes),
    tipo=unname(types[tipo_unidade_codigo]),funcao=funcao_assistencial,fonte=paste('DATASUS ST',competencia_referencia))
units <- bind_rows(current,historical) |> left_join(lookup,by='codigo_ibge_6',relationship='many-to-one')
stopifnot(nrow(units)==670+1868+74,!anyDuplicated(units[c('cnpj_raiz_8','ano','cnes')]))
write.csv(units,file.path(out,'atlas_unidades_consorcio_periodo.csv'),row.names=FALSE,na='',fileEncoding='UTF-8')
entities <- bind_rows(
  original |> transmute(raiz=cnpj_raiz_8,cnpj=cnpj_canonico,sigla=sigla_canonica,nome=razao_social_canonica,
    sede=municipio_sede_canonico,grupo='84 originais',decisao='Universo original de 84 entidades. A base v1 foi fechada em 24/09/2026; a amostra de estimacao depende da formula e da elegibilidade dos pares.',evidencia='',fonte='',limite=''),
  audit |> transmute(raiz=cnpj_raiz_8,cnpj=cnpj_canonico,sigla=sigla_canonica,nome=razao_social,
    sede=municipio_sede,grupo=if_else(revisao_documental,'Fronteira: revisao documental','Fronteira: triagem'),decisao,evidencia,fonte,limite)) |>
  mutate(across(where(is.character),decode),sigla=if_else(sigla==''|sigla=='-',nome,sigla)) |>
  arrange(grupo,sigla)
cnm <- read.csv('C:/IPEA/dados cnm/snapshots/2026-08-27/data/base_unificada_consorcios_macroareas.csv',sep=';',colClasses='character') |>
  mutate(raiz=substr(gsub('[^0-9]','',consorcio_cnpj),1,8)) |>
  filter(raiz %in% entities$raiz) |> select(raiz,municipios_ibge)
geofile <- file.path(out,'atlas_municipios.geojson')
st_write(mg,geofile,delete_dsn=TRUE,quiet=TRUE)
payload <- list(entities=entities,units=units,payments=positive,cnm=cnm,
               municipalities=fromJSON(geofile,simplifyVector=FALSE),date='16/09/2026')
write_json(payload,file.path(out,'atlas_dados.json'),auto_unbox=TRUE,na='null',digits=8)
widget <- leaflet(height=650,options=leafletOptions(preferCanvas=TRUE,minZoom=5,maxZoom=13)) |>
  fitBounds(-51.2,-23.1,-39.6,-14.2) |>
  onRender(paste(readLines(file.path(here,'atlas_consorcios.js'),encoding='UTF-8'),collapse='\n'),data=payload)
page <- prependContent(widget, tags$div(id='atlas-controls'))
page <- appendContent(page,tags$div(id='atlas-detail'))
if(!rmarkdown::pandoc_available()) Sys.setenv(RSTUDIO_PANDOC=Sys.getenv('RSTUDIO_PANDOC',
  'C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools'))
saveWidget(page,file.path(out,'atlas_consorcios_saude_mg.html'),selfcontained=TRUE,title='Atlas dos consorcios de saude em MG')
cat('Atlas:',nrow(entities),'entidades;',nrow(units),'registros CNES por periodo.\n')
print(audit |> count(decisao))
