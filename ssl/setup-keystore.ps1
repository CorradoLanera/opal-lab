# Script PowerShell per convertire certificati PEM in keystore PKCS12
#
param(
    [string]$KeystorePassword = "opalssl",  # Password per keystore
    [switch]$Force = $false                 # Sovrascrivi keystore esistenti
)

$ErrorActionPreference = "Stop"

# Directory per i certificati
$sslDir = $PSScriptRoot
Set-Location $sslDir

Write-Host "📦 Conversione in keystore PKCS12..." -ForegroundColor Cyan
Write-Host "🔐 Conversione certificati PEM in keystore PKCS12..." -ForegroundColor Cyan

# Verifica se OpenSSL è disponibile
$opensslPath = $null
try {
    $opensslPath = Get-Command openssl -ErrorAction Stop
    Write-Host "  ✅ OpenSSL trovato: $($opensslPath.Source)" -ForegroundColor Green
} catch {
    # Prova percorsi comuni di installazione
    $commonPaths = @(
        "C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
        "C:\OpenSSL-Win64\bin\openssl.exe",
        "C:\Tools\OpenSSL\bin\openssl.exe"
    )

    Write-Host "  🔍 Ricerca OpenSSL nei percorsi comuni..." -ForegroundColor Yellow
    foreach ($path in $commonPaths) {
        Write-Host "    Controllo: $path" -ForegroundColor Gray
        if (Test-Path $path) {
            $opensslPath = Get-Command $path
            Write-Host "  ✅ OpenSSL trovato in: $path" -ForegroundColor Green
            break
        }
    }

    if (-not $opensslPath) {
        Write-Host "❌ OpenSSL non trovato. Soluzioni:" -ForegroundColor Red
        Write-Host "   1. Esegui: refreshenv" -ForegroundColor Yellow
        Write-Host "   2. Riapri PowerShell come amministratore" -ForegroundColor Yellow
        Write-Host "   3. Verifica installazione: Get-Command openssl" -ForegroundColor Yellow
        Write-Host "   4. Se installato: riavvia il computer" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📍 Percorsi controllati:" -ForegroundColor Gray
        foreach ($path in $commonPaths) {
            Write-Host "   - $path" -ForegroundColor Gray
        }
        exit 1
    }
}

# Funzione per convertire certificati in keystore
function Convert-ToKeystore {
    param($siteName)

    $keyFile = "$siteName-key.pem"
    $certFile = "$siteName-cert.pem"
    $keystoreFile = "$siteName-keystore.p12"

    # Verifica che i certificati PEM esistano
    if (-not (Test-Path $keyFile) -or -not (Test-Path $certFile)) {
        Write-Host "  ❌ Certificati PEM per $siteName non trovati" -ForegroundColor Red
        Write-Host "     Esegui prima: .\generate-certs.ps1" -ForegroundColor Yellow
        return $false
    }

    if ((Test-Path $keystoreFile) -and !$Force) {
        Write-Host "  ⚠️  Keystore per $siteName già esistente (usa -Force per sovrascrivere)" -ForegroundColor Yellow
        return $true
    }

    Write-Host "  🔑 Conversione keystore per $siteName..." -ForegroundColor Green

    try {
        # Converti in PKCS12
        & $opensslPath.Source pkcs12 -export `
            -in $certFile `
            -inkey $keyFile `
            -out $keystoreFile `
            -name "$siteName-opal" `
            -passout "pass:$KeystorePassword"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✅ $keystoreFile creato" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    ❌ Errore nella conversione (exit code: $LASTEXITCODE)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "    ❌ Errore durante conversione: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Converti certificati per entrambi i siti
$success = @()
$success += Convert-ToKeystore -siteName "sitea"
$success += Convert-ToKeystore -siteName "siteb"

if ($success -contains $false) {
    Write-Host ""
    Write-Host "❌ Errori durante la conversione keystore" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Keystore PKCS12 creati con successo:" -ForegroundColor Green
Write-Host "  - sitea-keystore.p12"
Write-Host "  - siteb-keystore.p12"
Write-Host "  - Password keystore: $KeystorePassword"
Write-Host ""
Write-Host "🔐 I keystore sono pronti per essere usati da Opal" -ForegroundColor Cyan
Write-Host "   Assicurati che SSL_KEYSTORE_PASSWORD nel .env sia: $KeystorePassword" -ForegroundColor Yellow
