# Script PowerShell completo per configurare SSL/HTTPS per opal-lab
#

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
Set-Location $scriptDir

Write-Host "🔐 Setup SSL/HTTPS per opal-lab" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 1. Crea directory SSL se non esiste
if (-not (Test-Path "ssl")) {
    New-Item -ItemType Directory -Name "ssl" | Out-Null
    Write-Host "📁 Directory ssl\ creata" -ForegroundColor Green
}

# 2. Genera certificati PEM
Write-Host "🔑 Generazione certificati SSL..." -ForegroundColor Yellow
Set-Location ssl
try {
    .\generate-certs.ps1
} catch {
    Write-Host "❌ Errore durante la generazione certificati: $_" -ForegroundColor Red
    exit 1
}

# 3. Converti in keystore PKCS12
Write-Host ""
Write-Host "📦 Conversione in keystore PKCS12..." -ForegroundColor Yellow
try {
    .\setup-keystore.ps1
} catch {
    Write-Host "❌ Errore durante la conversione keystore: $_" -ForegroundColor Red
    exit 1
}

Set-Location ..

# 4. Verifica che PROJECT_HOME sia configurato
if (Test-Path ".env") {
    $envContent = Get-Content ".env"
    $projectHomeLine = $envContent | Where-Object { $_ -match "^PROJECT_HOME=" }
    
    if ($projectHomeLine) {
        $projectHome = ($projectHomeLine -split "=", 2)[1]
        
        if ($projectHome -and $projectHome -ne "<inserisci-percorso>") {
            Write-Host ""
            Write-Host "📂 Preparazione directory SSL per Docker..." -ForegroundColor Yellow
            
            $sslDir = Join-Path $projectHome "ssl"
            if (-not (Test-Path $sslDir)) {
                New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
            }
            
            # Copia certificati
            Copy-Item "ssl\*.p12" $sslDir -Force
            Copy-Item "ssl\*.pem" $sslDir -Force
            
            Write-Host "   ✅ Certificati copiati in $sslDir" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "⚠️  PROJECT_HOME non configurato correttamente nel file .env" -ForegroundColor Yellow
            Write-Host "   I certificati sono pronti in .\ssl\" -ForegroundColor Yellow
            Write-Host "   Copia manualmente i file .p12 in `$PROJECT_HOME\ssl\ prima di avviare Docker" -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "⚠️  PROJECT_HOME non trovato nel file .env" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "⚠️  File .env non trovato" -ForegroundColor Yellow
    Write-Host "   Copia .env.example in .env e configuralo prima di proseguire" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Setup SSL completato!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Passi successivi:" -ForegroundColor Cyan
Write-Host "   1. Configura il file .env con le tue password"
Write-Host "   2. Avvia i servizi: docker compose up -d"
Write-Host "   3. Accedi via HTTPS:"
Write-Host "      - Site A: https://localhost:18443"
Write-Host "      - Site B: https://localhost:28443"
Write-Host ""
Write-Host "⚠️  Certificati self-signed: il browser mostrerà un avviso di sicurezza" -ForegroundColor Yellow
Write-Host "   Clicca su 'Avanzate' → 'Procedi al sito' per accettare il certificato" -ForegroundColor Yellow