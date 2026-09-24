# Executar nesta pasta: Rscript 30_estimar_piloto_participacoes.R
# Media fracional normalizada; uma distribuicao por municipio, peso igual.
suppressPackageStartupMessages(library(dplyr))
if (.Platform$OS.type == "windows") Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
out <- "outputs/piloto_participacoes"
dir.create(out, recursive=TRUE, showWarnings=FALSE)
inputs <- c("outputs/base_v1/base_gravitacional_v1.rds",
  "outputs/base_v1/base_financeira_v1.rds", "outputs/base_v1/inclusao_entidade_ano.csv",
  "outputs/visuais_v1/dados/visuais.json")
hashes <- vapply(inputs, function(p) digest::digest(file=p,algo="sha256"), "")
g <- readRDS(inputs[1]) |> filter(ano==2019) |> arrange(id_municipio,cnpj_raiz_8)
f <- readRDS(inputs[2]) |> filter(ano==2019)
inclusion <- read.csv(inputs[3], colClasses="character",fileEncoding="UTF-8-BOM") |>
  filter(ano=="2019")
stopifnot(nrow(g)==46062, !anyNA(g), !anyDuplicated(g[c("id_municipio","cnpj_raiz_8")]))
total <- g |> group_by(id_municipio) |> summarise(total_direto=sum(valor_total),.groups="drop")
g <- g |> left_join(total,by="id_municipio",relationship="many-to-one") |>
  filter(total_direto>0) |> mutate(participacao=valor_total/total_direto,
    log_profissionais=log1p(profissionais_sus_clinicos_soma_unidades),
    tempo_horas=tempo_minimo_min/60)
ids <- unique(g$id_municipio); roots <- unique(g$cnpj_raiz_8)
n <- length(ids); j <- length(roots)
stopifnot(n==703, j==54, nrow(g)==n*j, sum(g$valor_total>0)==781)
mat <- function(x) matrix(x,nrow=n,ncol=j,byrow=TRUE)
Y <- mat(g$participacao)
X <- list(capacidade=mat(g$log_profissionais),tempo=-mat(g$tempo_horas))
stopifnot(max(abs(rowSums(Y)-1))<1e-12)

logprob <- function(b,x) {
  v <- Reduce(`+`, Map(function(z,a) z*a,x,b))
  z <- v-apply(v,1,max)
  z-log(rowSums(exp(z)))
}
loss <- function(b,x,y) -mean(rowSums(y*logprob(b,x)))
gradient <- function(b,x,y) {
  delta <- exp(logprob(b,x))-y
  vapply(x,function(z) mean(rowSums(delta*z)),0)
}
fit <- function(x,y) {
  r <- optim(rep(0,length(x)),loss,gradient,x=x,y=y,method="BFGS",
    control=list(maxit=1000,reltol=1e-12))
  stopifnot(r$convergence==0,all(is.finite(r$par)),max(abs(gradient(r$par,x,y)))<1e-5)
  names(r$par) <- names(x)
  r
}
# O gradiente analitico deve coincidir com diferencas finitas.
b0 <- c(.4,.7); eps <- 1e-6
numeric_grad <- vapply(seq_along(b0),function(k) {
  plus <- minus <- b0; plus[k] <- plus[k]+eps; minus[k] <- minus[k]-eps
  (loss(plus,X,Y)-loss(minus,X,Y))/(2*eps)
},0)
stopifnot(max(abs(numeric_grad-gradient(b0,X,Y)))<1e-6)
# Recuperacao em distribuicoes sinteticas conhecidas, com a mesma matriz X.
recovery <- fit(X,exp(logprob(b0,X)))
stopifnot(max(abs(recovery$par-b0))<1e-4)

specs <- list(tempo=X["tempo"],profissionais_tempo=X,
  horas_tempo=list(capacidade=mat(log1p(g$horas_sus_clinicas_soma_registros)),tempo=X$tempo),
  profissionais_mediana=list(capacidade=X$capacidade,tempo=-mat(g$tempo_mediano_min/60)))
