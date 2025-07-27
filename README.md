# opal‑lab

[![Docker Compose](https://img.shields.io/badge/docker--compose-supported-blue.svg)](https://docs.docker.com/compose/)
[![DataSHIELD](https://img.shields.io/badge/DataSHIELD-compatible-green.svg)](https://www.datashield.org/)
[![Opal](https://img.shields.io/badge/Opal-4.x-orange.svg)](https://www.obiba.org/pages/products/opal/)

**Ambiente Docker per sperimentare l'analisi federata con DataSHIELD**

Questo repository fornisce un ambiente completo con due server Opal simulati (Site A e Site B) e un client R per l'analisi federata. DataSHIELD permette di analizzare dati distribuiti senza spostarli dai siti originali.

## 🚀 Setup rapido (3 comandi)

```bash
# 1. Clona il repository
git clone https://github.com/CorradoLanera/opal-lab.git
cd opal-lab

# 2. Setup automatico (crea .env, directory, certificati SSL)
./setup.sh

# 3. Avvia i servizi
docker compose up -d
```

Dopo 2-3 minuti avrai tutto pronto:
- **RStudio**: http://localhost:8787
- **Site A**: https://localhost:18443 (HTTPS) o http://localhost:18880 (HTTP)
- **Site B**: https://localhost:28443 (HTTPS) o http://localhost:28880 (HTTP)

## 📋 Requisiti

- **Docker Desktop** (4 GB RAM disponibili)
- **Git**
- **OpenSSL** (per certificati SSL, opzionale)

**Verifica Docker:**
```bash
docker --version && docker compose version
```

## ⚙️ Configurazione dettagliata

### 1. File .env

Il setup automatico crea il file `.env`, ma devi configurare le password:

```bash
# Apri .env e sostituisci <inserisci-password-*> con password reali
nano .env  # Linux/macOS
notepad .env  # Windows
```

**Configurazioni principali:**
```env
PROJECT_HOME=C:/opal-lab  # Windows: C:/opal-lab, Linux: /opt/opal-lab

# Password (OBBLIGATORIE)
SITEA_OPAL_ADMIN_PWD=password123
SITEB_OPAL_ADMIN_PWD=password456
CLIENT_VERSE_RSTUDIO_PWD=rstudio123

# SSL (opzionale)
OPAL_FORCE_HTTPS=false  # true = solo HTTPS, false = HTTP + HTTPS
```

### 2. Directory del progetto

Il setup automatico crea:
```
$PROJECT_HOME/
├── sitea/opal_home/data/dataset.csv
├── siteb/opal_home/data/dataset.csv
├── client/  (script R)
└── ssl/     (certificati SSL)
```

## 📊 Importazione e analisi dati

### RStudio (raccomandato)

1. Vai su http://localhost:8787
2. Login: `rstudio` / password dal `.env`
3. Esegui in sequenza:

```r
# Installa pacchetti necessari
source("install-packages.R")

# Importa dati di esempio (HTTP/HTTPS automatico)
source("setup-demo-data.R")

# Analisi federata demo
source("demo-analysis.R")
```

### Analisi manuale passo-passo

```r
library(DSI)
library(DSOpal)
library(dsBaseClient)

# Connessione automatica con fallback HTTP/HTTPS
login_data <- data.frame(
  server = c("siteA", "siteB"),
  url = c(
    Sys.getenv("SITEA_OPAL_URL", "https://sitea_opal:8443"),
    Sys.getenv("SITEB_OPAL_URL", "https://siteb_opal:8443")
  ),
  user = c("administrator", "administrator"),
  password = c(
    Sys.getenv("SITEA_OPAL_ADMIN_PWD"),
    Sys.getenv("SITEB_OPAL_ADMIN_PWD")
  ),
  table = c("LAB.dataset", "LAB.dataset"),
  options = c("ssl_verifyhost=0,ssl_verifypeer=0", "ssl_verifyhost=0,ssl_verifypeer=0"),
  stringsAsFactors = FALSE
)

# Connetti e analizza
conns <- datashield.login(logins = login_data, assign = TRUE)
ds.mean("D$age")                    # Media età
ds.table("D$gender")                # Distribuzione genere
model <- ds.glm("bmi ~ age + gender", data = "D", family = "gaussian")
datashield.logout(conns)
```

## 🔧 Risoluzione problemi

### Servizi non si avviano

```bash
# Verifica configurazione
docker compose config

# Controlla log
docker compose logs sitea_opal
docker compose logs siteb_opal
```

**Soluzioni comuni:**
- File `.env` non configurato → Esegui `./setup.sh`
- Directory `PROJECT_HOME` non esiste → Creala manualmente
- Porte occupate → Cambia porte nel `.env`
- Memoria insufficiente → Libera RAM per Docker

### Errori SSL/certificati

**Problema:** "SSL handshake failed" o "certificate unknown"

**Soluzioni:**
1. **Usa HTTP temporaneamente**: Modifica `.env`:
   ```env
   SITEA_OPAL_URL=http://sitea_opal:8080
   SITEB_OPAL_URL=http://siteb_opal:8080
   ```

2. **Rigenera certificati**:
   ```bash
   cd ssl
   ./generate-certs.sh
   ./setup-keystore.sh
   docker compose restart
   ```

3. **Forza HTTPS**: Nel `.env` usa `OPAL_FORCE_HTTPS=true`

### Errori connessione DataSHIELD

**Problema:** `datashield.login()` fallisce

**Verifiche:**
1. Servizi avviati? `docker compose ps` (tutti devono essere "healthy")
2. Dati importati? Esegui `source("setup-demo-data.R")`
3. Password corrette nel `.env`?
4. URL corretti? Gli script usano fallback automatico HTTP/HTTPS

### Tabelle non trovate

**Problema:** "Table LAB.dataset not found"

**Soluzioni:**
- Reimporta dati: `source("setup-demo-data.R")`
- Verifica via web: https://localhost:18443 → Projects → LAB
- Controlla file CSV in `$PROJECT_HOME/*/opal_home/data/`

## 🔐 Note SSL/HTTPS

L'ambiente funziona sia con HTTP che HTTPS:

- **HTTP** (semplice): Funziona sempre, meno sicuro
- **HTTPS** (raccomandato): Certificati self-signed per sviluppo
- **Fallback automatico**: Gli script provano HTTPS, poi HTTP

Per **produzione** usa certificati CA verificati e credenziali sicure.

## 📚 Struttura repository

```
opal-lab/
├── docker-compose.yml      # Configurazione servizi
├── .env.example           # Template configurazione
├── setup.sh              # 🆕 Setup automatico completo
├── ssl/                   # Script generazione certificati
├── scripts/               # Script R per demo e setup
├── sitea/, siteb/        # Dati di esempio
└── README.md             # Questa guida
```

## 🤝 Contribuire

Pull request benvenute! Per modifiche importanti, apri prima un issue.

## 📄 Licenza

[MIT](LICENSE)

## 📞 Supporto

- **Issues GitHub**: Problemi e domande
- **Docker**: `docker compose logs` per debug
- **DataSHIELD**: [Documentazione ufficiale](https://www.datashield.org/help)

**Tips per il debug:**
- `docker compose ps` → Stato servizi
- `docker compose logs [servizio]` → Log specifici
- `docker stats` → Uso risorse

## 🛑 Arresto dell'ambiente

```bash
# Ferma i servizi
docker compose down

# Ferma e rimuove anche i volumi (ATTENZIONE: cancella tutti i dati!)
docker compose down -v
```

## 🔧 Risoluzione problemi

### I container non si avviano

```bash
# Verifica la configurazione
docker compose config

# Controlla i log per errori
docker compose logs
```

**Possibili cause:**

- File `.env` non configurato correttamente
- Directory `PROJECT_HOME` non esistente
- Certificati SSL non generati (esegui `.\ssl\generate-certs.ps1`)
- Porte già occupate da altri servizi
- Docker non ha abbastanza memoria

### Errori SSL/Certificati

**Sintomi:** Errori "certificate unknown" o "SSL handshake failed"

**Soluzioni:**

1. **Rigenera i certificati**: `.\ssl\generate-certs.ps1 -Force`
2. **Verifica i certificati**: Controlla che esistano `ssl/sitea-keystore.p12` e `ssl/siteb-keystore.p12`
3. **Accetta l'avviso browser**: I certificati self-signed richiedono conferma manuale
4. **Per test rapidi**: Usa HTTP invece di HTTPS modificando temporaneamente gli URL

### Errori di connessione DataSHIELD

**Sintomi:** Errori durante `datashield.login()`

**Verifiche:**

1. I servizi Opal sono avviati? `docker compose ps`
2. I progetti "LAB" esistono in entrambi i siti?
3. Le password nel `.env` sono corrette?
4. Stai usando gli URL HTTPS corretti? (`https://sitea_opal:8443`, non `localhost`)
5. Hai incluso le opzioni SSL per ignorare i certificati self-signed?

### Problemi con i dati

**Sintomi:** Tabelle non trovate durante l'analisi

**Soluzioni:**

1. Verifica che i file CSV siano stati copiati nella directory `PROJECT_HOME`
2. Esegui nuovamente l'importazione tramite interfaccia web
3. Controlla che i nomi delle tabelle siano `LAB.dataset`

### Problemi di performance

```bash
# Controlla l'uso delle risorse
docker stats

# Libera spazio
docker system prune
```

## 🔐 Note sulla sicurezza

Questo ambiente usa:

- **Certificati self-signed** per HTTPS (solo per sviluppo/test)
- **Password in chiaro** nel file `.env` (solo per ambiente locale)
- **Connessioni sicure** tra tutti i componenti

**Per produzione**, sostituisci con:

- Certificati firmati da CA verificata
- Gestione sicura delle credenziali (vault, secrets manager)
- Configurazione di rete isolata

## 📚 Risorse utili

- [Documentazione DataSHIELD](https://www.datashield.org/help)
- [Manuale Opal](https://opaldoc.obiba.org/)
- [Tutorial DataSHIELD](https://data2knowledge.atlassian.net/wiki/spaces/DSDEV/overview)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Certificati SSL e HTTPS](https://letsencrypt.org/docs/)

## 🤝 Contribuire

Le pull request sono benvenute! Per modifiche importanti, apri prima un issue per discutere cosa vorresti cambiare.

## 📄 Licenza

[MIT](LICENSE)

## 📞 Contatti

**Supporto**:

- **Problemi generali**: Apri un [issue su GitHub](https://github.com/your-username/opal-lab/issues)
- **Problemi Windows**: Consulta [README-Windows.md](README-Windows.md)
- **Domande DataSHIELD**: [Documentazione ufficiale](https://www.datashield.org/help)

Per approfondire l’uso di DataSHIELD e dei pacchetti disponibili, si veda la documentazione ufficiale di DataSHIELD e Opal. Nel capitolo Tips and tricks della guida DataSHIELD viene spiegato come creare progetti e importare risorse tramite interfaccia o via R.
