#
# Script per importare i dati di esempio in entrambi i siti Opal
#
# Questo script migliora la configurazione originale gestendo correttamente
# i percorsi dei dataset per i diversi siti (Site A e Site B) e utilizzando
# l'API `opal.table_save()` al posto di `opal.table_import()` per
# caricare i dati. La funzione `opal.table_save()` è la modalità
# consigliata per importare tabelle da R in Opal in quanto si occupa
# automaticamente di trasferire il tibble al server R e di creare la
# tabella, evitando problemi legati alla creazione di sessioni Rock.

#!/usr/bin/env Rscript

library(opalr)
library(glue)
library(getPass)
library(usethis)
library(readr)

ui_info("Setup dati demo per opal-lab")

# Configurazione URL con fallback automatico per client locali
get_opal_urls <- function() {
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

# Leggi le password dalle variabili d'ambiente oppure chiedi
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
# Utilizza `site_name` per determinare il percorso del dataset in maniera
# corretta (ad esempio `sitea/opal_home/data/dataset.csv` per Site A e
# `siteb/opal_home/data/dataset.csv` per Site B).
setup_site <- function(site_name, config, password) {
  ui_todo("Configurazione {site_name}...")
  tryCatch({
    # Opzioni di connessione
    opts <- list()
    if (config$use_ssl) {
      opts$ssl.verifyhost <- 0
      opts$ssl.verifypeer <- 0
      ui_info("Usando HTTPS con certificati self-signed")
    } else {
      ui_info("Usando HTTP")
    }

    # Connessione a Opal
    opal <- opal.login(
      username = "administrator",
      password = password,
      url = config$url,
      opts = opts
    )
    ui_done("Connessione riuscita a {config$url}")

    # Verifica o crea il progetto LAB
    progetti <- opal.projects(opal)
    if (!"LAB" %in% progetti$name) {
      opal.project_create(opal, "LAB", database = "mongodb")
      ui_done("Progetto LAB creato")
    } else {
      ui_info("Progetto LAB già esistente")
    }

    # Verifica se la tabella esiste già
    tabelle <- opal.tables(opal, "LAB")
    if ("dataset" %in% tabelle$name) {
      ui_info("Tabella dataset già esistente")
    } else {
      ui_todo("Importazione dati CSV...")
      # Costruisci il percorso del dataset per il sito corrente
      dataset_path <- file.path(site_name, "opal_home", "data", "dataset.csv")
      if (!file.exists(dataset_path)) {
        ui_oops("File CSV non trovato: {dataset_path}")
        stop("Dataset non trovato")
      }
      # Leggi il CSV in un tibble
      data <- readr::read_csv(dataset_path, show_col_types = FALSE)
      # Importa il tibble come tabella in Opal (sovrascrivendo se necessario)
      opal.table_save(opal, data, project = "LAB", table = "dataset", overwrite = TRUE, id.name = "id")
      ui_done("Dati importati nella tabella LAB.dataset")
    }

    # Mostra le tabelle finali
    tabelle_finali <- opal.tables(opal, "LAB")
    ui_info("Tabelle nel progetto LAB: {paste(tabelle_finali$name, collapse = ', ')}")
    # Disconnessione
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

# Configura entrambi i siti. I nomi 'sitea' e 'siteb' coincidono con le
# directory principali dove risiedono i dati e consentono di costruire
# correttamente il percorso del file CSV.
setup_site("sitea", sitea_config, SITEA_PWD)
setup_site("siteb", siteb_config, SITEB_PWD)

ui_done("Setup completato!")
ui_info("Configurazione utilizzata:")
ui_info("- Site A: {sitea_config$url}")
ui_info("- Site B: {siteb_config$url}")
ui_info("I dati sono stati importati nella tabella LAB.dataset")
ui_info("Per testare: {ui_code('source(\"demo-analysis.R\")')}")
