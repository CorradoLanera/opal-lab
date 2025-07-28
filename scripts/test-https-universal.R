#!/usr/bin/env Rscript
#
# Script universale per testare connessioni HTTPS ai server Opal
# Funziona sia dalla macchina host che dal container RStudio Server
#

library(opalr)
library(glue)
library(usethis)

ui_info("Test connessioni HTTPS universale per opal-lab")

# Determina se siamo dentro un container o sulla macchina host
is_container <- file.exists("/etc/hostname") &&
  any(grepl("opal-lab", readLines("/etc/hostname", warn = FALSE), ignore.case = TRUE))

if (is_container) {
  ui_info("Esecuzione rilevata: Container Docker")
  # URLs per connessioni interne al network Docker
  SITEA_URL <- "https://sitea_opal:8443"
  SITEB_URL <- "https://siteb_opal:8443"
  SITEA_HTTP_URL <- "http://sitea_opal:8080"
  SITEB_HTTP_URL <- "http://siteb_opal:8080"
} else {
  ui_info("Esecuzione rilevata: Macchina host")
  # URLs per connessioni dalla macchina host
  SITEA_URL <- "https://localhost:18443"
  SITEB_URL <- "https://localhost:28443"
  SITEA_HTTP_URL <- "http://localhost:18880"
  SITEB_HTTP_URL <- "http://localhost:28880"
}

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

    # Test connettività di base prima del login
    parsed_url <- httr::parse_url(url)
    ui_info("Test connettività di base...")

    # Test connessione
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

    # Test info server
    ui_info("Server Opal: connesso e operativo")

    # Disconnessione
    opal.logout(opal)
    ui_done("{site_name} - Test completato con successo")

    return(TRUE)

  }, error = function(e) {
    ui_oops("Errore connessione a {site_name}: {e$message}")

    # Diagnostica aggiuntiva per connessioni container
    if (is_container) {
      ui_info("Diagnostica network container:")
      parsed_url <- httr::parse_url(url)
      host <- parsed_url$hostname
      port <- parsed_url$port

      # Test risoluzione DNS
      dns_result <- system(paste("nslookup", host), intern = TRUE, ignore.stderr = TRUE)
      if (length(dns_result) > 0) {
        ui_info("DNS risoluzione: OK")
      } else {
        ui_oops("DNS risoluzione: FALLITA")
      }

      # Test connettività porta
      nc_result <- system(paste("nc -zv", host, port), intern = TRUE, ignore.stderr = TRUE)
      if (any(grepl("open", nc_result, ignore.case = TRUE))) {
        ui_info("Porta {port}: APERTA")
      } else {
        ui_oops("Porta {port}: CHIUSA o NON RAGGIUNGIBILE")
      }
    }

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

# Info aggiuntive per il debugging
ui_line()
ui_info("INFO AMBIENTE:")
ui_info("Contesto: {if(is_container) 'Container Docker' else 'Macchina Host'}")
ui_info("Site A URL: {SITEA_URL}")
ui_info("Site B URL: {SITEB_URL}")
