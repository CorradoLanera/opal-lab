#!/usr/bin/env Rscript
#
# Script per importare i dati di esempio in entrambi i siti Opal
# Supporta sia HTTP che HTTPS con fallback automatico
# Configurato per client locali (localhost)
#

library(opalr)
library(glue)
library(getPass)
library(usethis)

ui_info("Setup dati demo per opal-lab")

# Configurazione URL con fallback automatico per client locali
get_opal_urls <- function() {
  # URL per client locali (default)
  sitea_url <- Sys.getenv("SITEA_OPAL_URL", "https://localhost:18443")
  siteb_url <- Sys.getenv("SITEB_OPAL_URL", "https://localhost:28443")

  list(sitea = sitea_url, siteb = siteb_url)
}

# Funzione per testare e fare fallback HTTP se necessario
get_working_url <- function(https_url) {
  # Converti da HTTPS 18443/28443 a HTTP 18880/28880
  http_url <- gsub("https://", "http://", https_url)
  http_url <- gsub(":18443", ":18880", http_url)
  http_url <- gsub(":28443", ":28880", http_url)

  # Test HTTPS prima
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

  # Fallback HTTP
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

# Leggi le password dalle variabili d'ambiente
SITEA_PWD <- Sys.getenv("SITEA_OPAL_ADMIN_PWD")
SITEB_PWD <- Sys.getenv("SITEB_OPAL_ADMIN_PWD")

if (SITEA_PWD == "" || SITEB_PWD == "") {
  ui_oops("Password non trovate nelle variabili d'ambiente")
  ui_info("Assicurati che il file .env sia configurato correttamente")

  # Fallback interattivo
  if (SITEA_PWD == "") {
    SITEA_PWD <- getPass::getPass("Inserisci la password per Site A: ")
  }
  if (SITEB_PWD == "") {
    SITEB_PWD <- getPass::getPass("Inserisci la password per Site B: ")
  }
}

# Determina URL funzionanti
urls <- get_opal_urls()
sitea_config <- get_working_url(urls$sitea)
siteb_config <- get_working_url(urls$siteb)

if (is.null(sitea_config) || is.null(siteb_config)) {
  ui_oops("Impossibile connettersi ai server Opal")
  ui_info("Verifica che i servizi Docker siano avviati: docker compose ps")
  stop("Connessione fallita")
}

# Funzione per configurare un singolo sito
setup_site <- function(site_name, config, password) {
  ui_todo("Configurazione {site_name}...")

  tryCatch(
    {
      # Configurazione connessione
      opts <- list()
      if (config$use_ssl) {
        opts$ssl.verifyhost <- 0 # Ignora verifica hostname
        opts$ssl.verifypeer <- 0 # Ignora verifica certificato
        ui_info("Usando HTTPS con certificati self-signed")
      } else {
        ui_info("Usando HTTP")
      }

      # Connessione
      opal <- opal.login(
        username = "administrator",
        password = password,
        url = config$url,
        opts = opts
      )
      ui_done("Connessione riuscita a {config$url}")

      # Verifica se il progetto LAB esiste già
      progetti <- opal.projects(opal)
      if ("LAB" %in% progetti$name) {
        ui_info("Progetto LAB già esistente")
      } else {
        # Crea il progetto LAB
        opal.project_create(opal, "LAB", database = "mongodb")
        ui_done("Progetto LAB creato")
      }

      # Verifica se la tabella dataset esiste già
      tabelle <- opal.tables(opal, "LAB")
      if ("dataset" %in% tabelle$name) {
        ui_info("Tabella dataset già esistente")
      } else {
        # Importa il file CSV
        ui_todo("Importazione dati CSV...")
        tmp_rds <- tempfile(fileext = ".rds")
        readr::read_csv(
            "sitea/opal_home/data/dataset.csv",
           show_col_types = FALSE
          ) |>
            readr::write_rds(tmp_rds)
        opal.file_upload(opal, tmp_rds, "/tmp/dataset.rds")
        opal.table_import(
          opal,
          project = "LAB",
          file = "/tmp/dataset.rds",
          table = "dataset",
          policy = "generate"
        )
        ui_done("Dati importati nella tabella LAB.dataset")
      }

      # Mostra informazioni sulla tabella
      tabelle_finali <- opal.tables(opal, "LAB")
      ui_info(
        "Tabelle nel progetto LAB: {paste(tabelle_finali$name, collapse = ', ')}"
      )

      # Disconnessione
      opal.logout(opal)
      ui_done("{site_name} configurato correttamente")
    },
    error = function(e) {
      ui_oops("Errore durante la configurazione di {site_name}: {e$message}")
      ui_info("Suggerimenti:")
      ui_info("- Verifica che i servizi Docker siano avviati")
      ui_info("- Controlla le password nel file .env")
      ui_info(
        "- Assicurati che i file dataset.csv esistano nella directory data/"
      )
    }
  )
}

# Configura entrambi i siti
setup_site("Site A", sitea_config, SITEA_PWD)
setup_site("Site B", siteb_config, SITEB_PWD)

ui_done("Setup completato!")
ui_info("Configurazione utilizzata:")
ui_info("- Site A: {sitea_config$url}")
ui_info("- Site B: {siteb_config$url}")
ui_info("I dati sono stati importati nella tabella LAB.dataset")
ui_info("Per testare: {ui_code('source(\"demo-analysis.R\")')}")
