# Executar nesta pasta. Diagnostico da proposta de um ano; nao estima modelo.
suppressPackageStartupMessages(library(dplyr))
if (.Platform$OS.type == "windows") Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8")
dest <- "outputs/viabilidade_logit"
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
inputs <- paste0("outputs/", c("base_v1/base_financeira_v1.rds",
  "base_v1/base_gravitacional_v1.rds", "base_v1/capacidade_entidade_ano.csv",
  "universo_saude_mg_entidades.csv", "revisao_fora_84_resultado.csv",
  "elegibilidade_assistencial_unidades_historicas_saude_mg_2014_2021.csv",
  "candidatas_cnes_capacidade_unidades_2014_2021.csv"))
hashes <- vapply(inputs, function(p) digest::digest(file=p, algo="sha256"), character(1))
# Mesma decodificacao usada no script 26; sem modificar os CSVs de origem.
decode <- function(x) {
  affected <- which(!is.na(x) & grepl('<U\\+',x))
  x[affected] <- vapply(x[affected], function(s) {
    hits <- gregexpr('<U\\+[0-9A-Fa-f]{4,6}>',s,perl=TRUE)
    tokens <- regmatches(s,hits)[[1]]
    if(length(tokens)) regmatches(s,hits) <- list(vapply(tokens,function(z)
      intToUtf8(strtoi(sub('>','',sub('<U\\+','',z)),16)), ''))
    s
  }, '', USE.NAMES=FALSE)
  x
}
csv <- function(p) read.csv(p, colClasses="character", fileEncoding="UTF-8-BOM") |>
  mutate(across(where(is.character),decode))
save_table <- function(x,n) write.csv(x, file.path(dest,paste0(n,".csv")),
  row.names=FALSE, na="", fileEncoding="UTF-8")
f <- readRDS(inputs[1]); g <- readRDS(inputs[2])
stopifnot(nrow(f)==491328, nrow(g)==323287,
  !anyDuplicated(f[c("id_municipio","cnpj_raiz_8","ano")]),
  all(g$valor_total>=0), !anyNA(g))
# Contagens por municipio mantem quem nao tem pagamento e todos os vinculos.
municipal <- f |> group_by(ano,id_municipio,municipio) |>
  summarise(n_pagos=sum(valor_total>0),
    n_pagos_diretos=sum(valor_total>0 & elegivel_gravitacional_v1),
    valor=sum(valor_total), valor_direto=sum(valor_total[elegivel_gravitacional_v1]),
    n_maximos=if(sum(valor_total)>0) sum(valor_total==max(valor_total)) else 0L,
    maior_no_direto=if(sum(valor_total)>0)
      all(elegivel_gravitacional_v1[valor_total==max(valor_total)]) else FALSE,
    fracao_maior=if(sum(valor_total)>0) max(valor_total)/sum(valor_total) else NA_real_,
    .groups="drop")
annual <- municipal |> group_by(ano) |>
  summarise(municipios=n(),pagadores=sum(n_pagos>0),sem_pagamento=sum(n_pagos==0),
    multipagadores=sum(n_pagos>1),max_consorcios=max(n_pagos),
    pagadores_diretos=sum(n_pagos_diretos>0),
    multipagadores_diretos=sum(n_pagos_diretos>1),
    so_indiretos=sum(n_pagos>0 & n_pagos_diretos==0),
    mistos=sum(n_pagos_diretos>0 & n_pagos>n_pagos_diretos),
    empates_maior=sum(n_maximos>1),
    maior_financeiro_no_direto=sum(maior_no_direto & n_maximos==1),
    mediana_fracao_maior=median(fracao_maior,na.rm=TRUE),
    valor=sum(valor),valor_direto=sum(valor_direto),.groups="drop") |>
  left_join(f |> group_by(ano) |> summarise(entidades=n_distinct(cnpj_raiz_8),
    linhas=n(),pares_pagos=sum(valor_total>0),.groups="drop"),by="ano") |>
  left_join(g |> group_by(ano) |> summarise(entidades_diretas=n_distinct(cnpj_raiz_8),
    linhas_diretas=n(),pares_pagos_diretos=sum(valor_total>0),
    pares_tempo_zero=sum(tempo_minimo_min==0),
    pares_pagos_tempo_zero=sum(tempo_minimo_min==0 & valor_total>0),.groups="drop"),by="ano")
stopifnot(sum(annual$pares_pagos)==10735, sum(annual$pares_pagos_diretos)==5612,
  all(annual$linhas_diretas==853*annual$entidades_diretas))
save_table(annual,"comparacao_anos")
save_table(municipal |> filter(ano==2019),"municipios_2019")
example <- f |> filter(ano==2019,municipio=="Igarapé",valor_total>0) |>
  mutate(fracao_financeira=valor_total/sum(valor_total),
    fracao_direta=if_else(elegivel_gravitacional_v1,
      valor_total/sum(valor_total[elegivel_gravitacional_v1]),NA_real_)) |>
  left_join(g |> select(id_municipio,cnpj_raiz_8,ano,tempo_minimo_min,
    tempo_mediano_min,distancia_minima_km,profissionais_sus_clinicos_soma_unidades),
    by=c("id_municipio","cnpj_raiz_8","ano"),relationship="one-to-one")
