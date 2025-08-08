#!/usr/bin/env Rscript
#
# Script per testare la connessione ai servizi Opal da client locale
#

library(httr)
library(usethis)

ui_info("Test connessione client locale → Opal")

# URL da testare
test_urls <- list(
  sitea_https = "https://localhost:18443",
  sitea_http = "http://localhost:18880",
  siteb_https = "https://localhost:28443",
  siteb_http = "http://localhost:28880"
)

# Test ogni URL
for (name in names(test_urls)) {
  url <- test_urls[[name]]
  ui_todo("Test {name}: {url}")

  tryCatch({
    if (grepl("https://", url)) {
      response <- GET(url, config(ssl_verifypeer = FALSE), timeout(10))
    } else {
      response <- GET(url, timeout(10))
    }

    if (status_code(response) < 400) {
      ui_done("✓ Connessione riuscita (status: {status_code(response)})")
    } else {
      ui_oops("✗ Connessione fallita (status: {status_code(response)})")
    }
  }, error = function(e) {
    ui_oops("✗ Errore: {e$message}")
  })
}

ui_info("Verifica che Docker sia avviato: docker compose ps")
