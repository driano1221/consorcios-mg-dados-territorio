# Preparacao dos tres cenarios de 2019. Nao estima nem altera a v1.
# Executar nesta pasta; as sedes sao cadastrais, sem vigencia historica validada.
suppressPackageStartupMessages(library(dplyr))
invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8"))
out <- "outputs/cenarios_adesao"
dir.create(out, recursive=TRUE, showWarnings=FALSE)
inputs <- paste0("outputs/", c("base_v1/base_financeira_v1.rds",
 "base_v1/capacidade_entidade_ano.csv", "viabilidade_logit/populacao_sede_cadastral_2019.csv",
 "elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv",
 "candidatas_cnes_capacidade_unidades_2014_2021.csv", "rotas_mg_distbrasil_cache.rds",
 "cnes_historico_presenca_mensal_saude_mg_2014_2021.csv",
 "auditoria_alternativas/unidades_cnes_dezembro_corrigidas.csv"))
hashes <- vapply(inputs, function(p) digest::digest(file=p,algo="sha256"),character(1))
decode <- function(s) {
 for (i in which(!is.na(s) & grepl('<U\\+',s))) {
  hit <- gregexpr('<U\\+[0-9A-Fa-f]{4,6}>',s[i],perl=TRUE)
  tok <- regmatches(s[i],hit)[[1]]
  regmatches(s[i],hit) <- list(vapply(tok,function(z)
   intToUtf8(strtoi(sub('>','',sub('<U\\+','',z)),16)),''))
 }
 s
}
clean <- function(d) mutate(d,across(where(is.character),decode))
read_csv <- function(p) clean(read.csv(p,colClasses="character",fileEncoding="UTF-8-BOM"))
save_csv <- function(d,name) write.csv(d,file.path(out,paste0(name,".csv")),
 row.names=FALSE,na="",fileEncoding="UTF-8")
f <- clean(readRDS(inputs[1])) |> filter(ano==2019) |>
 mutate(adesao_financeira=as.integer(valor_total>0))
stopifnot(nrow(f)==853*73,!anyDuplicated(f[c("id_municipio","cnpj_raiz_8")]),
 all(f$valor_total>=0),!anyNA(f$populacao_ibge),all(f$populacao_ibge>0))
origins <- f |> distinct(id_municipio,municipio,populacao_ibge) |>
 mutate(codigo_ibge_6=substr(id_municipio,1,6))
entities <- f |> summarise(pares_pagos=sum(adesao_financeira),
 valor_pago=sum(valor_total),.by=c(cnpj_raiz_8,entidade))
seats <- read_csv(inputs[3]) |> select(cnpj_raiz_8,sede_cadastral,id_sede)
stopifnot(nrow(seats)==73,!anyDuplicated(seats$cnpj_raiz_8))
# O script 33 valida identificadores contra os oito ST brutos. Cenarios e
# v1 revisada usam esse mesmo insumo; a primeira entrega esta arquivada.
units <- read_csv(inputs[8]) |>
 filter(ano=="2019") |> semi_join(entities,by="cnpj_raiz_8") |>
 mutate(horas_sus=as.numeric(carga_horaria_sus)) |>
 left_join(origins |> select(codigo_ibge_6,id_destino=id_municipio,
 municipio_destino=municipio),by="codigo_ibge_6",relationship="many-to-one")
stopifnot(!anyDuplicated(units[c("cnpj_raiz_8","cnes")]),
 !anyNA(units$horas_sus),all(units$horas_sus>=0),!anyNA(units$id_destino))
clinical <- units |> filter(funcao_assistencial=="destino_clinico_fixo")
by_function <- units |> summarise(unidades=n(),horas_sus=sum(horas_sus),
 .by=c(cnpj_raiz_8,funcao_assistencial)) |> left_join(entities,by="cnpj_raiz_8")
