#!/usr/bin/env Rscript
#
# Script per installazione automatica dei pacchetti R necessari
# Usage: Rscript scripts/install-packages.R
#

# Installa pak e usethis se non disponibili
if (!require("pak", quietly = TRUE)) {
  install.packages("pak")
  library(pak)
}

if (!require("usethis", quietly = TRUE)) {
  install.packages("usethis")
  library(usethis)
}

ui_info("Installazione pacchetti R per DataSHIELD")

# Lista tutti i pacchetti necessari
packages <- c(
  "opalr",
  "DSI",
  "DSOpal",
  "datashield/dsBaseClient",  # da GitHub
  "glue",
  "dplyr",
  "ggplot2",
  "getPass",
  "httr"  # Necessario per test connessioni HTTP/HTTPS
)

# Installazione con pak
ui_todo("Installando {length(packages)} pacchetti...")
pak::pkg_install(packages)

# Verifica installazione
required_libs <- c("opalr", "DSI", "DSOpal", "dsBaseClient", "glue", "dplyr", "ggplot2", "getPass", "httr")
success <- sapply(required_libs, require, character.only = TRUE, quietly = TRUE)

if (all(success)) {
  ui_done("Tutti i pacchetti installati correttamente")
  ui_done("Ambiente DataSHIELD pronto!")
} else {
  failed_packages <- names(success)[!success]
  ui_oops("Alcuni pacchetti non disponibili: {ui_value(failed_packages)}")
}

ui_line()
ui_info("Informazioni sessione")
sessionInfo()
