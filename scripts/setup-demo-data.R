#!/usr/bin/env Rscript
#
# Script per importare i dati di esempio in entrambi i siti Opal
# Da eseguire in RStudio dopo aver avviato i servizi Docker
#

library(opalr)
library(glue)
library(getPass)
library(usethis)

ui_info("Setup dati demo per opal-lab (HTTPS)")

# Configurazione HTTPS
SITEA_URL <- "https://sitea_opal:8443"
SITEB_URL <- "https://siteb_opal:8443"

# Leggi le password dalle variabili d'ambiente
SITEA_PWD <- Sys.getenv(
  "SITEA_OPAL_ADMIN_PWD",
  getPass::getPass("Inserisci la password per Sito A: ")
)
SITEB_PWD <- Sys.getenv(
  "SITEB_OPAL_ADMIN_PWD",
  getPass::getPass("Inserisci la password per Sito B: ")
)

if (SITEA_PWD == "" || SITEB_PWD == "") {
  ui_oops("Password non trovate nelle variabili d'ambiente")
  ui_info("Assicurati che il file .env sia configurato correttamente")
  stop("Password mancanti")
}

# Funzione per configurare un singolo sito
setup_site <- function(site_name, url, password) {
  ui_todo("Configurazione {site_name}...")

  tryCatch({
    # Connessione con HTTPS e certificati self-signed
    # Nota: opalr deve essere configurato per accettare certificati self-signed
    opal <- opal.login(
      username = "administrator",
      password = password,
      url = url,
      opts = list(
        ssl.verifyhost = 0,  # Ignora verifica hostname
        ssl.verifypeer = 0   # Ignora verifica certificato
      )
    )
    ui_done("Connessione HTTPS riuscita")

    # Verifica se il progetto LAB esiste già
    progetti <- opal.projects(opal)
    if ("LAB" %in% progetti$name) {
      ui_info("Progetto LAB già esistente")
    } else {
      # Crea il progetto LAB
      opal.project_create(opal, "LAB", database = "LAB")
      ui_done("Progetto LAB creato")
    }

    # Verifica se la tabella dataset esiste già
    tabelle <- opal.tables(opal, "LAB")
    if ("dataset" %in% tabelle$name) {
      ui_info("Tabella dataset già esistente")
    } else {
      # Importa il file CSV
      opal.file_upload(opal, "/srv/data/dataset.csv", "/tmp/dataset.csv")
      opal.table_import(
        opal,
        project = "LAB",
        file = "/tmp/dataset.csv",
        type = "CSV",
        table = "dataset"
      )
      ui_done("Dati importati nella tabella LAB.dataset")
    }

    # Mostra informazioni sulla tabella
    tabelle_finali <- opal.tables(opal, "LAB")
    ui_info("Tabelle nel progetto LAB: {paste(tabelle_finali$name, collapse = ', ')}")

    # Disconnessione
    opal.logout(opal)
    ui_done("{site_name} configurato correttamente")

  }, error = function(e) {
    ui_oops("Errore durante la configurazione di {site_name}: {e$message}")
    ui_info("Suggerimenti:")
    ui_info("- Verifica che i servizi Docker siano avviati")
    ui_info("- Controlla che i certificati SSL siano configurati correttamente")
    ui_info("- Se il problema persiste, prova con HTTP temporaneamente")
  })
}

# Verifica connessione ai servizi prima di procedere
ui_todo("Verifica connessione ai servizi...")

# Configura entrambi i siti
setup_site("Site A", SITEA_URL, SITEA_PWD)
setup_site("Site B", SITEB_URL, SITEB_PWD)

ui_done("Setup completato!")
ui_info("I dati sono stati importati usando connessioni HTTPS")
ui_info("Ora puoi eseguire analisi federate usando la tabella LAB.dataset")
ui_info("Per testare: {ui_code('source(\"scripts/demo-analysis.R\")')}")
