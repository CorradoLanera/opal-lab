#!/bin/bash
#
# Script per generare certificati SSL self‑signed multi‑dominio per Opal.
#
# Questo script produce chiavi e certificati che includono Subject
# Alternative Names (SAN) per i nomi dei container (sitea_opal e
# siteb_opal) e per localhost/127.0.0.1.  I pacchetti DataSHIELD, DSOpal
# e i browser moderni rifiutano i certificati che non includono SAN,
# quindi le opzioni multi‑dominio sono indispensabili.
# Utilizzare le opzioni `ssl_verifyhost=0` e `ssl_verifypeer=0` sul
# client R per accettare questi certificati self‑signed.

set -e

# Directory per i certificati
SSL_DIR="$(dirname "$0")"
cd "$SSL_DIR"

echo "🔐 Generazione certificati SSL self‑signed per Opal (multi‑dominio)..."

# Funzione ausiliaria per generare certificati e chiavi con SAN
generate_cert() {
  local site_name=$1
  local common_name=$2

  local key_file="${site_name}-key.pem"
  local cert_file="${site_name}-cert.pem"
  local config_file="${site_name}.conf"

  cat > "$config_file" <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = IT
ST = Italy
L = City
O = Opal Lab
OU = ${site_name}
CN = ${common_name}

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${common_name}
DNS.2 = localhost
DNS.3 = 127.0.0.1
IP.1 = 127.0.0.1
EOF

  # Genera chiave privata
  openssl genrsa -out "$key_file" 2048

  # Genera certificato self‑signed con SAN
  openssl req -new -x509 -key "$key_file" -out "$cert_file" -days 365 \
    -config "$config_file" -extensions v3_req

  # Rimuovi file di configurazione temporaneo
  rm -f "$config_file"

  echo "  ✅ Certificato per ${site_name} generato (supporta ${common_name}, localhost, 127.0.0.1)"
}

# Genera certificati per Site A e Site B
generate_cert "sitea" "sitea_opal"
generate_cert "siteb" "siteb_opal"

# Imposta permessi stretti sui file PEM
chmod 600 *.pem

echo "✅ Certificati generati:"
echo "  - sitea-cert.pem / sitea-key.pem"
echo "  - siteb-cert.pem / siteb-key.pem"
echo ""
echo "⚠️  Questi certificati sono self‑signed per uso di SVILUPPO. Per ambienti di produzione usa certificati firmati da CA riconosciute."
