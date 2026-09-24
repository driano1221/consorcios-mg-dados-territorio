# Executar da pasta do modelo. GLM binomial por par; nao altera v1 nem piloto.
suppressPackageStartupMessages(library(dplyr))
invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8"))
out <- "outputs/adesao_financeira"
dir.create(out, recursive=TRUE, showWarnings=FALSE)
inputs <- c("outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv",
 "outputs/cenarios_adesao/rotas_por_ponto_2019.csv", "outputs/visuais_v1/dados/visuais.json")
hash <- function(p) digest::digest(file=p,algo="sha256")
hashes <- vapply(inputs,hash,"")
read <- function(p) read.csv(p,fileEncoding="UTF-8-BOM",
 colClasses=c(id_municipio="character",cnpj_raiz_8="character"))
save <- function(d,n) write.csv(d,file.path(out,paste0(n,".csv")),row.names=FALSE,na="",fileEncoding="UTF-8")
g <- read(inputs[1])
stopifnot(nrow(g)==186807, !anyDuplicated(g[c("cenario","id_municipio","cnpj_raiz_8")]))
ids <- sort(unique(g$id_municipio))
set.seed(24092026)
folds <- data.frame(id_municipio=ids,municipios=sample(rep(1:5,length.out=length(ids))))
# Reutiliza os centroides da visualizacao; geografia apenas, sem pagamentos.
geo <- jsonlite::read_json(inputs[3],simplifyVector=FALSE)$polys
xy <- do.call(rbind,lapply(geo,function(z) data.frame(code=z$code,x=z$x,y=z$y)))
xy <- xy[match(substr(ids,1,6),xy$code),c("x","y")]
stopifnot(nrow(folds)==853,!anyNA(xy))
set.seed(24092026)
folds$espacial <- kmeans(as.matrix(xy),centers=5,nstart=30)$cluster
folds$x <- xy$x; folds$y <- xy$y
g <- left_join(g,folds,by="id_municipio",relationship="many-to-one")
routes <- read(inputs[2]) |> filter(cenario=="S1_unidades",horas_base>0)
alternative <- routes |> summarise(
 L05=sum(peso_horas*log1p(distancia_km/.5)),
 L5=sum(peso_horas*log1p(distancia_km/5)),.by=c(id_municipio,cnpj_raiz_8))
g <- left_join(g,alternative,by=c("id_municipio","cnpj_raiz_8"),relationship="many-to-one")

# Onze especificacoes iniciais; teste intramunicipal acrescentado apos diagnostico.
# Nao ha busca automatica de especificacao nem substituicao silenciosa da principal.
specs <- data.frame(
 modelo=c("clinicas53","sedes53","sedes62","misto62","tempo53","dref05_53",
  "dref5_53","minimo53","zero54","sem_alertas51","sem_horas53","intramunicipal53"),
 cenario=c("S1_unidades","S2_sedes","S2_sedes","S3_misto",rep("S1_unidades",8)),
 regra=c("amostra_comum","amostra_comum",rep("pre_elegivel_horas_positivas",2),
  rep("amostra_comum",4),"pre_elegivel_cadastral","sem_alertas",rep("amostra_comum",2)),
 impedancia=c(rep("impedancia_log_km_horas",4),"impedancia_log_min_horas","L05","L5",
  "minima","zero",rep("impedancia_log_km_horas",3)),
 massa=c(rep("log_horas_positivas",8),"log1p_horas_sensibilidade",rep("log_horas_positivas",3)),
 espacial=c(rep(TRUE,4),rep(FALSE,7),TRUE),
 etapa=c(rep("planejada",11),"exploratoria_apos_erros_distancia_zero"))
