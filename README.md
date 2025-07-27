# opal‑lab

[![Docker Compose](https://img.shields.io/badge/docker--compose-supported-blue.svg)](https://docs.docker.com/compose/)
[![DataSHIELD](https://img.shields.io/badge/DataSHIELD-compatible-green.svg)](https://www.datashield.org/)
[![Opal](https://img.shields.io/badge/Opal-4.x-orange.svg)](https://www.obiba.org/pages/products/opal/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Laboratorio didattico per sperimentare l'analisi federata di dati con DataSHIELD. Questo repository fornisce un ambiente Docker completo con due server Opal simulati (Site A e Site B) e un client R per l'analisi.

**DataSHIELD** permette di analizzare dati distribuiti senza spostarli dai siti dove sono custoditi, garantendo privacy e conformità alle normative.

**🔐 SSL/HTTPS**: L'ambiente supporta connessioni sicure con certificati self-signed multi-dominio per simulare un ambiente di produzione.

## 📋 Contenuto del repository

```
opal-lab/
├── docker-compose.yml              # Definizione dei servizi Docker
├── .env.example                    # Template per le variabili d'ambiente
├── ssl/
│   └── generate-certs.ps1          # 🔐 Generazione certificati SSL multi-dominio
├── sitea/opal_home/data/
│   └── dataset.csv                 # Dati di esempio per Site A
├── siteb/opal_home/data/
│   └── dataset.csv                 # Dati di esempio per Site B
├── scripts/
│   ├── setup-demo-data.R           # Script per importare dati di esempio
│   ├── demo-analysis.R             # Script per demo analisi federata
│   └── install-packages.R          # Installazione automatica pacchetti R
└── README.md                       # Questa documentazione
```

## 🔧 Prerequisiti

- **Docker Desktop** installato e funzionante
- **4 GB di RAM** disponibili per Docker
- **OpenSSL** per generazione certificati SSL
- Browser web per accedere alle interfacce

### Verifica Docker

```bash
docker --version
docker compose version
```

### Installazione OpenSSL

**Windows:**
```powershell
# Con Chocolatey (da PowerShell come amministratore)
choco install openssl

# Oppure scarica da: https://slproweb.com/products/Win32OpenSSL.html
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install openssl

# CentOS/RHEL
sudo yum install openssl
```

**macOS:**
```bash
# Con Homebrew
brew install openssl
```

## ⚙️ Configurazione rapida

### 1. Clona il repository

```bash
git clone https://github.com/CorradoLanera/opal-lab.git
cd opal-lab
```

### 2. Configura le variabili d'ambiente

```bash
# Copia il template
cp .env.example .env

# Apri il file per modificarlo
# Windows: notepad .env
# Linux/macOS: nano .env
```

**Configura almeno queste variabili nel file `.env`:**

```env
PROJECT_HOME=C:/opal-lab               # Windows
# PROJECT_HOME=/opt/opal-lab           # Linux/macOS

SITEA_OPAL_ADMIN_PWD=TuaPasswordSiteA  # Password amministratore Site A
SITEB_OPAL_ADMIN_PWD=TuaPasswordSiteB  # Password amministratore Site B
CLIENT_VERSE_RSTUDIO_PWD=TuaPasswordR  # Password per RStudio
```

> ⚠️ **Importante**: Usa password forti (minimo 8 caratteri con lettere, numeri e simboli)

### 3. Setup SSL completo (un solo comando!)

```powershell
# Windows PowerShell
.\setup-ssl.ps1
```

Questo comando automaticamente:

- ✅ Genera certificati SSL multi-dominio (funzionano per container + localhost)
- ✅ Crea keystore PKCS12 per ogni sito Opal
- ✅ Copia tutto nella directory `$PROJECT_HOME/ssl`
- ✅ Verifica la configurazione `.env`
- ✅ Fornisce istruzioni per i passi successivi

> 💡 **Multi-dominio**: I certificati supportano sia i nomi container (`sitea_opal`, `siteb_opal`) che `localhost` per accesso diretto dal browser.green.svg)](https://www.datashield.org/)

### 4. Crea le directory per i dati

```bash
# Windows PowerShell
mkdir C:\opal-lab\sitea\opal_home\data, C:\opal-lab\siteb\opal_home\data, C:\opal-lab\client

# Linux/macOS
mkdir -p /opt/opal-lab/{sitea,siteb,client}/opal_home/data
```

### 5. Copia i dati di esempio e gli script

```bash
# Windows PowerShell
copy sitea\opal_home\data\dataset.csv C:\opal-lab\sitea\opal_home\data\
copy siteb\opal_home\data\dataset.csv C:\opal-lab\siteb\opal_home\data\
copy scripts\*.R C:\opal-lab\client\

# Linux/macOS
cp sitea/opal_home/data/dataset.csv /opt/opal-lab/sitea/opal_home/data/
cp siteb/opal_home/data/dataset.csv /opt/opal-lab/siteb/opal_home/data/
cp scripts/*.R /opt/opal-lab/client/
```

## 🚀 Avvio dell'ambiente

### Avvia tutti i servizi

```bash
docker compose up -d
```

La prima volta scaricherà le immagini Docker (circa 2-3 GB). Al termine avrai:

- **🔐 Site A Opal**: https://localhost:18443 (HTTPS sicuro)
- **🔐 Site B Opal**: https://localhost:28443 (HTTPS sicuro)
- **RStudio**: http://localhost:8787

> 💡 **Nota SSL**: I certificati sono self-signed per sviluppo. Il browser mostrerà un avviso di sicurezza - clicca "Procedi comunque" o "Advanced → Proceed to localhost".

### Verifica che tutto funzioni

```bash
docker compose ps
```

Dovresti vedere tutti i servizi in stato "healthy".

## 📊 Importazione dei dati

### Metodo 1: Script automatico R

Accedi a RStudio (http://localhost:8787) con:
- **Username**: `rstudio`
- **Password**: quella configurata in `CLIENT_VERSE_RSTUDIO_PWD`

Nel terminale R di RStudio esegui:

```r
# Prima installa i pacchetti necessari
source("install-packages.R")

# Poi importa i dati (ora con supporto HTTPS!)
source("setup-demo-data.R")

# Infine esegui l'analisi demo (opzionale)
source("demo-analysis.R")
```

### Metodo 2: Interfaccia web manuale

Per ogni sito (Site A e Site B):

1. Apri il browser e vai su https://localhost:18443 (Site A) o https://localhost:28443 (Site B)
2. **Accetta l'avviso SSL** (certificato self-signed per sviluppo)
3. Login con:
   - **Username**: `administrator`
   - **Password**: quella configurata nel `.env`
4. Vai su **Projects** → **Add Project**
5. Nome progetto: `LAB`
6. Vai su **Tables** → **Import**
7. Seleziona il file CSV: `/srv/data/dataset.csv`
8. Segui il wizard per completare l'importazione

## 🔬 Analisi federata con DataSHIELD

### Demo automatica

In RStudio, esegui lo script di demo:

```r
source("demo-analysis.R")
```

### Analisi manuale passo-passo

```r
# 1. Carica le librerie necessarie
library(DSI)
library(DSOpal)
library(dsBaseClient)

# 2. Configura le connessioni ai due siti (ora con HTTPS!)
login_data <- data.frame(
  server = c("siteA", "siteB"),
  url = c(
    "https://sitea_opal:8443",
    "https://siteb_opal:8443"
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

# 3. Connetti ai siti e carica i dati
conns <- datashield.login(logins = login_data, assign = TRUE)

# 4. Esegui analisi federate (i dati rimangono sui siti remoti!)
ds.mean("D$age")                    # Media età
ds.var("D$bmi")                     # Varianza BMI
ds.table("D$gender")                # Distribuzione genere

# 5. Modello federato
model <- ds.glm("bmi ~ age + gender", data = "D", family = "gaussian")
summary(model)

# 6. Chiudi le connessioni
datashield.logout(conns)
```

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
