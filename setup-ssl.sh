#!/bin/bash
#
# Script completo per configurare SSL/HTTPS per opal-lab
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔐 Setup SSL/HTTPS per opal-lab"
echo "================================"
echo ""

# 1. Crea directory SSL se non esiste
if [[ ! -d "ssl" ]]; then
    mkdir ssl
    echo "📁 Directory ssl/ creata"
fi

# 2. Genera certificati PEM
echo "🔑 Generazione certificati SSL..."
cd ssl
./generate-certs.sh

# 3. Converti in keystore PKCS12
echo ""
echo "📦 Conversione in keystore PKCS12..."
./setup-keystore.sh

cd ..

# 4. Verifica che PROJECT_HOME sia configurato
if [[ -f ".env" ]]; then
    PROJECT_HOME=$(grep "^PROJECT_HOME=" .env | cut -d'=' -f2)
    if [[ -n "$PROJECT_HOME" ]]; then
        echo ""
        echo "📂 Preparazione directory SSL per Docker..."
        mkdir -p "$PROJECT_HOME/ssl"
        cp ssl/*.p12 "$PROJECT_HOME/ssl/"
        cp ssl/*.pem "$PROJECT_HOME/ssl/"
        echo "   ✅ Certificati copiati in $PROJECT_HOME/ssl/"
    else
        echo ""
        echo "⚠️  PROJECT_HOME non configurato nel file .env"
        echo "   I certificati sono pronti in ./ssl/"
        echo "   Copia manualmente i file .p12 in \$PROJECT_HOME/ssl/ prima di avviare Docker"
    fi
else
    echo ""
    echo "⚠️  File .env non trovato"
    echo "   Copia .env.example in .env e configuralo prima di proseguire"
fi

echo ""
echo "✅ Setup SSL completato!"
echo ""
echo "📋 Passi successivi:"
echo "   1. Configura il file .env con le tue password"
echo "   2. Avvia i servizi: docker compose up -d"
echo "   3. Accedi via HTTPS:"
echo "      - Site A: https://localhost:18443"
echo "      - Site B: https://localhost:28443"
echo ""
echo "⚠️  Certificati self-signed: il browser mostrerà un avviso di sicurezza"
echo "   Clicca su 'Avanzate' → 'Procedi al sito' per accettare il certificato"