inventory <- entities |>
 left_join(units |> summarise(n_unidades_cnes=n(),horas_todas=sum(horas_sus),
  .by=cnpj_raiz_8),by="cnpj_raiz_8") |>
 left_join(clinical |> summarise(n_clinicas=n(),horas_clinicas=sum(horas_sus),
  .by=cnpj_raiz_8),by="cnpj_raiz_8") |>
 left_join(seats,by="cnpj_raiz_8") |>
 mutate(n_unidades_cnes=coalesce(n_unidades_cnes,0L),n_clinicas=coalesce(n_clinicas,0L),
  horas_base=if_else(n_clinicas>0,horas_clinicas,horas_todas),
  origem_horas=case_when(n_clinicas>0 ~ "clinicas_do_ano",
   n_unidades_cnes>0 ~ "moveis_ou_nao_clinicas_do_ano",TRUE ~ "sem_unidade_cnes_identificada"),
  sede_historica="referencia_cadastral_vigencia_2019_nao_validada")
stopifnot(nrow(inventory)==73,sum(inventory$n_clinicas>0)==54,
 sum(inventory$n_clinicas)==62,sum(is.na(inventory$horas_base))==10)
cap <- read_csv(inputs[2]) |> filter(ano=="2019")
check_cap <- inventory |> filter(n_clinicas>0) |>
 left_join(cap |> select(cnpj_raiz_8,horas_v1=horas_sus_clinicas_soma_registros),
 by="cnpj_raiz_8",relationship="one-to-one")
stopifnot(all(check_cap$horas_clinicas==as.numeric(check_cap$horas_v1)))

# Mesmo conjunto de horas para S2 e S3: clinicas quando existem; outras
# modalidades somente no complemento exploratorio, nunca somadas silenciosamente.
points1 <- clinical |> transmute(cenario="S1_unidades",cnpj_raiz_8,
 ponto_id=cnes,id_destino,municipio_destino,horas_ponto=horas_sus,
 tipo_destino="municipio_unidade_clinica")
points2 <- inventory |> transmute(cenario="S2_sedes",cnpj_raiz_8,
 ponto_id=paste0("sede_",cnpj_raiz_8),id_destino=id_sede,
 municipio_destino=sede_cadastral,horas_ponto=horas_base,
 tipo_destino="sede_cadastral_vigencia_nao_validada")
points3 <- bind_rows(mutate(points1,cenario="S3_misto"),
 points2 |> semi_join(inventory |> filter(n_clinicas==0),by="cnpj_raiz_8") |>
 mutate(cenario="S3_misto"))
points <- bind_rows(points1,points2,points3) |>
 left_join(inventory |> select(cnpj_raiz_8,entidade,horas_base,origem_horas),by="cnpj_raiz_8") |>
 mutate(peso_horas=if_else(horas_base>0,horas_ponto/horas_base,NA_real_))
stopifnot(!anyNA(points$id_destino),
 !anyDuplicated(points[c("cenario","cnpj_raiz_8","ponto_id")]))
weights <- points |> filter(horas_base>0) |>
 summarise(total=sum(peso_horas),.by=c(cenario,cnpj_raiz_8))
stopifnot(all(abs(weights$total-1)<1e-12))
road <- readRDS(inputs[6])
stopifnot(nrow(road)==choose(853,2),!anyDuplicated(road[c("a","b")]),
 !anyNA(road[c("tempo_min","distancia_km")]))
routes <- merge(origins,points,by=NULL) |> as_tibble() |>
 mutate(a=pmin(id_municipio,id_destino),b=pmax(id_municipio,id_destino)) |>
 left_join(road,by=c("a","b"),relationship="many-to-one") |>
 mutate(mesmo_municipio=id_municipio==id_destino,
  tempo_min=if_else(mesmo_municipio,0,tempo_min),
  distancia_km=if_else(mesmo_municipio,0,distancia_km)) |> select(-a,-b)
stopifnot(!anyNA(routes[c("tempo_min","distancia_km")]),
 all(routes$tempo_min>=0),all(routes$distancia_km>=0))
pair_routes <- routes |> summarise(n_pontos=n(),
 distancia_min_km=min(distancia_km),tempo_minimo_min=min(tempo_min),
 distancia_media_horas_km=if(all(is.finite(peso_horas))) sum(peso_horas*distancia_km) else NA_real_,
 tempo_medio_horas_min=if(all(is.finite(peso_horas))) sum(peso_horas*tempo_min) else NA_real_,
 impedancia_log_km_horas=if(all(is.finite(peso_horas))) sum(peso_horas*log1p(distancia_km)) else NA_real_,
 impedancia_log_min_horas=if(all(is.finite(peso_horas))) sum(peso_horas*log1p(tempo_min)) else NA_real_,
 .by=c(cenario,id_municipio,cnpj_raiz_8))
