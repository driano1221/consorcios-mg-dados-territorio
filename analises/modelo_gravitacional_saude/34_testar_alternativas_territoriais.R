# Auditoria financeira e sensibilidades territoriais. Executar apos 33 -> 31 -> 32.
# Regras geograficas nao usam pagamento; nao representam filiacao ou elegibilidade legal.
suppressPackageStartupMessages(library(dplyr))
invisible(Sys.setlocale("LC_ALL","Portuguese_Brazil.utf8"))
out <- "outputs/auditoria_alternativas"
dir.create(out,recursive=TRUE,showWarnings=FALSE)
read <- function(p) read.csv(p,fileEncoding="UTF-8-BOM",colClasses=c(
 id_municipio="character",cnpj_raiz_8="character",id_destino="character",
 codigo_ibge_6="character",cod_ibge_6="character",documento_credor="character"))
save <- function(d,n) write.csv(d,file.path(out,paste0(n,".csv")),
 row.names=FALSE,na="",fileEncoding="UTF-8")
inputs <- c("outputs/cenarios_adesao/grade_candidata_cenarios_2019.csv",
 "outputs/cenarios_adesao/rotas_por_ponto_2019.csv",
 "outputs/regionalizacao_saude_mg_pdr_2019.csv",
 "outputs/adesao_financeira/previsoes.csv.gz","outputs/adesao_financeira/grupos_validacao.csv",
 "../../dados/bruto/mides_mg_atualizado.rds","outputs/fronteira_mides_complementar.csv",
 "outputs/cotejamento_mides_munic_saude_mg_2019.csv",
 "outputs/auditoria_alternativas/conflitos_nome_documento.csv")
hash <- function(p) digest::digest(file=p,algo="sha256")
hashes <- vapply(inputs,hash,"")
g <- read(inputs[1]); routes <- read(inputs[2]); regions <- read(inputs[3])
p <- read(inputs[4]); folds <- read(inputs[5])
conflicts <- read(inputs[9]) |> filter(ano==2019) |>
 select(id_municipio,cnpj_raiz_8) |> mutate(conflito_nome_documento=TRUE)
stopifnot(nrow(regions)==853,!anyDuplicated(regions$codigo_ibge_6))
f <- g |> filter(cenario=="S1_unidades")
raw <- readRDS(inputs[6]) |> mutate(cnpj_raiz_8=substr(documento_credor,1,8))
extra <- read(inputs[7]) |> mutate(cnpj_raiz_8=substr(documento_credor,1,8))
stopifnot(length(intersect(unique(raw$cnpj_raiz_8),unique(extra$cnpj_raiz_8)))==0)
raw19 <- raw |> filter(ano==2019,cnpj_raiz_8 %in% f$cnpj_raiz_8)
extra19 <- extra |> filter(ano==2019,cnpj_raiz_8 %in% f$cnpj_raiz_8)
stopifnot(!anyNA(raw19$valor_final),!anyNA(extra19$valor_total))
reconstructed <- bind_rows(
 raw19 |> summarise(valor_fonte=sum(valor_final),transacoes_fonte=n(),
  negativos=sum(valor_final<0),fonte="MIDES_original_por_cnpj",
  .by=c(id_municipio,cnpj_raiz_8)),
 extra19 |> summarise(valor_fonte=sum(valor_total),transacoes_fonte=sum(n_transacoes),
  negativos=NA_integer_,fonte="MIDES_complementar_por_raiz",
  .by=c(id_municipio,cnpj_raiz_8)))
reconciliation <- f |> select(id_municipio,municipio,cnpj_raiz_8,entidade,valor_total,n_transacoes,
 tem_registro_mides,adesao_financeira) |> left_join(reconstructed,
 by=c("id_municipio","cnpj_raiz_8"),relationship="one-to-one") |>
 mutate(registro_na_fonte=!is.na(transacoes_fonte),
  valor_fonte=coalesce(valor_fonte,0),transacoes_fonte=coalesce(transacoes_fonte,0L),
  diferenca=valor_total-valor_fonte)
