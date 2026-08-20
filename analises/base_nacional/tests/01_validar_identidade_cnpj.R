invisible(Sys.setlocale("LC_ALL", "Portuguese_Brazil.1252"))

library(dplyr)
library(stringr)

project_dir <- "."
out_dir <- file.path(project_dir, "analises", "base_nacional", "outputs")

crosswalk <- readRDS(file.path(out_dir, "crosswalk_cnpj_matriz_filial_nacional.rds"))
cadastro <- readRDS(file.path(out_dir, "cadastro_consorcios_nacional_consolidado.rds"))

stopifnot(nrow(crosswalk) == 1194L)
stopifnot(nrow(cadastro) == 1159L)
stopifnot(n_distinct(crosswalk$cnpj_original) == 1194L)
stopifnot(n_distinct(crosswalk$cnpj_raiz_8) == 1159L)
stopifnot(sum(cadastro$tem_filial) == 23L)
stopifnot(sum(cadastro$n_filiais) == 35L)
stopifnot(all(crosswalk$cnpj_canonico == crosswalk$cnpj_matriz))
stopifnot(all(str_sub(crosswalk$cnpj_canonico, 9, 12) == "0001"))
stopifnot(all(crosswalk$uf_sede_original == crosswalk$uf_sede_canonica))
stopifnot(!anyDuplicated(cadastro$cnpj_raiz_8))
stopifnot(!anyDuplicated(cadastro$cnpj_canonico))

cat("OK - identidade CNPJ nacional validada\n")
cat("CNPJs originais:", nrow(crosswalk), "\n")
cat("Entidades consolidadas:", nrow(cadastro), "\n")
cat("Raizes com filiais:", sum(cadastro$tem_filial), "\n")
cat("Filiais incorporadas:", sum(cadastro$n_filiais), "\n")