fits <- lapply(specs,fit,y=Y)
set.seed(24092026)
fold <- sample(rep(1:5,length.out=n))
# Sensibilidade espacial: cinco grupos compactos, somente coordenadas, sem Y.
geo <- jsonlite::read_json(inputs[4],simplifyVector=FALSE)$polys
coords <- do.call(rbind,lapply(geo,function(p) data.frame(code=p$code,x=p$x,y=p$y)))
xy <- coords[match(substr(ids,1,6),coords$code),c("x","y")]
stopifnot(!anyNA(xy))
set.seed(24092026)
spatial <- kmeans(as.matrix(xy),centers=5,nstart=30)$cluster
schemes <- list(municipios=fold,espacial=spatial)
predictions <- list(); fold_coeff <- list(); metrics <- list()
score <- function(p,y) {
  tied <- rowSums(abs(p-apply(p,1,max))<1e-12)>1
  c(entropia=-mean(rowSums(y*log(p))),
    distancia_total_pct=100*mean(rowSums(abs(y-p))/2),
    acerto_principal_pct=if(all(tied)) NA_real_ else
      100*mean(!tied & max.col(p,ties.method="first")==max.col(y,ties.method="first")))
}
for (scheme in names(schemes)) {
  folds <- schemes[[scheme]]
  for (model in c("uniforme","frequencia_treino",names(specs))) {
    p <- matrix(NA_real_,n,j)
    for (k in 1:5) {
      test <- folds==k; train <- !test
      if(model=="uniforme") p[test,] <- 1/j else if(model=="frequencia_treino") {
        # Suavizacao previa fixa: uma distribuicao uniforme adicional no treino.
        prior <- (colSums(Y[train,,drop=FALSE])+1/j)/(sum(train)+1)
        p[test,] <- matrix(prior,sum(test),j,byrow=TRUE)
      } else {
        xs <- specs[[model]]
        r <- fit(lapply(xs,function(z) z[train,,drop=FALSE]),Y[train,,drop=FALSE])
        p[test,] <- exp(logprob(r$par,lapply(xs,function(z) z[test,,drop=FALSE])))
        fold_coeff[[length(fold_coeff)+1]] <- data.frame(validacao=scheme,modelo=model,
          fold=k,n_treino=sum(train),n_teste=sum(test),termo=names(r$par),coeficiente=r$par)
      }
    }
    stopifnot(all(is.finite(p)),all(p>0),max(abs(rowSums(p)-1))<1e-10)
    predictions[[paste(scheme,model,sep="_")]] <- p
    metrics[[length(metrics)+1]] <- data.frame(validacao=scheme,modelo=model,
      as.list(score(p,Y)),row.names=NULL)
  }
}
metrics <- bind_rows(metrics)
main <- fits$profissionais_tempo
p_full <- exp(logprob(main$par,X))
p_cv <- predictions$municipios_profissionais_tempo
p_spatial <- predictions$espacial_profissionais_tempo
g <- g |> mutate(fold=rep(fold,each=j),bloco_espacial=rep(spatial,each=j),
  utilidade=as.vector(t(Reduce(`+`,Map(function(z,a)z*a,X,main$par)))),
  previsto_ajuste=as.vector(t(p_full)),previsto_validacao=as.vector(t(p_cv)),
  previsto_espacial=as.vector(t(p_spatial)))
municipal <- g |> group_by(id_municipio,municipio) |> summarise(
  total_direto=first(total_direto),n_pagos=sum(valor_total>0),fold=first(fold),
  bloco_espacial=first(bloco_espacial),alerta_temporal=any(alerta_temporal & valor_total>0),
  erro_validacao_pct=100*sum(abs(participacao-previsto_validacao))/2,.groups="drop") |>
  left_join(f |> group_by(id_municipio) |> summarise(total_financeiro=sum(valor_total),.groups="drop"),
    by="id_municipio",relationship="one-to-one")
entities <- g |> distinct(cnpj_raiz_8,entidade,profissionais_sus_clinicos_soma_unidades,
  horas_sus_clinicas_soma_registros,n_destinos_clinicos_dezembro,alerta_temporal)
coef <- bind_rows(lapply(names(fits),function(m) data.frame(modelo=m,
  termo=names(fits[[m]]$par),coeficiente=unname(fits[[m]]$par),
  convergencia=fits[[m]]$convergence,gradiente_max=max(abs(gradient(fits[[m]]$par,specs[[m]],Y))))))
# A medida de massa deve ser auditavel em quem tem registro zero.
zero_mass <- entities |> filter(profissionais_sus_clinicos_soma_unidades==0)
write_table <- function(x,name) write.csv(x,file.path(out,paste0(name,".csv")),
  row.names=FALSE,fileEncoding="UTF-8",na="")
write_table(g,"base_estimacao_2019")
write_table(municipal,"municipios_2019")
write_table(inclusion,"selecao_consorcios_2019")
write_table(metrics,"validacao")
write_table(coef,"coeficientes")
write_table(bind_rows(fold_coeff),"coeficientes_validacao")
write_table(entities,"consorcios_2019")
write_table(data.frame(arquivo=inputs,sha256=hashes),"fontes")
stopifnot(identical(hashes,vapply(inputs,function(p)digest::digest(file=p,algo="sha256"),"")))
# Objeto compacto para o HTML, todas as 54 alternativas consultaveis por municipio.
payload <- list(ano=2019,seed=24092026,coeficientes=coef,validacao=metrics,
  coeficientes_validacao=bind_rows(fold_coeff),consorcios=entities,municipios=municipal,
  selecao=inclusion,
  resumo=list(municipios=n,consorcios=j,linhas=n*j,pagos=sum(g$valor_total>0),
    valor_direto=sum(g$valor_total),valor_financeiro=sum(f$valor_total),
    pagadores_financeiros=n_distinct(f$id_municipio[f$valor_total>0]),
    municipios_um=sum(municipal$n_pagos==1),municipios_varios=sum(municipal$n_pagos>1),
    capacidade_zero=zero_mass,alertas=sum(entities$alerta_temporal),
    pares_pagos_alerta=sum(g$valor_total>0 & g$alerta_temporal)),
  colunas=c("raiz","valor","profissionais","tempo","mediana","observado","ajuste","validacao","espacial","utilidade"),
  linhas=lapply(split(g,g$id_municipio),function(z) unname(lapply(seq_len(nrow(z)),function(i)
    list(z$cnpj_raiz_8[i],z$valor_total[i],z$profissionais_sus_clinicos_soma_unidades[i],
      z$tempo_minimo_min[i],z$tempo_mediano_min[i],z$participacao[i],z$previsto_ajuste[i],
      z$previsto_validacao[i],z$previsto_espacial[i],z$utilidade[i])))))
jsonlite::write_json(payload,file.path(out,"piloto.json"),auto_unbox=TRUE,digits=12,pretty=FALSE,na="null")
cat("Piloto executado. Fontes preservadas; nenhum corte por pagamento nas alternativas.\n")
print(coef); print(metrics)
