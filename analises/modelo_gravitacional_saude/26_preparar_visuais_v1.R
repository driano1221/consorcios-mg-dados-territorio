# Executar da raiz do repositorio. Apenas le as fontes; grava em outputs/visuais_v1.
invisible(Sys.setlocale('LC_ALL', 'Portuguese_Brazil.utf8'))
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr); library(sf); library(jsonlite)})
here <- file.path(getwd(), 'analises/modelo_gravitacional_saude')
out <- file.path(here, 'outputs'); dest <- file.path(out, 'visuais_v1')
dir.create(file.path(dest, 'dados'), recursive=TRUE, showWarnings=FALSE)
read_data <- function(name) read_csv(file.path(out,name), col_types=cols(.default=col_character()), show_col_types=FALSE)
decode <- function(x) {
  affected <- which(!is.na(x) & grepl('<U\\+',x))
  x[affected] <- vapply(x[affected], function(s) {
  hits <- gregexpr('<U\\+[0-9A-Fa-f]{4,6}>',s,perl=TRUE); tokens <- regmatches(s,hits)[[1]]
  if(length(tokens)) regmatches(s,hits) <- list(vapply(tokens,function(z) intToUtf8(strtoi(sub('>','',sub('<U\\+','',z)),16)),''))
  s
  }, '', USE.NAMES=FALSE)
  x
}
clean <- function(x) x |> mutate(across(where(is.character), decode))
f <- clean(readRDS(file.path(out,'base_v1/base_financeira_v1.rds')))
g <- clean(readRDS(file.path(out,'base_v1/base_gravitacional_v1.rds')))
cap <- clean(read_data('base_v1/capacidade_entidade_ano.csv')) |>
  mutate(across(-c(cnpj_raiz_8,entidade,alerta_temporal),as.numeric))
ledger <- clean(read_data('base_v1/inclusao_entidade_ano.csv')) |>
  mutate(ano=as.integer(ano),pares_pagos=as.integer(pares_pagos),valor_mides=as.numeric(valor_mides))
atlas <- fromJSON(file.path(out,'atlas_dados.json'))
entities <- clean(atlas$entities)
entities$decisao[entities$grupo=='84 originais'] <- 'Universo original de 84 entidades. A inclusao na v1 varia por escopo e ano; consulte o registro de inclusao.'
entities <- entities |> left_join(ledger |> distinct(cnpj_raiz_8,entidade,grupo_escopo),by=c('raiz'='cnpj_raiz_8'),relationship='one-to-one')
entities$rotulo <- ifelse(is.na(entities$entidade),entities$sigla,entities$entidade)
entities$rotulo[entities$raiz=='06070075'] <- 'CONVALES'
labels <- entities |> transmute(cnpj_raiz_8=raiz,rotulo)
paid <- f |> filter(valor_total>0)
direct <- g |> filter(valor_total>0)
annual <- paid |> summarise(valor=sum(valor_total),relacoes=n(),municipios=n_distinct(id_municipio),consorcios=n_distinct(cnpj_raiz_8),.by=ano) |>
  left_join(direct |> summarise(valor_direto=sum(valor_total),relacoes_diretas=n(),.by=ano),by='ano',relationship='one-to-one') |>
  mutate(fracao_relacoes=relacoes_diretas/relacoes,fracao_valor=valor_direto/valor) |> arrange(ano)
entity_year <- f |> summarise(valor=sum(valor_total),pagadores=sum(valor_total>0),.by=c(cnpj_raiz_8,entidade,ano)) |>
  left_join(cap,by=c('cnpj_raiz_8','entidade','ano'),relationship='one-to-one') |> arrange(cnpj_raiz_8,ano)
