#!/usr/bin/env Rscript
#
# Demo di analisi federata con DataSHIELD.
# Supporta sia HTTP che HTTPS con fallback automatico
#

suppressPackageStartupMessages({
  library(DSI)
  library(DSOpal)
  library(dsBaseClient)
  library(glue)
  library(usethis)
})

ui_info("Demo Analisi Federata DataSHIELD")

# Configurazione URL con fallback automatico
get_opal_urls <- function() {
  # Prova prima le variabili d'ambiente (preferite)
  sitea_url <- Sys.getenv("SITEA_OPAL_URL", "")
  siteb_url <- Sys.getenv("SITEB_OPAL_URL", "")

  # Se non configurate, usa HTTPS di default
  if (sitea_url == "") sitea_url <- "https://sitea_opal:8443"
  if (siteb_url == "") siteb_url <- "https://siteb_opal:8443"

  list(sitea = sitea_url, siteb = siteb_url)
}

# Funzione per testare connessione e fare fallback HTTP se necessario
test_and_fallback <- function(https_url) {
  http_url <- gsub("https://", "http://", gsub(":8443", ":8080", https_url))

  ui_todo("Test connessione a {https_url}...")

  # Test HTTPS
  tryCatch({
    response <- httr::GET(https_url, httr::config(ssl_verifypeer = FALSE, ssl_verifyhost = FALSE))
    if (httr::status_code(response) < 400) {
      ui_done("HTTPS funzionante")
      return(list(url = https_url, options = "ssl_verifyhost=0,ssl_verifypeer=0"))
    }
  }, error = function(e) {
    ui_info("HTTPS non disponibile, provo HTTP...")
  })

  # Fallback HTTP
  tryCatch({
    response <- httr::GET(http_url)
    if (httr::status_code(response) < 400) {
      ui_done("HTTP funzionante")
      return(list(url = http_url, options = ""))
    }
  }, error = function(e) {
    ui_oops("Nessuna connessione disponibile")
    return(NULL)
  })
}

# Configura connessioni con fallback automatico
urls <- get_opal_urls()

sitea_config <- test_and_fallback(urls$sitea)
siteb_config <- test_and_fallback(urls$siteb)

if (is.null(sitea_config) || is.null(siteb_config)) {
  ui_oops("Impossibile connettersi ai server Opal")
  ui_info("Verifica che i servizi Docker siano avviati: docker compose ps")
  stop("Connessione fallita")
}

login_data <- data.frame(
  server = c("siteA", "siteB"),
  url = c(sitea_config$url, siteb_config$url),
  user = c("administrator", "administrator"),
  password = c(
    Sys.getenv("SITEA_OPAL_ADMIN_PWD"),
    Sys.getenv("SITEB_OPAL_ADMIN_PWD")
  ),
  table = c("LAB.dataset", "LAB.dataset"),
  options = c(sitea_config$options, siteb_config$options),
  stringsAsFactors = FALSE
)

# Verifica password
if (any(login_data$password == "")) {
  ui_oops("Password mancanti nelle variabili d'ambiente")
  ui_info("Verifica che il file .env sia configurato correttamente")
  stop("Password mancanti")
}

tryCatch(
  {
    ## Connessione ai siti ----
    ui_todo("Connessione ai siti DataSHIELD...")
    conns <- datashield.login(logins = login_data, assign = TRUE)
    ui_done("Connesso a {length(conns)} siti")

    ## Verifica informazioni sui dataset ----
    ui_todo("Verifica informazioni sui dataset...")
    for (site in names(conns)) {
      dims <- ds.dim("D", datasources = conns[site])
      ui_info("{ui_value(site)}: {dims[[1]][1]} righe × {dims[[1]][2]} colonne")
    }

    ## Struttura dataset ----
    ui_todo("Analisi struttura dataset...")
    structure_info <- ds.colnames("D")
    ui_info(
      "Colonne disponibili: {paste(structure_info$siteA, collapse = ', ')}"
    )

    ## Statistiche descrittive ----
    ui_todo("Calcolo statistiche descrittive federate...")
    # Media età
    if ("age" %in% structure_info$siteA) {
      age_stats <- ds.mean("D$age", type = "combine")
      ui_info("Età media: {round(age_stats$Global.Mean[1], 2)} anni")
    }
    # Media BMI
    if ("bmi" %in% structure_info$siteA) {
      bmi_stats <- ds.mean("D$bmi", type = "combine")
      ui_info("BMI medio: {round(bmi_stats$Global.Mean[1], 2)}")
    }
    ui_info("- I servizi Opal siano avviati (docker compose ps)")
    if ("gender" %in% structure_info$siteA) {
      gender_table <- ds.table("D$gender", type = "combine")
      ui_info("Distribuzione genere:")
      for (i in seq_along(
        gender_table$output.list$TABLES.COMBINED_all.sources_counts
      )) {
        gender <- names(
          gender_table$output.list$TABLES.COMBINED_all.sources_counts
        )[i]
        count <- gender_table$output.list$TABLES.COMBINED_all.sources_counts[[
          i
        ]]
        percentage <- round(
          100 *
            count /
            sum(gender_table$output.list$TABLES.COMBINED_all.sources_counts),
          1
        )
        ui_info("  {gender}: {count} ({percentage}%)")
      }
    }
    # Modello lineare federato
    if (all(c("age", "bmi", "gender") %in% structure_info$siteA)) {
      ui_todo("Esecuzione modello lineare federato (BMI ~ età + genere)...")
      model <- ds.glm(
        formula = "bmi ~ age + gender",
        data = "D",
        family = "gaussian",
        datasources = conns
      )
      ui_info("Coefficienti:")
      coeffs <- model$coefficients
      for (i in seq_along(coeffs)) {
        var_name <- names(coeffs)[i]
        coeff_val <- coeffs[[i]]
        ui_info("  {var_name}: {round(coeff_val, 4)}")
      }
    }
    # Correlazione età-BMI
    if (all(c("age", "bmi") %in% structure_info$siteA)) {
      ui_todo("Calcolo correlazione età-BMI...")
      corr <- ds.cor(x = "D$age", y = "D$bmi", type = "combine")
      ui_info("Correlazione: {round(corr$pooled.cor, 3)}")
    }

    ui_done("Analisi completata con successo!")
    ui_info(
      "I risultati mostrano statistiche aggregate senza trasferire dati individuali"
    )

    ## Chiusura connessioni ----
    datashield.logout(conns)
    ui_done("Disconnesso da tutti i siti")
  },
  error = function(e) {
    ui_oops("Errore durante l'analisi: {e$message}")
    ui_info("Verifica che:")
    ui_info("- I servizi Opal siano avviati")
    ui_info("- I dati siano stati importati correttamente")
    ui_info("- Le credenziali nel file .env siano corrette")

    ## Cleanup in caso di errore ----
    if (exists("conns")) {
      try(datashield.logout(conns), silent = TRUE)
    }
  }
)
