#!/usr/bin/env Rscript

library(opalr)
library(glue)
library(getPass)
library(usethis)
library(readr)

ui_info("Setup dati demo per opal-lab")
get_opal_urls <- function() {
  list(
    sitea = Sys.getenv("SITEA_OPAL_URL", "https://localhost:18443"),
    siteb = Sys.getenv("SITEB_OPAL_URL", "https://localhost:28443")
  )
}

get_working_url <- function(https_url) {
  http_url <- gsub("https://", "http://", https_url)
  http_url <- gsub(":(\\d{2})443", ":\\1880", http_url)

  ui_todo("Test HTTPS: {https_url}")
  if (grepl("https://", https_url)) {
    tryCatch({
      response <- httr::GET(https_url, httr::config(ssl_verifypeer = FALSE))
      if (httr::status_code(response) < 400) {
        ui_done("HTTPS disponibile")
        return(list(url = https_url, use_ssl = TRUE))
      }
    }, error = function(e) {
      ui_info("HTTPS non raggiungibile, provo HTTP...")
    })
  }

  ui_todo("Test HTTP: {http_url}")
  tryCatch({
    response <- httr::GET(http_url)
    if (httr::status_code(response) < 400) {
      ui_done("HTTP disponibile")
      return(list(url = http_url, use_ssl = FALSE))
    }
  }, error = function(e) {
    ui_oops("Nessuna connessione disponibile per {https_url}")
    return(NULL)
  })
}

SITEA_PWD <- Sys.getenv("SITEA_OPAL_ADMIN_PWD")
SITEB_PWD <- Sys.getenv("SITEB_OPAL_ADMIN_PWD")

if (SITEA_PWD == "" || SITEB_PWD == "") {
  ui_oops("Password non trovate nelle variabili d'ambiente")
  ui_info("Assicurati che il file .env sia configurato correttamente")
  if (SITEA_PWD == "") {
    SITEA_PWD <- getPass::getPass("Inserisci la password per Site A: ")
  }
  if (SITEB_PWD == "") {
    SITEB_PWD <- getPass::getPass("Inserisci la password per Site B: ")
  }
}

urls <- get_opal_urls()
sitea_config <- get_working_url(urls$sitea)
siteb_config <- get_working_url(urls$siteb)

if (is.null(sitea_config) || is.null(siteb_config)) {
  ui_oops("Impossibile connettersi ai server Opal")
  ui_info("Verifica che i servizi Docker siano avviati: docker compose ps")
  ui_stop("Connessione fallita")
}

setup_site <- function(site_name, config, password) {
  ui_todo("Configurazione {site_name}...")
  tryCatch({
    opts <- list()
    if (config$use_ssl) {
      opts$ssl.verifyhost <- 0
      opts$ssl.verifypeer <- 0
      ui_info("Usando HTTPS con certificati self-signed")
    } else {
      ui_info("Usando HTTP")
    }

    opal <- opal.login(
      username = "administrator",
      password = password,
      url = config$url,
      opts = opts
    )
    ui_done("Connessione riuscita a {config$url}")

    progetti <- opal.projects(opal)
    if (!"LAB" %in% progetti$name) {
      opal.project_create(opal, "LAB", database = "mongodb")
      ui_done("Progetto LAB creato")
    } else {
      ui_info("Progetto LAB già esistente")
    }

    tabelle <- opal.tables(opal, "LAB", counts = TRUE)
    if ("dataset" %in% tabelle$name) {
      ui_info("Tabella dataset già esistente")
    } else {
      ui_todo("Importazione dati CSV...")
      dataset_path <- file.path(site_name, "opal_home", "data", "dataset.csv")
      if (!file.exists(dataset_path)) {
        ui_oops("File CSV non trovato: {dataset_path}")
        stop("Dataset non trovato")
      }
      data <- readr::read_csv(dataset_path, show_col_types = FALSE)
      opal |>
        opal.table_save(
          data,
          project = "LAB",
          table = "dataset"
        )
      ui_done("Dati importati nella tabella LAB.dataset")
    }

    tabelle_finali <- opal.tables(opal, "LAB", counts = TRUE)
    ui_info("Tabelle nel progetto LAB: {paste(tabelle_finali$name, collapse = ', ')}")

    opal.logout(opal)
    ui_done("{site_name} configurato correttamente")
  }, error = function(e) {
    ui_oops("Errore durante la configurazione di {site_name}: {e$message}")
    ui_info("Suggerimenti:")
    ui_info("- Verifica che i servizi Docker siano avviati")
    ui_info("- Controlla le password nel file .env")
    ui_info("- Assicurati che i file dataset.csv esistano nella directory data/")
  })
}

setup_site("sitea", sitea_config, SITEA_PWD)
setup_site("siteb", siteb_config, SITEB_PWD)

ui_done("Setup completato!")
ui_info("Configurazione utilizzata:")
ui_info("- Site A: {sitea_config$url}")
ui_info("- Site B: {siteb_config$url}")
ui_info("I dati sono stati importati nella tabella LAB.dataset")
ui_info("Per testare: {ui_code('source(\"demo-analysis.R\")')}")