ranking <- bind_rows(entity_year |> transmute(periodo=as.character(ano),cnpj_raiz_8,entidade,valor,pagadores),
  paid |> summarise(valor=sum(valor_total),pagadores=n_distinct(id_municipio),.by=c(cnpj_raiz_8,entidade)) |> mutate(periodo='2014-2021')) |>
  group_by(periodo) |> arrange(desc(valor),cnpj_raiz_8,.by_group=TRUE) |>
  mutate(posicao=row_number(),participacao=valor/sum(valor),acumulada=cumsum(participacao)) |> ungroup()
units <- clean(atlas$units) |> mutate(ano=as.character(ano))
hist <- bind_rows(read_data('elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv'),
  read_data('candidatas_cnes_capacidade_unidades_2014_2021.csv')) |>
  mutate(ano=as.integer(ano),across(c(n_profissionais_sus_distintos,n_servicos_especializados_sus,carga_horaria_sus,leitos_sus),as.numeric))
cap_all <- hist |> filter(funcao_assistencial=='destino_clinico_fixo') |>
  summarise(unidades=n(),profissionais=sum(n_profissionais_sus_distintos),servicos=sum(n_servicos_especializados_sus),
    horas=sum(carga_horaria_sus),leitos=sum(leitos_sus),.by=c(cnpj_raiz_8,ano))
v1keys <- f |> distinct(cnpj_raiz_8,ano) |> mutate(ano=as.character(ano))
units_v1 <- units |> semi_join(v1keys,by=c('cnpj_raiz_8','ano'))
unit_profile <- units_v1 |> count(ano,funcao,tipo,name='unidades') |> mutate(ano=as.integer(ano))
aux_roots <- ledger |> filter(cnpj_raiz_8 %in% c('01272081','06070075','07306549')) |> distinct(cnpj_raiz_8,entidade)
aux <- ledger |> semi_join(aux_roots,by='cnpj_raiz_8') |>
  left_join(cap_all,by=c('cnpj_raiz_8','ano'),relationship='one-to-one') |>
  select(cnpj_raiz_8,entidade,ano,pares_pagos,valor_mides,unidades,profissionais,servicos,horas,leitos) |>
  mutate(entidade=if_else(cnpj_raiz_8=='06070075','CONVALES',entidade))
absent <- paid |> filter(!elegivel_gravitacional_v1) |>
  left_join(ledger |> select(cnpj_raiz_8,ano,grupo_conciliacao),by=c('cnpj_raiz_8','ano'),relationship='many-to-one') |>
  summarise(relacoes=n(),valor=sum(valor_total),.by=c(grupo_conciliacao,classificacao_oferta))
times <- direct |> select(cnpj_raiz_8,entidade,ano,id_municipio,municipio,valor_total,tempo_minimo_min,destino_clinico_mais_proximo_id)
time_dist <- times |> mutate(faixa=floor(tempo_minimo_min/30)*30) |> summarise(relacoes=n(),valor=sum(valor_total),.by=faixa) |> arrange(faixa)
time_ecdf <- times |> summarise(relacoes=n(),valor=sum(valor_total),.by=tempo_minimo_min) |> arrange(tempo_minimo_min) |>
  mutate(fracao_relacoes=cumsum(relacoes)/sum(relacoes),fracao_valor=cumsum(valor)/sum(valor))
time_entity <- times |> summarise(n=n(),min=min(tempo_minimo_min),p25=quantile(tempo_minimo_min,.25),
  mediana=median(tempo_minimo_min),p75=quantile(tempo_minimo_min,.75),max=max(tempo_minimo_min),.by=c(cnpj_raiz_8,entidade)) |> arrange(mediana)
time_stats <- data.frame(n=nrow(times),min=min(times$tempo_minimo_min),mediana=median(times$tempo_minimo_min),
  p90=unname(quantile(times$tempo_minimo_min,.9)),max=max(times$tempo_minimo_min),
  intramunicipais=sum(times$tempo_minimo_min==0),ate60=sum(times$tempo_minimo_min<=60),ate120=sum(times$tempo_minimo_min<=120))
