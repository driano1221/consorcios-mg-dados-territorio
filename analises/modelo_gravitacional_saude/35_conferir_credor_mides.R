# Auditoria de nomes sem substituir CNPJ ou deduplicar pagamentos.
# --consultar baixa apenas agregado por nome/documento/municipio/ano; teto 10 GB.
suppressPackageStartupMessages(library(dplyr))
invisible(Sys.setlocale("LC_ALL","Portuguese_Brazil.utf8"))
out<-"outputs/auditoria_alternativas"
cache<-file.path(out,"credores_complementares_2014_2021.csv")
read<-function(p) read.csv(p,fileEncoding="UTF-8-BOM",colClasses=c(
 id_municipio="character",cnpj_raiz_8="character",documento_credor="character"))
save<-function(d,n) write.csv(d,file.path(out,paste0(n,".csv")),row.names=FALSE,na="",fileEncoding="UTF-8")
extra<-read("outputs/fronteira_mides_complementar.csv")
roots<-sort(unique(substr(extra$documento_credor,1,8)))
sql<-paste0("SELECT ano,id_municipio,documento_credor,nome_credor,",
 "SUM(valor_final) AS valor_total,COUNT(*) AS n_transacoes ",
 "FROM `basedosdados.world_wb_mides.pagamento` WHERE sigla_uf='MG' ",
 "AND ano BETWEEN 2014 AND 2021 AND LENGTH(documento_credor)=14 ",
 "AND SUBSTR(documento_credor,1,8) IN ('",paste(roots,collapse="','"),"') ",
 "GROUP BY ano,id_municipio,documento_credor,nome_credor")
writeLines(sql,file.path(out,"consulta_credores_complementares.sql"))
if("--consultar" %in% commandArgs(TRUE)) {
 bigrquery::bq_auth(email=TRUE)
 # O limite precisa estar dentro de configuration.query na API Jobs.
 job<-bigrquery::bq_perform_query(sql,billing=Sys.getenv("MIDES_BILLING_ID","ipea-consorcios"),
  configuration=list(query=list(maximumBytesBilled=jsonlite::unbox("10000000000"))))
 bigrquery::bq_job_wait(job,quiet=TRUE);m<-bigrquery::bq_job_meta(job)
 dest<-m$configuration$query$destinationTable
 d<-bigrquery::bq_table_download(bigrquery::bq_table(dest$projectId,dest$datasetId,dest$tableId),quiet=TRUE)
 save(d,"credores_complementares_2014_2021")
 stopifnot(m$configuration$query$maximumBytesBilled=="10000000000")
 jsonlite::write_json(list(job=unclass(job),statistics=m$statistics,status=m$status,
  maximumBytesBilled=m$configuration$query$maximumBytesBilled,
  consulta_utc=format(Sys.time(),tz="UTC"),sha256=digest::digest(file=cache,algo="sha256")),
  file.path(out,"consulta_credores_manifesto.json"),pretty=TRUE,auto_unbox=TRUE)
}
stopifnot(file.exists(cache))
fresh<-read(cache)
# Consulta de nomes precisa reproduzir os agregados ja usados, sem revisar montantes silenciosamente.
cmp<-full_join(extra |> rename(valor_anterior=valor_total,n_anterior=n_transacoes),
 fresh |> summarise(valor_novo=sum(valor_total),n_novo=sum(n_transacoes),
 .by=c(ano,id_municipio,documento_credor)),by=c("ano","id_municipio","documento_credor"),relationship="one-to-one")
stopifnot(!anyNA(cmp),max(abs(cmp$valor_anterior-cmp$valor_novo))<1e-6,all(cmp$n_anterior==cmp$n_novo))
raw<-readRDS("../../dados/bruto/mides_mg_atualizado.rds") |>
 summarise(valor_total=sum(valor_final),n_transacoes=n(),.by=c(ano,id_municipio,documento_credor,nome_credor))
financial<-read("outputs/base_v1/base_financeira_v1.csv")
names_all<-bind_rows(mutate(raw,extracao="original"),mutate(fresh,extracao="complementar")) |>
 mutate(cnpj_raiz_8=substr(documento_credor,1,8)) |>
 semi_join(financial,by=c("ano","id_municipio","cnpj_raiz_8")) |>
 mutate(nome_normalizado=toupper(iconv(nome_credor,to="ASCII//TRANSLIT")),
  # Nomes inspecionados no catalogo: entidades explicitamente distintas.
  # Nome generico nao basta para declarar CNPJ errado.
  conflito_nome_documento=grepl("MINISTERIO DA FAZENDA|RECEITA FEDERAL|SOMETAL|EMIVE PATRULHA",nome_normalizado),
  nome_generico=nome_normalizado %in% c("0","CREDOR","MATRIZ","FOLHA DE PAGAMENTO") |
   grepl("^[0-9]+$",nome_normalizado))
save(names_all,"nomes_credores_financeira_v1")
conflicts<-names_all |> filter(conflito_nome_documento) |>
 summarise(nomes=paste(sort(unique(nome_credor)),collapse=" | "),
 valor_conflitante=sum(valor_total),transacoes_conflitantes=sum(n_transacoes),
 .by=c(ano,id_municipio,cnpj_raiz_8)) |>
 left_join(financial |> select(ano,id_municipio,municipio,cnpj_raiz_8,entidade,valor_total,n_transacoes),
 by=c("ano","id_municipio","cnpj_raiz_8"),relationship="one-to-one") |>
 mutate(decisao="conflito_nome_documento; nao converter em zero; sensibilidade sem o par")
save(conflicts,"conflitos_nome_documento")
save(names_all |> summarise(valor=sum(valor_total),transacoes=sum(n_transacoes),
 .by=c(cnpj_raiz_8,nome_credor,conflito_nome_documento,nome_generico)) |>
 arrange(cnpj_raiz_8,desc(valor)),"catalogo_nomes_credores")
save(data.frame(arquivo=c(cache,"../../dados/bruto/mides_mg_atualizado.rds","outputs/fronteira_mides_complementar.csv"),
 sha256=vapply(c(cache,"../../dados/bruto/mides_mg_atualizado.rds","outputs/fronteira_mides_complementar.csv"),
 function(p) digest::digest(file=p,algo="sha256"),"")),"fontes_credores")
print(conflicts,width=Inf)
