# 🔬 opal-lab

[![Docker Compose](https://img.shields.io/badge/docker--compose-supported-blue.svg?logo=docker)](https://docs.docker.com/compose/)
[![DataSHIELD](https://img.shields.io/badge/DataSHIELD-compatible-green.svg?logo=r)](https://www.datashield.org/)
[![Opal](https://img.shields.io/badge/Opal-4.x-orange.svg?logo=obiba)](https://www.obiba.org/pages/products/opal/)
[![RStudio](https://img.shields.io/badge/RStudio-ready-blue.svg?logo=rstudio)](https://rstudio.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20windows%20%7C%20macOS-lightgrey.svg?logo=docker)](https://docker.com/)

> **Ambiente completo Docker per sperimentare l'analisi federata con DataSHIELD**

**opal-lab** è un ambiente di sviluppo containerizzato che simula una rete di analisi federata con DataSHIELD. Include due server Opal indipendenti (Site A e Site B) e un client RStudio preconfigurato per eseguire analisi distribuite sui dati senza mai spostarli dai siti originali.

**Caratteristiche principali:**

- 🚀 **Setup automatico** in 3 comandi
- 🔒 **Sicurezza SSL/HTTPS** configurabile
- 📊 **Demo interattive** con dati di esempio
- 🐳 **Completamente containerizzato** con Docker
- 📝 **Script R pronti** per iniziare subito
- 🔧 **Debug tools** integrati

Perfetto per ricercatori, data scientist e sviluppatori che vogliono esplorare l'analisi federata senza complesse configurazioni di rete.

## 📋 Requisiti

### Tutti i sistemi
- **Docker Desktop** (4 GB RAM disponibili)
- **Git**

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
```

Windows (PowerShell):
```powershell
docker --version; docker compose version
```


## 🚀 Setup rapido (3 comandi)

### Linux/macOS
```bash
# 1. Clona il repository
git clone https://github.com/CorradoLanera/opal-lab.git
cd opal-lab

# 2. Setup automatico (crea .env, directory, certificati SSL)
./setup.sh

# 3. Avvia i servizi
docker compose up -d
```

### Windows (PowerShell)
```powershell
# 1. Clona il repository
git clone https://github.com/CorradoLanera/opal-lab.git
cd opal-lab

# 2. Setup automatico (crea .env, directory, certificati SSL)
.\setup.ps1

# 3. Avvia i servizi
docker compose up -d
```

Dopo 2-3 minuti avrai tutto pronto:

- **RStudio**: http://localhost:8787
- **Site A**: https://localhost:18443 (HTTPS) o http://localhost:18880 (HTTP)
- **Site B**: https://localhost:28443 (HTTPS) o http://localhost:28880 (HTTP)

### Directory del progetto

Il setup automatico crea (se non già presenti) le seguenti directory:
```
$PROJECT_HOME/
├── sitea/opal_home/data/dataset.csv
├── siteb/opal_home/data/dataset.csv
├── client/  (script R)
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

# Password (OBBLIGATORIE - sostituisci i placeholder!)
SITEA_OPAL_ADMIN_PWD=password123
SITEB_OPAL_ADMIN_PWD=password456
CLIENT_VERSE_RSTUDIO_PWD=rstudio123

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
```

## 🔐 Note SSL/HTTPS

L'ambiente funziona sia con HTTP che HTTPS:

- **HTTP** (semplice): Funziona sempre, meno sicuro
- **HTTPS** (raccomandato): Certificati self-signed per sviluppo
- **Fallback automatico**: Gli script provano HTTPS, poi HTTP

Per **produzione** usa certificati CA verificati e credenziali sicure.


## 📊 Analisi dati con RStudio

### Procedura automatica (raccomandato)

1. Vai su http://localhost:8787
2. Login: `rstudio` / password dal `.env`
3. Esegui in sequenza:

```r
# Installa pacchetti necessari
source("install-packages.R")

# Importa dati di esempio (HTTP/HTTPS automatico)
source("setup-demo-data.R")
```

## 🤝 Contribuire

Pull request benvenute! Per modifiche importanti, apri prima un [issue su GitHub](https://github.com/your-username/opal-lab/issues).


## 📚 Risorse utili

- [Documentazione DataSHIELD](https://www.datashield.org/help)
- [Manuale Opal](https://opaldoc.obiba.org/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