pair_base <- bind_rows(lapply(c("S1_unidades","S2_sedes","S3_misto"),function(s)
 mutate(f,cenario=s))) |>
 left_join(pair_routes,by=c("cenario","id_municipio","cnpj_raiz_8"),relationship="one-to-one") |>
 left_join(inventory |> select(cnpj_raiz_8,horas_base,origem_horas,sede_historica),by="cnpj_raiz_8") |>
 mutate(destino_identificado=!is.na(n_pontos),capacidade_identificada=!is.na(horas_base),
  usa_sede=cenario=="S2_sedes" | (cenario=="S3_misto" & origem_horas!="clinicas_do_ano"),
  log_populacao=log(populacao_ibge),
  log_horas_positivas=log(if_else(horas_base>0,horas_base,NA_real_)),
  log1p_horas_sensibilidade=log1p(horas_base),
  pre_elegivel_cadastral=destino_identificado & capacidade_identificada,
  pre_elegivel_horas_positivas=pre_elegivel_cadastral & coalesce(horas_base>0,FALSE),
  amostra_comum=cnpj_raiz_8 %in% inventory$cnpj_raiz_8[inventory$n_clinicas>0 &
    !is.na(inventory$horas_base) & inventory$horas_base>0],
  diagnostico=case_when(!destino_identificado ~ "sem_destino_clinico",
   !capacidade_identificada ~ "sem_capacidade_identificada",
   horas_base==0 ~ "horas_zero_regra_a_definir",
   origem_horas!="clinicas_do_ano" ~ "exploratorio_modalidade_nao_clinica",
   cenario=="S2_sedes" ~ "exploratorio_sede_sem_vigencia_validada",
   TRUE ~ "clinicas_horas_positivas"))
stopifnot(nrow(pair_base)==3*nrow(f),
 !anyDuplicated(pair_base[c("cenario","id_municipio","cnpj_raiz_8")]))
summary <- bind_rows(lapply(c("pre_elegivel_cadastral","pre_elegivel_horas_positivas","amostra_comum"),function(flag)
 pair_base |> filter(.data[[flag]]) |> summarise(
  regra=flag,consorcios=n_distinct(cnpj_raiz_8),municipios=n_distinct(id_municipio),
  linhas=n(),positivos=sum(adesao_financeira),zeros=sum(adesao_financeira==0),
  valor_pago=sum(valor_total),fracao_relacoes=sum(adesao_financeira)/sum(f$adesao_financeira),
  fracao_valor=sum(valor_total)/sum(f$valor_total),
  pares_distancia_zero=sum(distancia_min_km==0),
  pagos_distancia_zero=sum(distancia_min_km==0 & adesao_financeira==1),.by=cenario)))
municipal <- pair_base |> filter(pre_elegivel_horas_positivas) |>
 summarise(vinculos=sum(adesao_financeira),valor=sum(valor_total),
 .by=c(cenario,id_municipio,municipio))
municipal_summary <- municipal |> summarise(municipios=n(),sem_pagamento=sum(vinculos==0),
 um_vinculo=sum(vinculos==1),multiplos_vinculos=sum(vinculos>1),.by=cenario)
stopifnot(all(summary$linhas==853*summary$consorcios),
 all(summary$positivos+summary$zeros==summary$linhas),
 all(municipal_summary$municipios==853))
save_csv(inventory,"inventario_consorcios_2019")
monthly <- read_csv(inputs[7]) |> filter(cnpj_raiz_8=="05802877",cnes=="5364167")
stopifnot(monthly$n_meses_presente[monthly$ano=="2021"]=="6",
 monthly$meses_presente[monthly$ano=="2021"]=="01 | 02 | 03 | 04 | 05 | 06")
save_csv(monthly,"cismep_brumadinho_presenca_mensal")
save_csv(by_function,"horas_por_modalidade_2019")
save_csv(points,"destinos_cenarios_2019")
save_csv(routes,"rotas_por_ponto_2019")
save_csv(pair_base,"grade_candidata_cenarios_2019")
save_csv(summary,"comparacao_cenarios_2019")
save_csv(municipal_summary,"municipios_por_cenario_2019")
save_csv(pair_base |> filter(municipio %in% c("Igarapé","Conceição Do Pará")) |>
 filter(adesao_financeira==1 | cnpj_raiz_8=="05802877"),"exemplos_2019")
