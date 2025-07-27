# Script PowerShell per generare certificati SSL self-signed per Opal
#
param(
    [switch]$Force = $false  # Sovrascrivi certificati esistenti
)

$ErrorActionPreference = "Stop"

# Directory per i certificati
$sslDir = $PSScriptRoot
Set-Location $sslDir

Write-Host "🔐 Generazione certificati SSL multi-dominio per Opal..." -ForegroundColor Cyan

# Verifica se OpenSSL è disponibile
$opensslPath = $null
try {
    $opensslPath = Get-Command openssl -ErrorAction Stop
    Write-Host "  ✅ OpenSSL trovato: $($opensslPath.Source)" -ForegroundColor Green
} catch {
    # Prova percorsi comuni di installazione
    $commonPaths = @(
        "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
        "C:\OpenSSL-Win64\bin\openssl.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $opensslPath = Get-Command $path
            Write-Host "  ✅ OpenSSL trovato in: $path" -ForegroundColor Green
            break
        }
    }

    if (-not $opensslPath) {
        Write-Host "❌ OpenSSL non trovato. Soluzioni:" -ForegroundColor Red
        Write-Host "   1. Esegui: refreshenv" -ForegroundColor Yellow
        Write-Host "   2. Riapri PowerShell" -ForegroundColor Yellow
        Write-Host "   3. Verifica installazione: choco list openssl" -ForegroundColor Yellow
        exit 1
    }
}

# Funzione per generare certificato multi-dominio
function New-SelfSignedCert {
    param($siteName, $commonName)

    $keyFile = "$siteName-key.pem"
    $certFile = "$siteName-cert.pem"
    $p12File = "$siteName-keystore.p12"
    $configFile = "$siteName.conf"
    $password = "opalssl"

    if ((Test-Path $keyFile) -and (Test-Path $certFile) -and (Test-Path $p12File) -and !$Force) {
        Write-Host "  ⚠️  Certificati per $siteName già esistenti (usa -Force per sovrascrivere)" -ForegroundColor Yellow
        return
    }

    Write-Host "  🔑 Generazione certificato multi-dominio per $siteName..." -ForegroundColor Green

    # Crea file di configurazione con SAN per supportare sia container che localhost
    @"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C=IT
ST=Italy
L=City
O=Opal Lab
OU=$siteName
CN=$commonName

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $commonName
DNS.2 = localhost
DNS.3 = 127.0.0.1
IP.1 = 127.0.0.1
"@ | Out-File -FilePath $configFile -Encoding UTF8

    # Genera chiave privata
    & $opensslPath.Source genrsa -out $keyFile 2048

    # Genera certificato con SAN
    & $opensslPath.Source req -new -x509 -key $keyFile -out $certFile -days 365 -config $configFile -extensions v3_req

    # Genera keystore P12 per Opal
    & $opensslPath.Source pkcs12 -export -out $p12File -inkey $keyFile -in $certFile -password "pass:$password"

    # Pulisci file temporaneo
    Remove-Item $configFile -Force

    Write-Host "    ✅ $keyFile, $certFile e $p12File creati (supporto localhost + container)" -ForegroundColor Green
}

# Genera certificati per entrambi i siti
New-SelfSignedCert -siteName "sitea" -commonName "sitea_opal"
New-SelfSignedCert -siteName "siteb" -commonName "siteb_opal"

Write-Host ""
Write-Host "✅ Certificati SSL multi-dominio generati:" -ForegroundColor Green
Write-Host "  - sitea-cert.pem / sitea-key.pem / sitea-keystore.p12"
Write-Host "  - siteb-cert.pem / siteb-key.pem / siteb-keystore.p12"
Write-Host ""
Write-Host "🌐 I certificati supportano:" -ForegroundColor Cyan
Write-Host "  - sitea_opal / siteb_opal (nomi container)"
Write-Host "  - localhost (accesso dal laptop)"
Write-Host "  - 127.0.0.1 (IP locale)"
Write-Host ""
Write-Host "🔗 Accedi a:" -ForegroundColor Green
Write-Host "  - Site A: https://localhost:18443"
Write-Host "  - Site B: https://localhost:28443"
Write-Host ""
Write-Host "⚠️  Certificati self-signed per SVILUPPO - accetta l'avviso sicurezza nel browser" -ForegroundColor Yellow