fit <- function(d,formula) {
 r <- glm(formula,data=d,family=binomial(),na.action=na.fail,
  control=glm.control(epsilon=1e-13,maxit=100),x=TRUE,y=TRUE)
 stopifnot(r$converged,!r$boundary,all(is.finite(coef(r))),
  r$rank==ncol(r$x),max(abs(crossprod(r$x,r$y-fitted(r))))/nrow(d)<1e-8)
 r
}
score <- function(y,p) {
 stopifnot(all(is.finite(p)),all(p>0 & p<1),sum(y)>0,sum(y)<length(y))
 o <- order(p,decreasing=TRUE); yy <- y[o]; pp <- p[o]
 ends <- c(which(diff(pp)!=0),length(pp))
 tp <- cumsum(yy)[ends]; precision <- tp/ends
 ap <- sum(diff(c(0,tp))*precision)/sum(y)
 auc <- (sum(rank(p)[y==1])-sum(y)*(sum(y)+1)/2)/(sum(y)*sum(y==0))
 c(logloss=-mean(y*log(p)+(1-y)*log1p(-p)),brier=mean((y-p)^2),
  average_precision=ap,roc_auc=auc,prevalencia=mean(y),prob_media=mean(p))
}
coefs <- diagnostics <- pred <- metrics <- calibration <- fold_coefs <- samples <- list()
fits <- list()
for (i in seq_len(nrow(specs))) {
 s <- specs[i,]; d <- g |> filter(cenario==s$cenario)
 keep <- if(s$regra=="sem_alertas") d$amostra_comum & !d$alerta_temporal else d[[s$regra]]
 d <- d[keep,] |> arrange(id_municipio,cnpj_raiz_8)
 d$log_horas <- d[[s$massa]]
 d$impedancia <- if(s$impedancia=="minima") log1p(d$distancia_min_km) else if(s$impedancia=="zero") {
  # CISVAS tem exatamente um destino, logo a impedancia independe do peso.
  stopifnot(all(d$n_pontos[d$horas_base==0]==1))
  ifelse(d$horas_base==0,log1p(d$distancia_min_km),d$impedancia_log_km_horas)
 } else d[[s$impedancia]]
 d$mesmo_municipio_destino <- as.integer(d$distancia_min_km==0)
 formula <- if(s$modelo=="intramunicipal53")
  adesao_financeira ~ log_populacao + log_horas + impedancia + mesmo_municipio_destino else
  if(s$modelo=="sem_horas53") adesao_financeira ~ log_populacao + impedancia else
  adesao_financeira ~ log_populacao + log_horas + impedancia
 stopifnot(n_distinct(d$id_municipio)==853,nrow(d)==853*n_distinct(d$cnpj_raiz_8),
  !anyNA(d[c("log_populacao","log_horas","impedancia","adesao_financeira")]))
 r <- fit(d,formula); fits[[s$modelo]] <- r
 # Duas dimensoes de agrupamento; intersecoes sao pares unicos (multi0).
 V <- sandwich::vcovCL(r,cluster=d[c("id_municipio","cnpj_raiz_8")],
  type="HC1",cadjust=TRUE,multi0=TRUE,fix=FALSE)
 stopifnot(all(diag(V)>0))
 se <- sqrt(diag(V)); b <- coef(r)
 coefs[[i]] <- data.frame(modelo=s$modelo,termo=names(b),coeficiente=unname(b),
  erro_cluster_duplo=se,ic95_inf=b-qnorm(.975)*se,ic95_sup=b+qnorm(.975)*se,row.names=NULL)
 diagnostics[[i]] <- data.frame(modelo=s$modelo,convergiu=r$converged,iteracoes=r$iter,
  gradiente_max=max(abs(crossprod(r$x,r$y-fitted(r))))/nrow(d),
  menor_autovalor_cov=min(eigen(V,symmetric=TRUE,only.values=TRUE)$values),
  condicao_X=kappa(r$x),min_prob=min(fitted(r)),max_prob=max(fitted(r)),
  grupos_municipios=n_distinct(d$id_municipio),grupos_consorcios=n_distinct(d$cnpj_raiz_8))
 samples[[i]] <- data.frame(modelo=s$modelo,linhas=nrow(d),consorcios=n_distinct(d$cnpj_raiz_8),
  municipios=n_distinct(d$id_municipio),positivos=sum(d$adesao_financeira),
  zeros=sum(d$adesao_financeira==0),valor=sum(d$valor_total),
  municipios_sem_vinculo=sum(tapply(d$adesao_financeira,d$id_municipio,sum)==0))
 for (scheme in c("municipios",if(s$espacial) "espacial")) {
  p <- base <- freq <- rep(NA_real_,nrow(d))
  for (k in 1:5) {
   test <- d[[scheme]]==k; train <- !test
   cv <- fit(d[train,],formula)
   p[test] <- predict(cv,newdata=d[test,],type="response")
   base[test] <- mean(d$adesao_financeira[train])
   rates <- d[train,] |> summarise(p=(sum(adesao_financeira)+.5)/(n()+1),.by=cnpj_raiz_8)
   freq[test] <- rates$p[match(d$cnpj_raiz_8[test],rates$cnpj_raiz_8)]
   fold_coefs[[length(fold_coefs)+1]] <- data.frame(modelo=s$modelo,validacao=scheme,fold=k,
    termo=names(coef(cv)),coeficiente=unname(coef(cv)),
    municipios_treino=n_distinct(d$id_municipio[train]),municipios_teste=n_distinct(d$id_municipio[test]))
  }
  result <- d |> select(id_municipio,municipio,cnpj_raiz_8,entidade,valor_total,
   adesao_financeira,log_populacao,log_horas,impedancia,horas_base,origem_horas,alerta_temporal,
   mesmo_municipio_destino)
  result$modelo <- s$modelo; result$validacao <- scheme; result$fold <- d[[scheme]]
  result$prob_ajuste <- fitted(r); result$prob_validacao <- p
  result$prob_prevalencia <- base; result$prob_frequencia_consorcio <- freq
  pred[[length(pred)+1]] <- result
  for (ref in c("modelo","prevalencia","frequencia_consorcio")) {
   probs <- switch(ref,modelo=p,prevalencia=base,frequencia_consorcio=freq)
   for (k in 0:5) {
    ix <- if(k==0) rep(TRUE,nrow(d)) else d[[scheme]]==k
    metrics[[length(metrics)+1]] <- data.frame(modelo=s$modelo,validacao=scheme,
     referencia=ref,fold=k,n=sum(ix),as.list(score(d$adesao_financeira[ix],probs[ix])))
   }
  }
  calibration[[length(calibration)+1]] <- data.frame(y=d$adesao_financeira,p=p) |>
   mutate(faixa=cut(p,c(0,.01,.025,.05,.1,.2,.4,.6,.8,1),include.lowest=TRUE)) |>
   summarise(n=n(),positivos=sum(y),prob_media=mean(p),fracao_observada=mean(y),.by=faixa) |>
   mutate(modelo=s$modelo,validacao=scheme)
 }
 cat(s$modelo,":",nrow(d),"pares,",sum(d$adesao_financeira),"positivos; OK\n")
}
pred <- bind_rows(pred); metrics <- bind_rows(metrics)
save(specs,"especificacoes"); save(folds,"grupos_validacao")
save(bind_rows(samples),"amostras"); save(bind_rows(coefs),"coeficientes")
save(bind_rows(diagnostics),"diagnosticos"); save(bind_rows(fold_coefs),"coeficientes_validacao")
save(metrics,"validacao"); save(bind_rows(calibration),"calibracao")
con <- gzfile(file.path(out,"previsoes.csv.gz"),"wt",encoding="UTF-8")
write.csv(pred,con,row.names=FALSE,na=""); close(con)
save(pred |> filter(id_municipio %in% c("3130101","3117603"),
 modelo %in% c("clinicas53","sedes53","sedes62","misto62","intramunicipal53")),"exemplos")