save_csv(pair_base |> distinct(cenario,cnpj_raiz_8,entidade,horas_base,origem_horas,
 diagnostico,pre_elegivel_cadastral,pre_elegivel_horas_positivas),"decisoes_por_consorcio_2019")
dictionary <- data.frame(
 variavel=c("adesao_financeira","cenario","n_pontos","distancia_min_km","tempo_minimo_min",
  "distancia_media_horas_km","tempo_medio_horas_min","impedancia_log_km_horas",
  "impedancia_log_min_horas","horas_base","origem_horas","sede_historica","usa_sede",
  "destino_identificado","capacidade_identificada","log_populacao","log_horas_positivas",
  "log1p_horas_sensibilidade","pre_elegivel_cadastral","pre_elegivel_horas_positivas",
  "amostra_comum","diagnostico"),
 definicao=c("1 se valor_total positivo; varios positivos permitidos por origem",
  "S1 unidades; S2 sedes; S3 unidades com complemento por sede",
  "Numero de pontos cadastrais ligados ao par; NA sem destino no cenario",
  "Menor distancia em km entre os pontos; nao e necessariamente a rota de menor tempo",
  "Menor tempo em minutos entre os pontos",
  "Media das distancias ponderada pelas horas por unidade; NA sem massa positiva",
  "Media dos tempos ponderada pelas horas por unidade; NA sem massa positiva",
  "Soma dos pesos de horas vezes ln(1+distancia_km/1km); proposta de impedancia",
  "Soma dos pesos de horas vezes ln(1+tempo_min/1min); sensibilidade temporal",
  "Horas clinicas se ha clinica; senao horas de outras modalidades; NA sem unidade",
  "Distingue clinicas, outras modalidades e ausencia; nao combina modalidades silenciosamente",
  "Sede cadastral sem comprovacao da vigencia em 2019; qualifica somente uso da sede",
  "TRUE se o cenario usa a sede neste par; FALSE se usa unidades",
  "Ha destino municipal e rotas completas neste cenario",
  "Ha soma de horas disponivel; inclui soma cadastral zero, distingue de ausencia",
  "ln(populacao_ibge) da origem, em habitantes",
  "ln(horas_base) somente se horas positivas; NA no zero ou ausencia",
  "ln(1+horas_base), retendo zero como sensibilidade; NA permanece NA",
  "Destino e capacidade conhecida, incluindo zero; nao e aprovacao institucional",
  "Pre-elegibilidade com horas estritamente positivas, criterio proposto para log(H)",
  "53 consorcios clinicos com horas positivas comuns aos tres cenarios",
  "Motivo de pre-elegibilidade ou pendencia do par"))
save_csv(dictionary,"dicionario_campos_novos")
stopifnot(identical(hashes,vapply(inputs,function(p)
 digest::digest(file=p,algo="sha256"),character(1))))
save_csv(data.frame(arquivo=inputs,sha256=hashes),"fontes")
jsonlite::write_json(list(status="PREPARACAO_SEM_ESTIMACAO",ano=2019,
 universo_financeiro=list(consorcios=73,municipios=853,linhas=nrow(f),
 positivos=sum(f$adesao_financeira),valor=sum(f$valor_total)),
 comparacao=summary,municipios=municipal_summary,
 limites=c("Sedes cadastrais sem vigencia historica validada",
 "Horas moveis/nao clinicas sao complemento exploratorio",
 "Regras de massa zero e forma funcional descritas como proposta",
 "Nenhum parametro ou probabilidade foi estimado")),file.path(out,"resumo.json"),
 auto_unbox=TRUE,pretty=TRUE,na="null")
print(summary,width=Inf)
print(municipal_summary,width=Inf)
products <- list.files(out,pattern="\\.(csv|json)$",full.names=TRUE)
products <- products[basename(products)!="manifesto_produtos.csv"]
save_csv(data.frame(arquivo=basename(products),sha256=vapply(products,function(p)
 digest::digest(file=p,algo="sha256"),character(1))),"manifesto_produtos")
cat("OK: preparacao sem estimacao; 853 origens em todos os cenarios; fontes preservadas.\n")
