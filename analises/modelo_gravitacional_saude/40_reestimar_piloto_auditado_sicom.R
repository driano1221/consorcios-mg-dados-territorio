# Executar da pasta do modelo. Sensibilidade documental de 2019; preserva v1 e script 32.
suppressPackageStartupMessages(library(dplyr))
invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8"))
out <- "outputs/auditoria_sicom_modelo_2019"
dir.create(out, recursive=TRUE, showWarnings=FALSE)
inputs <- c("outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv",
 "outputs/adesao_financeira/grupos_validacao.csv",
 "outputs/adesao_financeira/previsoes.csv.gz",
 "outputs/adesao_financeira/coeficientes.csv",
 "evidencias/decisoes_sicom_2026_09_25.csv")
hash <- function(p) digest::digest(file=p,algo="sha256")
hashes <- vapply(inputs,hash,"")
read <- function(p) {
 fields <- names(read.csv(p,fileEncoding="UTF-8-BOM",nrows=0))
 classes <- c(id_municipio="character",cnpj_raiz_8="character",cnpj="character")
 read.csv(p,fileEncoding="UTF-8-BOM",colClasses=classes[names(classes) %in% fields])
}
save <- function(d,n) write.csv(d,file.path(out,paste0(n,".csv")),
 row.names=FALSE,na="",fileEncoding="UTF-8")
g <- read(inputs[1]); folds <- read(inputs[2]); old <- read(inputs[3]); old_co <- read(inputs[4])
dec <- read(inputs[5]) |> filter(ano==2019, y_original==1) |>
 mutate(cnpj_raiz_8=substr(cnpj,1,8))
stopifnot(nrow(dec)==2, !anyDuplicated(dec[c("id_municipio","cnpj_raiz_8")]),
 setequal(dec$status,c("objetos_sustentam_vinculo_financeiro_com_nome_conflitante",
  "objetos_contradizem_atribuicao_consorcial")),
 sum(is.na(dec$y_auditado))==1, sum(dec$y_auditado==1,na.rm=TRUE)==1,
 nrow(folds)==853, !anyDuplicated(folds$id_municipio))
removed <- dec |> filter(is.na(y_auditado))
supported <- dec |> filter(y_auditado==1)
stopifnot(removed$id_municipio=="3118403",removed$cnpj_raiz_8=="00639952",
 supported$id_municipio=="3161205",supported$cnpj_raiz_8=="00079634")
specs <- data.frame(modelo=c("clinicas53","sedes53","sedes62","misto62"),
 cenario=c("S1_unidades","S2_sedes","S2_sedes","S3_misto"),
 regra=c("amostra_comum","amostra_comum","pre_elegivel_horas_positivas",
  "pre_elegivel_horas_positivas"))