stopifnot(abs(sum(example$fracao_financeira)-1)<1e-12)
save_table(example,"exemplo_igarape_2019")
multiple <- f |> filter(ano==2019,municipio=="Conceição Do Pará",valor_total>0) |>
  group_by(id_municipio) |> mutate(fracao_financeira=valor_total/sum(valor_total),
    fracao_direta=if_else(elegivel_gravitacional_v1,
      valor_total/sum(valor_total[elegivel_gravitacional_v1]),NA_real_)) |>
  ungroup() |> left_join(g |> select(id_municipio,cnpj_raiz_8,ano,
    tempo_minimo_min,profissionais_sus_clinicos_soma_unidades),
    by=c("id_municipio","cnpj_raiz_8","ano"),relationship="one-to-one")
stopifnot(nrow(multiple)==4,abs(sum(multiple$fracao_financeira)-1)<1e-12,
  abs(sum(multiple$fracao_direta,na.rm=TRUE)-1)<1e-12)
save_table(multiple,"exemplo_multiplos_consorcios_2019")
units <- bind_rows(csv(inputs[6]),csv(inputs[7])) |>
  mutate(ano=as.integer(ano)) |> semi_join(f |> distinct(cnpj_raiz_8,ano),
    by=c("cnpj_raiz_8","ano")) |> filter(ano==2019)
stopifnot(!anyDuplicated(units[c("cnpj_raiz_8","ano","cnes")]))
save_table(units |> count(funcao_assistencial,tipo_unidade_codigo),
  "tipos_cnes_2019")
capacity <- g |> filter(ano==2019) |> distinct(cnpj_raiz_8,entidade,ano,
  n_destinos_clinicos_dezembro,n_municipios_clinicos_dezembro,
  profissionais_sus_clinicos_soma_unidades,servicos_sus_clinicos_soma_unidades,
  horas_sus_clinicas_soma_registros,leitos_sus_clinicos)
# Sede do cadastro atual: junção tecnica, nao evidencia de sede historica.
seats <- bind_rows(csv(inputs[4]) |> transmute(cnpj_raiz_8,
  sede_cadastral=municipio_sede_canonico),
  csv(inputs[5]) |> transmute(cnpj_raiz_8,sede_cadastral=municipio_sede)) |>
  semi_join(f |> distinct(cnpj_raiz_8),by="cnpj_raiz_8")
norm <- function(x) toupper(gsub("[^[:alnum:]]","",
  stringi::stri_trans_general(x,"Latin-ASCII")))
pop <- f |> filter(ano==2019) |> distinct(id_municipio,municipio,populacao_ibge) |>
  mutate(nome_norm=norm(municipio),codigo_ibge_6=substr(id_municipio,1,6))
stopifnot(nrow(pop)==853,!anyDuplicated(pop$nome_norm),
  nrow(seats)==73,!anyDuplicated(seats$cnpj_raiz_8))
seats <- seats |> mutate(nome_norm=norm(sede_cadastral)) |>
  left_join(pop |> select(nome_norm,id_sede=id_municipio,
    populacao_sede_2019=populacao_ibge),by="nome_norm",relationship="many-to-one")
stopifnot(!anyNA(seats$id_sede))
save_table(seats |> select(-nome_norm),"populacao_sede_cadastral_2019")
clinical <- units |> filter(funcao_assistencial=="destino_clinico_fixo") |>
  left_join(pop |> select(codigo_ibge_6,municipio,populacao_ibge),
    by="codigo_ibge_6",relationship="many-to-one")
stopifnot(!anyNA(clinical$populacao_ibge))
destinations <- clinical |> distinct(cnpj_raiz_8,codigo_ibge_6,municipio,populacao_ibge) |>
  group_by(cnpj_raiz_8) |> summarise(destinos=paste(municipio,collapse="; "),
    populacoes_destinos=paste(populacao_ibge,collapse="; "),
    populacao_destinos_soma=sum(populacao_ibge),.groups="drop")
mass <- capacity |> left_join(seats |> select(-nome_norm),by="cnpj_raiz_8",
    relationship="one-to-one") |>
  left_join(destinations,by="cnpj_raiz_8",relationship="one-to-one")
stopifnot(nrow(mass)==54,all(mass$leitos_sus_clinicos==0))
save_table(mass,"massas_e_localizacoes_2019")
metrics <- bind_rows(lapply(names(capacity)[4:9],function(v) data.frame(
  variavel=v,n=54,zeros=sum(capacity[[v]]==0),nulos=sum(is.na(capacity[[v]])),
  minimo=min(capacity[[v]]),mediana=median(capacity[[v]]),maximo=max(capacity[[v]]))))
save_table(metrics,"cobertura_massas_2019")
stopifnot(identical(hashes,vapply(inputs,function(p)
  digest::digest(file=p,algo="sha256"),character(1))))
save_table(data.frame(arquivo=inputs,sha256=hashes),"fontes")
print(annual |> filter(ano==2019),width=Inf)
print(metrics)
print(example |> select(entidade,valor_total,fracao_financeira,fracao_direta,
  tempo_minimo_min),width=Inf)
cat("OK: diagnostico sem estimacao; fontes preservadas. Sedes sem pareamento:",
  sum(is.na(seats$id_sede)),"\n")