geom <- readRDS(file.path(getwd(),'dashboards/base1_shiny/data/mg_municipios_sf_web.rds')) |>
  transmute(code=substr(as.character(cod_ibge_6),1,6),name=decode(municipio_geo)) |> st_transform(5880) |>
  st_simplify(dTolerance=100,preserveTopology=TRUE)
xy <- st_coordinates(suppressWarnings(st_point_on_surface(geom)))
geom$x <- xy[,1];geom$y <- xy[,2]
polys <- lapply(seq_len(nrow(geom)),function(i){
  coords <- st_coordinates(geom[i,]); groups <- interaction(as.data.frame(coords)[,grep('^L',colnames(coords)),drop=FALSE],drop=TRUE)
  rings <- lapply(split(seq_len(nrow(coords)),groups),function(ids) unname(round(coords[ids,c('X','Y'),drop=FALSE],0)))
  list(code=geom$code[i],name=geom$name[i],x=round(geom$x[i]),y=round(geom$y[i]),rings=unname(rings))
})
# Os pontos do atlas sao representativos dos municipios, nao enderecos CNES.
units <- units |> left_join(st_drop_geometry(geom) |> select(code,x,y),by=c('codigo_ibge_6'='code'),relationship='many-to-one')
summary <- list(relacoes=nrow(paid),valor=sum(paid$valor_total),relacoes_diretas=nrow(direct),valor_direto=sum(direct$valor_total),
  municipios=n_distinct(paid$id_municipio),consorcios=n_distinct(f$cnpj_raiz_8),consorcios_diretos=n_distinct(g$cnpj_raiz_8),
  capacidade_entidades_ano=nrow(cap),linhas_financeira=nrow(f),linhas_direta=nrow(g),zeros_financeira=sum(f$valor_total==0),zeros_direta=sum(g$valor_total==0))
stopifnot(summary$relacoes==10735,summary$relacoes_diretas==5612,nrow(cap)==379,nrow(units)==2612,
  nrow(entities)==221,nrow(geom)==853,nrow(aux_roots)==3,
  sum(absent$relacoes)==5123,abs(sum(annual$valor)-3315638156.17)<.01,
  !anyDuplicated(units[c('cnpj_raiz_8','ano','cnes')]))
tables <- list(pagamentos_anuais=annual,pagamentos_consorcio_ano=entity_year,ranking=ranking,capacidade=cap,
  unidades_por_tipo=unit_profile,multiarea=aux,ausencia_polo=absent,tempos_relacoes=times,
  tempos_distribuicao=time_dist,tempos_acumulada=time_ecdf,tempos_consorcio=time_entity,tempos_resumo=time_stats,
  tempos_extremos=times |> arrange(desc(tempo_minimo_min)) |> slice_head(n=30))
for(n in names(tables)) write_excel_csv2(tables[[n]],file.path(dest,'dados',paste0(n,'.csv')),na='')
data <- list(summary=summary,annual=annual,entity_year=entity_year,ranking=ranking,cap=cap,aux=aux,
  units_profile=unit_profile,absence=absent,times=time_stats,entities=entities,units=units,cap_all=cap_all,
  payments=clean(atlas$payments),cnm=atlas$cnm,ledger=ledger,polys=polys,
  example=clean(read_data('base_v1/exemplo_igarape_cismep.csv')))
write_json(data,file.path(dest,'dados','visuais.json'),dataframe='rows',auto_unbox=TRUE,digits=8,na='null')
saveRDS(list(tables=tables,geom=geom,units=units,entities=entities,ledger=ledger,summary=summary,
  source_files=c('base_v1/base_financeira_v1.rds','base_v1/base_gravitacional_v1.rds',
  'base_v1/capacidade_entidade_ano.csv','base_v1/inclusao_entidade_ano.csv','atlas_dados.json',
  'elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv','candidatas_cnes_capacidade_unidades_2014_2021.csv')),
  file.path(dest,'dados','preparacao.rds'))
cat('Dados visuais preparados sem alterar a v1.\n');print(aux_roots);print(time_stats)