fit <- function(d) {
 r <- glm(adesao_financeira ~ log_populacao+log_horas_positivas+impedancia_log_km_horas,
  data=d,family=binomial(),na.action=na.fail,
  control=glm.control(epsilon=1e-11,maxit=200),x=TRUE,y=TRUE)
 stopifnot(r$converged,!r$boundary,r$rank==4,all(is.finite(coef(r))),
  max(abs(crossprod(r$x,r$y-fitted(r))))/nrow(d)<1e-8)
 r
}
score <- function(y,p) {
 q <- pmax(1e-15,pmin(1-1e-15,p)); n1 <- sum(y)
 o <- order(p,decreasing=TRUE); yy <- y[o]; pp <- p[o]
 ends <- c(which(diff(pp)!=0),length(pp)); tp <- cumsum(yy)[ends]
 c(brier=mean((y-p)^2),logloss=-mean(y*log(q)+(1-y)*log1p(-q)),
  average_precision=sum(diff(c(0,tp))*tp/ends)/n1,
  roc_auc=(sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*sum(y==0)))
}
samples <- coefficients <- fold_coefs <- metrics <- predictions <- list()
for(i in seq_len(nrow(specs))) {
 s <- specs[i,]
 d <- g |> filter(cenario==s$cenario,.data[[s$regra]]) |>
  arrange(id_municipio,cnpj_raiz_8) |>
  left_join(folds,by="id_municipio",relationship="many-to-one")
 observed <- inner_join(d,dec,by=c("id_municipio","cnpj_raiz_8"),relationship="many-to-one")
 stopifnot(nrow(observed)==2,all(observed$adesao_financeira==observed$y_original),
  all(abs(observed$valor_total-observed$valor_mides)<.01))
 a <- anti_join(d,removed,by=c("id_municipio","cnpj_raiz_8"))
 stopifnot(nrow(a)==nrow(d)-1,sum(a$adesao_financeira)==sum(d$adesao_financeira)-1,
  n_distinct(a$id_municipio)==853,!anyNA(a[c("log_populacao","log_horas_positivas",
   "impedancia_log_km_horas","adesao_financeira","municipios","espacial")]))
 r <- fit(a)
 co <- old_co |> filter(modelo==s$modelo) |>
  select(termo,coeficiente_original=coeficiente) |>
  mutate(termo=recode(termo,log_horas="log_horas_positivas",
   impedancia="impedancia_log_km_horas"))
 stopifnot(nrow(co)==4,!anyDuplicated(co$termo))
 coefficients[[i]] <- data.frame(modelo=s$modelo,termo=names(coef(r)),
  coeficiente_auditado=unname(coef(r))) |>
  left_join(co,by="termo",relationship="one-to-one") |>
  mutate(diferenca=coeficiente_auditado-coeficiente_original)
 stopifnot(!anyNA(coefficients[[i]]))
 samples[[i]] <- data.frame(modelo=s$modelo,pares_original=nrow(d),
  pares_auditado=nrow(a),positivos_original=sum(d$adesao_financeira),
  positivos_auditado=sum(a$adesao_financeira),
  valor_original=sum(d$valor_total),valor_auditado=sum(a$valor_total),
  positivos_sustentados_por_sicom=1L,pares_indeterminados_retirados=1L)
 for(scheme in c("municipios","espacial")) {
  prior <- old |> filter(modelo==s$modelo,validacao==scheme) |>
   select(id_municipio,cnpj_raiz_8,prob_original=prob_validacao)
  z <- left_join(a,prior,by=c("id_municipio","cnpj_raiz_8"),relationship="one-to-one")
  stopifnot(nrow(z)==nrow(a),!anyNA(z$prob_original))
  z$prob_auditada <- NA_real_
  for(k in 1:5) {
   test <- z[[scheme]]==k; train <- !test
   stopifnot(length(intersect(z$id_municipio[train],z$id_municipio[test]))==0)
   cv <- fit(z[train,]); z$prob_auditada[test] <- predict(cv,z[test,],type="response")
   fold_coefs[[length(fold_coefs)+1]] <- data.frame(modelo=s$modelo,
    validacao=scheme,fold=k,termo=names(coef(cv)),coeficiente=unname(coef(cv)),
    n_treino=sum(train),positivos_treino=sum(z$adesao_financeira[train]))
  }
  stopifnot(all(is.finite(z$prob_auditada)),all(z$prob_auditada>0 & z$prob_auditada<1))
  for(version in c("original_mesma_amostra","auditado")) {
   p <- if(version=="auditado") z$prob_auditada else z$prob_original
   metrics[[length(metrics)+1]] <- cbind(data.frame(modelo=s$modelo,
    validacao=scheme,versao=version,pares=nrow(z),
    positivos=sum(z$adesao_financeira)),as.data.frame(as.list(score(z$adesao_financeira,p))))
  }
  predictions[[length(predictions)+1]] <- z |>
   select(id_municipio,cnpj_raiz_8,adesao_financeira,valor_total,
    log_populacao,log_horas_positivas,impedancia_log_km_horas,all_of(scheme),
    prob_original,prob_auditada) |>
   rename(fold=all_of(scheme)) |>
   mutate(modelo=s$modelo,validacao=scheme)
 }
 cat(s$modelo,":",nrow(a),"pares;",sum(a$adesao_financeira),"positivos\n")
}
save(bind_rows(samples),"amostras");save(bind_rows(coefficients),"coeficientes")
save(bind_rows(fold_coefs),"coeficientes_validacao")
save(bind_rows(metrics),"validacao_mesma_amostra")
save(dec |> select(id_municipio,cnpj_raiz_8,ano,status,y_original,y_auditado,
 valor_mides),"decisoes_2019")
con <- gzfile(file.path(out,"previsoes_comparacao.csv.gz"),"wt",encoding="UTF-8")
write.csv(bind_rows(predictions),con,row.names=FALSE,na="");close(con)
stopifnot(identical(hashes,vapply(inputs,hash,"")))
save(data.frame(arquivo=inputs,sha256=hashes),"fontes")
capture.output(sessionInfo(),file=file.path(out,"ambiente.txt"))
jsonlite::write_json(list(status="SENSIBILIDADE_DOCUMENTAL_EXPLORATORIA",ano=2019,
 regra="Retirar apenas Conselheiro Pena-CISVI; manter Sao Francisco de Paula-CISMARG",
 linha_retirada_nao_e_zero=TRUE,modelos=4,validacoes=2,
 limites=c("Nao confirma filiacao juridica nem elegibilidade de todas as alternativas",
 "SICOM pode compartilhar origem com MIDES; nao comprova beneficiario bancario",
 "Neves/2014 nao altera o exercicio transversal de 2019")),
 file.path(out,"resumo.json"),auto_unbox=TRUE,pretty=TRUE)
print(bind_rows(metrics),row.names=FALSE)
