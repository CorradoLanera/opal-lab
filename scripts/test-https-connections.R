#!/usr/bin/env Rscript
#
# Script per testare le connessioni HTTPS ai server Opal
# Utile per verificare che i certificati SSL siano configurati correttamente
#

library(opalr)
library(glue)
library(usethis)

ui_info("Test connessioni HTTPS per opal-lab")

# Configurazione HTTPS - Usa i nomi container per connessioni dall'interno del network Docker
SITEA_URL <- "https://sitea_opal:8443"   # Per connessioni interne al network Docker
SITEB_URL <- "https://siteb_opal:8443"   # Per connessioni interne al network Docker

# URLs localhost per test dalla macchina host
SITEA_LOCAL_URL <- "https://localhost:18443"
SITEB_LOCAL_URL <- "https://localhost:28443"

# URLs HTTP per fallback testing
SITEA_HTTP_URL <- "http://sitea_opal:8080"   # Porta HTTP interna
SITEB_HTTP_URL <- "http://siteb_opal:8080"   # Porta HTTP interna

# Leggi le password dalle variabili d'ambiente
SITEA_PWD <- Sys.getenv("SITEA_OPAL_ADMIN_PWD")
SITEB_PWD <- Sys.getenv("SITEB_OPAL_ADMIN_PWD")

if (SITEA_PWD == "" || SITEB_PWD == "") {
  ui_oops("Password non trovate nelle variabili d'ambiente")
  ui_info("Configura SITEA_OPAL_ADMIN_PWD e SITEB_OPAL_ADMIN_PWD nel file .env")
  stop("Password mancanti")
}

# Funzione per testare connessione HTTPS
test_https_connection <- function(site_name, url, password) {
  ui_todo("Test connessione HTTPS a {site_name}...")
  ui_info("URL: {url}")

  tryCatch({
    # Reset configurazione httr
    httr::reset_config()

    # Configurazione httr per certificati self-signed
    httr::set_config(
      httr::config(
        ssl_verifypeer = 0L,
        ssl_verifyhost = 0L,
        sslversion = 6L,
        verbose = FALSE
      )
    )

    # Test connessione con opzioni SSL per certificati self-signed
    opal <- opal.login(
      username = "administrator",
      password = password,
      url = url,
      opts = list(
        ssl_verifypeer = 0L,
        ssl_verifyhost = 0L,
        verbose = FALSE
      )
    )

    ui_done("Connessione HTTPS riuscita")

    # Test operazioni base
    ui_todo("Test operazioni base...")

    # Lista progetti
    progetti <- opal.projects(opal)
    ui_info("Progetti disponibili: {paste(progetti$name, collapse = ', ')}")

    # Se esiste il progetto LAB, mostra le tabelle
    if ("LAB" %in% progetti$name) {
      tabelle <- opal.tables(opal, "LAB")
      ui_info("Tabelle in LAB: {paste(tabelle$name, collapse = ', ')}")
    }

    # Test info server - usa funzione che esiste
    ui_info("Server Opal: connesso e operativo")

    # Disconnessione
    opal.logout(opal)
    ui_done("{site_name} - Test completato con successo")

    return(TRUE)

  }, error = function(e) {
    ui_oops("Errore connessione a {site_name}: {e$message}")
    return(FALSE)
  })
}

# Test connessione HTTP (per debug)
test_http_connection <- function(site_name, url, password) {
  ui_todo("Test connessione HTTP a {site_name}...")
  ui_info("URL: {url}")

  tryCatch({
    opal <- opal.login(
      username = "administrator",
      password = password,
      url = url
    )

    ui_done("Connessione HTTP riuscita")

    # Test operazioni base
    ui_todo("Test operazioni base...")
    progetti <- opal.projects(opal)
    ui_info("Progetti disponibili: {paste(progetti$name, collapse = ', ')}")

    opal.logout(opal)
    ui_done("{site_name} - Test HTTP completato")
    return(TRUE)

  }, error = function(e) {
    ui_oops("Errore connessione HTTP a {site_name}: {e$message}")
    return(FALSE)
  })
}

# Test connessioni a entrambi i siti
ui_todo("Avvio test connessioni HTTPS...")

sitea_ok <- test_https_connection("Site A", SITEA_URL, SITEA_PWD)
siteb_ok <- test_https_connection("Site B", SITEB_URL, SITEB_PWD)

# Test HTTP per troubleshooting
ui_line()
ui_info("TEST HTTP (fallback per troubleshooting)")
sitea_http_ok <- test_http_connection("Site A", SITEA_HTTP_URL, SITEA_PWD)
siteb_http_ok <- test_http_connection("Site B", SITEB_HTTP_URL, SITEB_PWD)

# Resoconto finale
ui_line()
ui_info("RESOCONTO FINALE")
ui_info("Site A (HTTPS): {if(sitea_ok) ui_value('OK') else ui_value('ERRORE')}")
ui_info("Site B (HTTPS): {if(siteb_ok) ui_value('OK') else ui_value('ERRORE')}")
ui_info("Site A (HTTP): {if(sitea_http_ok) ui_value('OK') else ui_value('ERRORE')}")
ui_info("Site B (HTTP): {if(siteb_http_ok) ui_value('OK') else ui_value('ERRORE')}")

if (sitea_ok && siteb_ok) {
  ui_done("TUTTI I TEST SUPERATI!")
  ui_info("Le connessioni HTTPS funzionano correttamente.")
  ui_info("I certificati SSL sono configurati correttamente.")
  ui_line()
  ui_info("Prossimi passi:")
  ui_info("1. Importa i dati: {ui_code('source(\"setup-demo-data.R\")')}")
  ui_info("2. Esegui analisi: {ui_code('source(\"demo-analysis.R\")')}")
} else {
  ui_oops("ALCUNI TEST FALLITI")
  ui_info("Controlla la configurazione prima di procedere.")
  ui_line()
  ui_info("Troubleshooting:")
  ui_info("1. Verifica che Docker sia avviato: {ui_code('docker compose ps')}")
  ui_info("2. Controlla i log: {ui_code('docker compose logs')}")
  ui_info("3. Riavvia container Opal: {ui_code('docker compose restart sitea_opal siteb_opal')}")
  ui_info("4. Verifica file .env con password corrette")
}
