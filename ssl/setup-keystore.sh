#!/bin/bash
#
# Script per convertire certificati PEM in keystore PKCS12 per Opal
#

set -e

SSL_DIR="$(dirname "$0")"
cd "$SSL_DIR"

# Password per keystore (puoi cambiarla nel file .env)
KEYSTORE_PWD="${SSL_KEYSTORE_PASSWORD:-opalssl}"

echo "🔐 Conversione certificati PEM in keystore PKCS12..."

# Verifica che i certificati PEM esistano
if [[ ! -f "sitea-cert.pem" || ! -f "sitea-key.pem" ]]; then
    echo "❌ Certificati Site A non trovati. Esegui prima ./generate-certs.sh"
    exit 1
fi

if [[ ! -f "siteb-cert.pem" || ! -f "siteb-key.pem" ]]; then
    echo "❌ Certificati Site B non trovati. Esegui prima ./generate-certs.sh"
    exit 1
fi

# Crea keystore PKCS12 per Site A
echo "  🔑 Creazione keystore per Site A..."
openssl pkcs12 -export \
    -in sitea-cert.pem \
    -inkey sitea-key.pem \
    -out sitea-keystore.p12 \
    -name "sitea_opal" \
    -passout "pass:$KEYSTORE_PWD"

# Crea keystore PKCS12 per Site B  
echo "  🔑 Creazione keystore per Site B..."
openssl pkcs12 -export \
    -in siteb-cert.pem \
    -inkey siteb-key.pem \
    -out siteb-keystore.p12 \
    -name "siteb_opal" \
    -passout "pass:$KEYSTORE_PWD"

# Crea un keystore comune (Opal può usare lo stesso)
echo "  🔑 Creazione keystore comune..."
cp sitea-keystore.p12 keystore.p12

# Imposta permessi
chmod 600 *.p12

echo "✅ Keystore PKCS12 creati:"
echo "  - sitea-keystore.p12"
echo "  - siteb-keystore.p12" 
echo "  - keystore.p12 (comune)"
echo ""
echo "🔧 Password keystore: $KEYSTORE_PWD"
echo "   (configura SSL_KEYSTORE_PASSWORD nel file .env se diversa)"