stopifnot(nrow(reconciliation)==62269, max(abs(reconciliation$diferenca))<1e-6,
 all(reconciliation$n_transacoes==reconciliation$transacoes_fonte),
 all(reconciliation$tem_registro_mides==reconciliation$registro_na_fonte))
save(reconciliation,"conciliacao_financeira_2019")
save(data.frame(linhas_brutas_2019=nrow(raw19),valores_negativos=sum(raw19$valor_final<0),
 valores_nulos=sum(is.na(raw19$valor_final)),datas_fora_ano=sum(format(raw19$data,"%Y")!="2019",na.rm=TRUE),
 pares_conciliados=nrow(reconciliation),max_diferenca=max(abs(reconciliation$diferenca)),
 pares_zero_sem_registro=sum(reconciliation$valor_total==0 & !reconciliation$registro_na_fonte),
 pares_zero_com_registro=sum(reconciliation$valor_total==0 & reconciliation$registro_na_fonte)),"resumo_conciliacao")

# Regiao da origem comparada a cada destino efetivo, nao apenas a sede do consorcio.
rr <- routes |> mutate(origem6=substr(id_municipio,1,6),destino6=substr(id_destino,1,6)) |>
 left_join(regions |> rename(origem6=codigo_ibge_6,macro_o=macro_saude_2019,micro_o=micro_saude_2019),by="origem6") |>
 left_join(regions |> rename(destino6=codigo_ibge_6,macro_d=macro_saude_2019,micro_d=micro_saude_2019),by="destino6")
stopifnot(!anyNA(rr[c("macro_o","micro_o","macro_d","micro_d")]))
territory <- rr |> summarise(mesma_macro=any(macro_o==macro_d),mesma_micro=any(micro_o==micro_d),
 .by=c(cenario,id_municipio,cnpj_raiz_8))
g <- left_join(g,territory,by=c("cenario","id_municipio","cnpj_raiz_8"),relationship="one-to-one") |>
 left_join(folds,by="id_municipio",relationship="many-to-one") |>
 left_join(conflicts,by=c("id_municipio","cnpj_raiz_8"),relationship="many-to-one") |>
 mutate(conflito_nome_documento=coalesce(conflito_nome_documento,FALSE))
specs <- data.frame(modelo=c("clinicas53","sedes53","sedes62","misto62"),
 cenario=c("S1_unidades","S2_sedes","S2_sedes","S3_misto"),
 regra=c("amostra_comum","amostra_comum","pre_elegivel_horas_positivas","pre_elegivel_horas_positivas"))
# Fixadas antes de examinar metricas: thresholds sao sensibilidades, nao limites normativos.
rules <- c("estadual","ate90min","ate120min","ate180min","mesma_macro","mesma_micro","cinco_proximos",
 "sem_conflito_credor")
