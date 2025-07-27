#!/bin/bash
#
# Script di setup completo per opal-lab
# Risolve tutti i problemi SSL e configura l'ambiente
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Setup completo opal-lab"
echo "=========================="
echo ""

# 1. Verifica file .env
if [[ ! -f ".env" ]]; then
    echo "📝 Creazione file .env..."
    cp .env.example .env
    echo "⚠️  IMPORTANTE: Configura le password nel file .env prima di continuare"
    echo "   Apri il file .env e sostituisci <inserisci-password-*> con password reali"
    exit 1
fi

# 2. Leggi PROJECT_HOME dal file .env
PROJECT_HOME=$(grep "^PROJECT_HOME=" .env | cut -d'=' -f2)
if [[ -z "$PROJECT_HOME" ]]; then
    echo "❌ PROJECT_HOME non configurato nel file .env"
    exit 1
fi

echo "📂 PROJECT_HOME: $PROJECT_HOME"

# 3. Crea directory necessarie
echo "📁 Creazione directory..."
mkdir -p "$PROJECT_HOME"/{sitea,siteb,client}/opal_home/data
mkdir -p "$PROJECT_HOME/ssl"
echo "   ✅ Directory create"

# 4. Copia dati di esempio
echo "📊 Copia dati di esempio..."
if [[ -f "sitea/opal_home/data/dataset.csv" ]]; then
    cp sitea/opal_home/data/dataset.csv "$PROJECT_HOME/sitea/opal_home/data/"
fi
if [[ -f "siteb/opal_home/data/dataset.csv" ]]; then
    cp siteb/opal_home/data/dataset.csv "$PROJECT_HOME/siteb/opal_home/data/"
fi
echo "   ✅ Dati copiati"

# 5. Copia script R
echo "📋 Copia script R..."
cp scripts/*.R "$PROJECT_HOME/client/"
echo "   ✅ Script copiati"

# 6. Setup SSL (opzionale ma raccomandato)
echo ""
echo "🔐 Setup SSL..."
if [[ -x "ssl/generate-certs.sh" && -x "ssl/setup-keystore.sh" ]]; then
    cd ssl
    ./generate-certs.sh
    ./setup-keystore.sh
    cd ..
    
    # Copia certificati nella directory di progetto
    cp ssl/*.p12 "$PROJECT_HOME/ssl/"
    cp ssl/*.pem "$PROJECT_HOME/ssl/" 2>/dev/null || true
    echo "   ✅ Certificati SSL generati e copiati"
else
    echo "   ⚠️  Script SSL non trovati o non eseguibili"
    echo "   L'ambiente funzionerà comunque con HTTP"
fi

# 7. Verifica configurazione Docker
echo ""
echo "🐳 Verifica configurazione Docker..."
if command -v docker >/dev/null 2>&1; then
    if docker compose config >/dev/null 2>&1; then
        echo "   ✅ Configurazione Docker valida"
    else
        echo "   ❌ Errori nella configurazione Docker"
        docker compose config
        exit 1
    fi
else
    echo "   ❌ Docker non trovato"
    exit 1
fi

echo ""
echo "✅ Setup completato!"
echo ""
echo "📋 Passi successivi:"
echo "   1. Avvia i servizi: docker compose up -d"
echo "   2. Attendi che tutti i servizi siano healthy: docker compose ps"
echo "   3. Accedi a RStudio: http://localhost:8787"
echo "   4. Esegui setup dati: source('install-packages.R'); source('setup-demo-data.R')"
echo "   5. Analisi demo: source('demo-analysis.R')"
echo ""
echo "🌐 Interfacce disponibili:"
echo "   - RStudio: http://localhost:8787"
if [[ -f "$PROJECT_HOME/ssl/sitea-keystore.p12" ]]; then
    echo "   - Site A: https://localhost:18443 (HTTPS) o http://localhost:18880 (HTTP)"
    echo "   - Site B: https://localhost:28443 (HTTPS) o http://localhost:28880 (HTTP)"
else
    echo "   - Site A: http://localhost:18880 (HTTP)"
    echo "   - Site B: http://localhost:28880 (HTTP)"
fi