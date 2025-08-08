# 🔬 opal-lab

[![Docker Compose](https://img.shields.io/badge/docker--compose-supported-blue.svg?logo=docker)](https://docs.docker.com/compose/)
[![DataSHIELD](https://img.shields.io/badge/DataSHIELD-compatible-green.svg?logo=r)](https://www.datashield.org/)
[![Opal](https://img.shields.io/badge/Opal-4.x-orange.svg?logo=obiba)](https://www.obiba.org/pages/products/opal/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20windows%20%7C%20macOS-lightgrey.svg?logo=docker)](https://docker.com/)

> **Ambiente completo Docker per sperimentare l'analisi federata con DataSHIELD**

**opal-lab** è un ambiente di sviluppo containerizzato che simula una rete di analisi federata con DataSHIELD. Include due server Opal indipendenti (Site A e Site B), ciascuno con i loro server Rock e MongoDB, che puoi interrogare dalla tua installazione locale di R/RStudio/Positron per eseguire analisi distribuite sui dati senza mai spostarli dai siti originali.

**Caratteristiche principali:**

- 🚀 **Setup automatico** in 3 comandi
- 🔒 **Sicurezza SSL/HTTPS** configurabile
- 📊 **Demo interattive** con dati di esempio
- 🐳 **Completamente containerizzato** con Docker
- 📝 **Script R pronti** per iniziare subito
- 🔧 **Debug tools** integrati
- 💻 **Usa il tuo ambiente locale** - nessun browser necessario

Perfetto per ricercatori, data scientist e sviluppatori che vogliono esplorare l'analisi federata senza complesse configurazioni di rete.

## 📋 Requisiti

### Tutti i sistemi
- **Docker Desktop** (4 GB RAM disponibili)
- **Git**
- **R 4.0+** (installazione locale)
- **RStudio/Positron** (opzionale ma raccomandato)

### Linux/macOS
- **Bash** (di solito pre-installato)
- **OpenSSL** (per certificati SSL, opzionale)

### Windows
- **PowerShell 5.1+** (pre-installato su Windows 10/11)
- **OpenSSL** (opzionale, per HTTPS): `choco install openssl`

**Verifica installazione:**

Linux/macOS:
```bash
docker --version && docker compose version
R --version
```

Windows (PowerShell):
```powershell
docker --version; docker compose version
R --version
```


## 🚀 Setup rapido (3 comandi)

### Linux/macOS
```bash
# 1. Clona il repository
git clone https://github.com/CorradoLanera/opal-lab.git
cd opal-lab

# 2. Setup automatico (crea .env, directory, certificati SSL)
./setup.sh

# 3. Avvia i servizi Opal
docker compose up -d
```

### Windows (PowerShell)
```powershell
# 1. Clona il repository
git clone https://github.com/CorradoLanera/opal-lab.git
cd opal-lab

# 2. Setup automatico (crea .env, directory, certificati SSL)
.\setup.ps1

# 3. Avvia i servizi Opal
docker compose up -d
```

Dopo 2-3 minuti avrai i server Opal pronti:

- **Site A**: https://localhost:18443 (HTTPS) o http://localhost:18880 (HTTP)
- **Site B**: https://localhost:28443 (HTTPS) o http://localhost:28880 (HTTP)

### Directory del progetto

Il setup automatico crea (se non già presenti) le seguenti directory:
```
$PROJECT_HOME/
├── sitea/opal_home/data/dataset.csv
├── siteb/opal_home/data/dataset.csv
└── ssl/     (certificati SSL)
```


## ⚙️ Configurazione dettagliata

### File .env

Il setup automatico crea il file `.env`, ma devi configurare le password:

**Linux/macOS:**
```bash
nano .env  # o vim, gedit, etc.
```

**Windows:**
```powershell
notepad .env    # Notepad
code .env       # VS Code
```

**Configurazioni principali:**
```env
# Percorso per dati persistenti
PROJECT_HOME=C:/opal-lab        # Windows
PROJECT_HOME=/opt/opal-lab      # Linux/macOS

# Password Opal (OBBLIGATORIE - sostituisci i placeholder!)
SITEA_OPAL_ADMIN_PWD=password123
SITEB_OPAL_ADMIN_PWD=password456

# SSL (opzionale)
OPAL_FORCE_HTTPS=false  # true = solo HTTPS, false = HTTP + HTTPS
```


## 🛑 Gestione ambiente

**Comandi universali:**

```bash
# Arresta i servizi
docker compose down

# Arresta e rimuove anche i volumi (ATTENZIONE: cancella tutti i dati!)
docker compose down -v

# Riavvia tutto
docker compose restart

# Verifica stato servizi
docker compose ps
```

## 🔐 Note SSL/HTTPS

L'ambiente funziona sia con HTTP che HTTPS:

- **HTTP** (semplice): Funziona sempre, meno sicuro
- **HTTPS** (raccomandato): Certificati self-signed per sviluppo
- **Fallback automatico**: Gli script provano HTTPS, poi HTTP

Per **produzione** usa certificati CA verificati e credenziali sicure.


## 📊 Analisi dati con R locale

### Setup iniziale (una tantum)

1. **Installa i pacchetti DataSHIELD** nel tuo R locale:
```r
# Nel tuo R/RStudio/Positron locale
source("scripts/install-packages.R")
```

2. **Configura le variabili d'ambiente** (opzionale):
```r
# Crea/modifica il file .Renviron nella tua home directory
Sys.setenv(SITEA_OPAL_ADMIN_PWD = "tua-password-sitea")
Sys.setenv(SITEB_OPAL_ADMIN_PWD = "tua-password-siteb")
```

3. **Esegui gli script di setup**:
```r
# Importa dati di esempio nei server Opal
source("scripts/setup-demo-data.R")

# Test connessioni
source("scripts/test-connection.R")

# Analisi di esempio
source("scripts/demo-analysis.R")
```


## 🤝 Contribuire

Pull request benvenute! Per modifiche importanti, apri prima un [issue su GitHub](https://github.com/your-username/opal-lab/issues).


## 📚 Risorse utili

- [Documentazione DataSHIELD](https://www.datashield.org/help)
- [Manuale Opal](https://opaldoc.obiba.org/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