fit <- function(d) {
 r <- glm(adesao_financeira ~ log_populacao+log_horas_positivas+impedancia_log_km_horas,
  data=d,family=binomial(),na.action=na.fail,control=glm.control(epsilon=1e-11,maxit=200),x=TRUE,y=TRUE)
 stopifnot(r$converged,!r$boundary,r$rank==4,all(is.finite(coef(r))),
  max(abs(crossprod(r$x,r$y-fitted(r))))/nrow(d)<1e-8)
 r
}
score <- function(y,p) {
 stopifnot(length(y)==length(p),all(is.finite(p)),all(p>=0 & p<=1))
 q <- pmax(1e-15,pmin(1-1e-15,p)); n1 <- sum(y)
 ap <- auc <- NA_real_
 if(n1>0 && n1<length(y)) {
  o<-order(p,decreasing=TRUE);yy<-y[o];pp<-p[o]
  ends<-c(which(diff(pp)!=0),length(pp));tp<-cumsum(yy)[ends]
  ap<-sum(diff(c(0,tp))*tp/ends)/n1
  auc<-(sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*sum(y==0))
 }
 c(logloss=-mean(y*log(q)+(1-y)*log1p(-q)),brier=mean((y-p)^2),
   average_precision=ap,roc_auc=auc,prevalencia=mean(y),prob_media=mean(p))
}
metrics<-predictions<-samples<-exclusions<-coefficients<-bands<-rules_by_pair<-list()
for(i in seq_len(nrow(specs))) {
 s<-specs[i,];d<-g |> filter(cenario==s$cenario,.data[[s$regra]]) |>
  arrange(id_municipio,cnpj_raiz_8) |> group_by(id_municipio) |>
  mutate(ordem_tempo=min_rank(tempo_minimo_min)) |> ungroup()
 d$estadual<-TRUE;d$ate90min<-d$tempo_minimo_min<=90;d$ate120min<-d$tempo_minimo_min<=120
 d$ate180min<-d$tempo_minimo_min<=180;d$cinco_proximos<-d$ordem_tempo<=5
 # Teste documental separado das sete regras geograficas; retira linha, nao recodifica y.
 d$sem_conflito_credor<-!d$conflito_nome_documento
 stopifnot(!anyNA(d[rules]))
 rules_by_pair[[i]]<-d |> select(id_municipio,cnpj_raiz_8,tempo_minimo_min,mesma_macro,mesma_micro,
  ordem_tempo,all_of(rules)) |> mutate(modelo=s$modelo)
 for(rule in rules) {
  a<-d[d[[rule]],];lost<-d[!d[[rule]] & d$adesao_financeira==1,]
  counts<-table(factor(a$id_municipio,levels=folds$id_municipio))
  samples[[length(samples)+1]]<-data.frame(modelo=s$modelo,regra=rule,pares=nrow(a),
   municipios=n_distinct(a$id_municipio),sem_candidato=sum(counts==0),
   alternativas_min=min(counts),alternativas_mediana=median(as.numeric(counts)),alternativas_max=max(counts),
   positivos=sum(a$adesao_financeira),positivos_total=sum(d$adesao_financeira),
   positivos_excluidos=nrow(lost),valor_retido=sum(a$valor_total),valor_excluido=sum(lost$valor_total),
   fracao_positivos=sum(a$adesao_financeira)/sum(d$adesao_financeira),
   fracao_valor=sum(a$valor_total)/sum(d$valor_total))
  exclusions[[length(exclusions)+1]]<-lost |> select(id_municipio,municipio,cnpj_raiz_8,entidade,
   valor_total,tempo_minimo_min) |> mutate(modelo=s$modelo,regra=rule)
  for(scheme in c("municipios","espacial")) {
   q<-p |> filter(modelo==s$modelo,validacao==scheme) |>
    select(id_municipio,cnpj_raiz_8,prob_estadual=prob_validacao)
   a2<-left_join(a,q,by=c("id_municipio","cnpj_raiz_8"),relationship="one-to-one")
   a2$prob_reajustada<-a2$prob_prevalencia<-NA_real_
   a2$fold<-a2[[scheme]]
   for(k in 1:5) {
    train<-a2 |> filter(fold!=k); ix<-which(a2$fold==k)
    stopifnot(length(intersect(train$id_municipio,a2$id_municipio[ix]))==0)
    r<-fit(train);a2$prob_reajustada[ix]<-predict(r,a2[ix,],type="response")
    a2$prob_prevalencia[ix]<-mean(train$adesao_financeira)
    coefficients[[length(coefficients)+1]]<-data.frame(modelo=s$modelo,regra=rule,validacao=scheme,
     fold=k,termo=names(coef(r)),coeficiente=unname(coef(r)),n_treino=nrow(train),positivos_treino=sum(train$adesao_financeira))
   }
   for(version in c("prob_estadual","prob_reajustada","prob_prevalencia")) {
    for(k in 0:5) {
     z<-if(k==0) a2 else a2[a2$fold==k,]
     metrics[[length(metrics)+1]]<-cbind(data.frame(modelo=s$modelo,regra=rule,validacao=scheme,
      previsao=version,fold=k,n=nrow(z),positivos=sum(z$adesao_financeira)),
      as.data.frame(as.list(score(z$adesao_financeira,z[[version]]))))
    }
   }
   predictions[[length(predictions)+1]]<-a2 |> select(id_municipio,cnpj_raiz_8,adesao_financeira,
    valor_total,log_populacao,log_horas_positivas,impedancia_log_km_horas,fold,
    prob_estadual,prob_reajustada,prob_prevalencia) |>
    mutate(modelo=s$modelo,regra=rule,validacao=scheme)
   if(rule=="estadual") {
    a2$faixa<-cut(a2$tempo_minimo_min,c(-Inf,0,30,60,120,180,300,Inf),
     labels=c("0","(0,30]","(30,60]","(60,120]","(120,180]","(180,300]",">300"))
    for(b in levels(a2$faixa)) {
     z<-a2[a2$faixa==b,]
     if(nrow(z)) bands[[length(bands)+1]]<-cbind(data.frame(modelo=s$modelo,validacao=scheme,
      faixa_min=b,pares=nrow(z),positivos=sum(z$adesao_financeira),valor=sum(z$valor_total)),
      as.data.frame(as.list(score(z$adesao_financeira,z$prob_estadual))))
    }
   }
  }
  cat(s$modelo,rule,'concluido\n')
 }
}
save(bind_rows(samples),"cobertura_regras")
save(bind_rows(exclusions),"pagamentos_excluidos_por_regra")
save(bind_rows(metrics),"validacao_territorial")
save(bind_rows(coefficients),"coeficientes_treino_territorial")
save(bind_rows(bands),"diagnostico_faixas_tempo")
save(bind_rows(rules_by_pair),"regras_por_par")
con<-gzfile(file.path(out,"previsoes_territoriais.csv.gz"),"wt",encoding="UTF-8")
write.csv(bind_rows(predictions),con,row.names=FALSE,na="");close(con)

