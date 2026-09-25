# Recorte dirigido do MIDES original, sem alterar fontes ou bases analiticas.
# Usar na pasta do modelo: Rscript 37_conciliar_transacoes_portais.R
invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.utf8"))
out <- "outputs/auditoria_alternativas/conciliacao_financeira_2026_09_25"
dir.create(out, recursive=TRUE, showWarnings=FALSE)
d <- readRDS("../../dados/bruto/mides_mg_atualizado.rds")
root <- substr(d$documento_credor, 1, 8)
keep <- (d$id_municipio == "3131307" & root == "00853908" & d$ano %in% 2018:2019) |
        (d$id_municipio == "3154606" & root == "05802877" & d$ano == 2014) |
        (d$id_municipio == "3161205" & root == "00079634" & d$ano == 2019)
x <- d[which(keep), ]
write.csv(x, file.path(out, "transacoes_originais_prioritarias.csv"),
          row.names=FALSE, na="", fileEncoding="UTF-8")
summary <- aggregate(valor_final ~ ano + id_municipio + nome_credor + indicador_restos_pagar,
                     data=x, FUN=sum)
write.csv(summary, file.path(out, "resumo_por_restos.csv"), row.names=FALSE,
          fileEncoding="UTF-8")
ipatinga <- x[x$id_municipio == "3131307" & x$ano == 2018, ]
stopifnot(abs(sum(ipatinga$valor_final[!ipatinga$indicador_restos_pagar]) - 567152.67) < .005,
          abs(sum(ipatinga$valor_final[ipatinga$indicador_restos_pagar]) - 137077.88) < .005,
          abs(sum(ipatinga$valor_final) - 704230.55) < .005)
print(summary)
cp <- read.csv("evidencias/conselheiro_pena_empenhos_2019_portal.csv",
               colClasses="character", fileEncoding="UTF-8")
stopifnot(nrow(cp) == 14, all(cp$objeto_consultado == "TRUE"),
          all(nzchar(cp$descricao_transcrita)),
          abs(sum(as.numeric(cp$valor_pago)) - 11468.66) < .005)
# Decisão analítica separada: não reescrever o original nem inventar zero.
decision <- data.frame(id_municipio="3118403", cnpj_raiz_8="00639952", ano=2019,
  valor_original=11468.66, y_original=1L, y_auditado=NA_integer_,
  usar_como_positivo_validado=FALSE,
  motivo="14 objetos fiscais/radiodifusao contradizem atribuicao ao CISVI",
  fonte="evidencias/conselheiro_pena_empenhos_2019_portal.csv")
write.csv(decision, file.path(out, "decisao_conselheiro_pena_2019.csv"),
          row.names=FALSE, na="", fileEncoding="UTF-8")