save(pred |> group_by(modelo,validacao,id_municipio,municipio) |>
 summarise(vinculos_observados=sum(adesao_financeira),vinculos_esperados=sum(prob_validacao),
  .groups="drop"),"vinculos_municipais")
save(pred |> group_by(modelo,validacao,origem_horas) |>
 summarise(n=n(),positivos=sum(adesao_financeira),observado=mean(adesao_financeira),
  previsto=mean(prob_validacao),logloss=-mean(adesao_financeira*log(prob_validacao)+
  (1-adesao_financeira)*log1p(-prob_validacao)),.groups="drop"),"resultados_modalidade")
save(pred |> filter(modelo %in% c("clinicas53","intramunicipal53")) |>
 group_by(modelo,validacao,mesmo_municipio_destino) |>
 summarise(n=n(),positivos=sum(adesao_financeira),observado=mean(adesao_financeira),
  previsto=mean(prob_validacao),logloss=-mean(adesao_financeira*log(prob_validacao)+
  (1-adesao_financeira)*log1p(-prob_validacao)),.groups="drop"),"diagnostico_intramunicipal")
save(pred |> filter(modelo=="clinicas53",validacao=="municipios") |>
 mutate(erro=abs(adesao_financeira-prob_validacao)) |> arrange(desc(erro)) |> head(30),"maiores_erros")
saveRDS(fits,file.path(out,"ajustes.rds"))
stopifnot(identical(hashes,vapply(inputs,hash,"")))
save(data.frame(arquivo=inputs,sha256=hashes),"fontes")
capture.output(sessionInfo(),file=file.path(out,"ambiente.txt"))
jsonlite::write_json(list(status="ESTIMADO_EXPLORATORIO",ano=2019,seed=24092026,
 modelos=nrow(specs),linhas_previsoes=nrow(pred),
 limites=c("Vinculo financeiro, nao filiacao juridica nem entrada",
 "Candidatos estaduais sem acesso institucional comprovado",
 "Sedes sem vigencia historica validada; modalidades nao clinicas exploratorias",
 "Validacao em municipios retidos, nao em outros anos ou consorcios",
 "IC95 assintotico com agrupamento municipio e consorcio; nao causal")),
 file.path(out,"resumo.json"),auto_unbox=TRUE,pretty=TRUE)
products <- list.files(out,full.names=TRUE)
products <- products[basename(products)!="manifesto_produtos.csv"]
save(data.frame(arquivo=basename(products),sha256=vapply(products,hash,"")),"manifesto_produtos")
print(metrics |> filter(fold==0,referencia=="modelo"),row.names=FALSE)