# Maiores erros previamente selecionados: preserva criterio/top 30, nao apaga zeros documentados.
errors<-read("outputs/adesao_financeira/maiores_erros.csv")
munic<-read(inputs[8]) |> select(cod_ibge_6,cnpj_raiz_8,tem_munic_2019)
audit_errors<-errors |> mutate(cod_ibge_6=substr(id_municipio,1,6)) |>
 left_join(reconciliation |> select(id_municipio,cnpj_raiz_8,registro_na_fonte,valor_fonte,
  transacoes_fonte,diferenca),by=c("id_municipio","cnpj_raiz_8"),relationship="many-to-one") |>
 left_join(munic,by=c("cod_ibge_6","cnpj_raiz_8"),relationship="many-to-one") |>
 left_join(g |> filter(cenario=="S1_unidades") |> select(id_municipio,cnpj_raiz_8,
  tempo_minimo_min,mesma_macro,mesma_micro),by=c("id_municipio","cnpj_raiz_8"),relationship="many-to-one") |>
 mutate(conclusao=case_when(id_municipio=="3170107" & cnpj_raiz_8=="09310999" ~
  "zero_confirmado_relatorio_Uberaba_2019_p80; mudanca_contrato_rateio_desde_2018",
  adesao_financeira==0 ~ "zero_conciliado_extracao; causa_institucional_ainda_nao_comprovada",
  id_municipio=="3118403" & cnpj_raiz_8=="00639952" ~
   "conflito_nome_MINISTERIO_DA_FAZENDA_documento_CISVI; pagamento_nao_validado_como_consorcial",
  TRUE ~ "pagamento_conciliado; destino_financiado_nao_identificado_pelo_MIDES"))
save(audit_errors,"auditoria_30_maiores_erros")
stopifnot(identical(hashes,vapply(inputs,hash,"")))
save(data.frame(arquivo=inputs,sha256=hashes),"fontes_territoriais")
capture.output(sessionInfo(),file=file.path(out,"ambiente_R.txt"))
cat('OK: conciliacao financeira; 28 combinacoes territoriais e 4 documentais; duas validacoes cada.\n')
