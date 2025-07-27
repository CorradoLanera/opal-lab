# Script PowerShell completo per setup opal-lab
# Equivalente Windows di setup.sh
#
param(
    [switch]$Force = $false  # Forza sovrascrittura file esistenti
)

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
Set-Location $scriptDir

Write-Host "🚀 Setup completo opal-lab (Windows)" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verifica file .env
if (-not (Test-Path ".env")) {
    Write-Host "📝 Creazione file .env..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "⚠️  IMPORTANTE: Configura le password nel file .env prima di continuare" -ForegroundColor Yellow
    Write-Host "   Apri il file .env e sostituisci <inserisci-password-*> con password reali" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Per modificare il file .env:" -ForegroundColor Cyan
    Write-Host "   notepad .env    # Windows Notepad" -ForegroundColor Gray
    Write-Host "   code .env       # VS Code" -ForegroundColor Gray
    exit 1
}

# 2. Leggi PROJECT_HOME dal file .env
$envContent = Get-Content ".env"
$projectHomeLine = $envContent | Where-Object { $_ -match "^PROJECT_HOME=" }

if (-not $projectHomeLine) {
    Write-Host "❌ PROJECT_HOME non configurato nel file .env" -ForegroundColor Red
    exit 1
}

$projectHome = ($projectHomeLine -split "=", 2)[1]
if ([string]::IsNullOrWhiteSpace($projectHome)) {
    Write-Host "❌ PROJECT_HOME vuoto nel file .env" -ForegroundColor Red
    exit 1
}

Write-Host "📂 PROJECT_HOME: $projectHome" -ForegroundColor Green

# 3. Crea directory necessarie
Write-Host "📁 Creazione directory..." -ForegroundColor Yellow
$directories = @(
    "$projectHome\sitea\opal_home\data",
    "$projectHome\siteb\opal_home\data", 
    "$projectHome\client",
    "$projectHome\ssl"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Host "   ✅ Directory create" -ForegroundColor Green

# 4. Copia dati di esempio
Write-Host "📊 Copia dati di esempio..." -ForegroundColor Yellow
if (Test-Path "sitea\opal_home\data\dataset.csv") {
    Copy-Item "sitea\opal_home\data\dataset.csv" "$projectHome\sitea\opal_home\data\" -Force
}
if (Test-Path "siteb\opal_home\data\dataset.csv") {
    Copy-Item "siteb\opal_home\data\dataset.csv" "$projectHome\siteb\opal_home\data\" -Force
}
Write-Host "   ✅ Dati copiati" -ForegroundColor Green

# 5. Copia script R
Write-Host "📋 Copia script R..." -ForegroundColor Yellow
if (Test-Path "scripts") {
    $rScripts = Get-ChildItem "scripts\*.R"
    foreach ($script in $rScripts) {
        Copy-Item $script.FullName "$projectHome\client\" -Force
    }
    Write-Host "   ✅ Script copiati" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Directory scripts non trovata" -ForegroundColor Yellow
}

# 6. Setup SSL (opzionale ma raccomandato)
Write-Host ""
Write-Host "🔐 Setup SSL..." -ForegroundColor Yellow
if ((Test-Path "ssl\generate-certs.ps1") -and (Test-Path "ssl\setup-keystore.ps1")) {
    try {
        Set-Location ssl
        .\generate-certs.ps1
        .\setup-keystore.ps1
        Set-Location ..
        
        # Copia certificati nella directory di progetto
        $sslFiles = Get-ChildItem "ssl\*.p12"
        foreach ($file in $sslFiles) {
            Copy-Item $file.FullName "$projectHome\ssl\" -Force
        }
        
        $pemFiles = Get-ChildItem "ssl\*.pem" -ErrorAction SilentlyContinue
        foreach ($file in $pemFiles) {
            Copy-Item $file.FullName "$projectHome\ssl\" -Force
        }
        
        Write-Host "   ✅ Certificati SSL generati e copiati" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Errore durante setup SSL: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   L'ambiente funzionerà comunque con HTTP" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  Script SSL non trovati" -ForegroundColor Yellow
    Write-Host "   L'ambiente funzionerà comunque con HTTP" -ForegroundColor Yellow
}

# 7. Verifica configurazione Docker
Write-Host ""
Write-Host "🐳 Verifica configurazione Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "   ✅ Docker trovato: $dockerVersion" -ForegroundColor Green
    
    $composeCheck = docker compose config 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Configurazione Docker Compose valida" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Errori nella configurazione Docker Compose:" -ForegroundColor Red
        Write-Host $composeCheck -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Docker non trovato o non funzionante" -ForegroundColor Red
    Write-Host "   Installa Docker Desktop per Windows" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ Setup completato!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Passi successivi:" -ForegroundColor Cyan
Write-Host "   1. Avvia i servizi: docker compose up -d" -ForegroundColor White
Write-Host "   2. Attendi che tutti i servizi siano healthy: docker compose ps" -ForegroundColor White
Write-Host "   3. Accedi a RStudio: http://localhost:8787" -ForegroundColor White
Write-Host "   4. Esegui setup dati: source('install-packages.R'); source('setup-demo-data.R')" -ForegroundColor White
Write-Host "   5. Analisi demo: source('demo-analysis.R')" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Interfacce disponibili:" -ForegroundColor Cyan
Write-Host "   - RStudio: http://localhost:8787" -ForegroundColor White

if (Test-Path "$projectHome\ssl\sitea-keystore.p12") {
    Write-Host "   - Site A: https://localhost:18443 (HTTPS) o http://localhost:18880 (HTTP)" -ForegroundColor White
    Write-Host "   - Site B: https://localhost:28443 (HTTPS) o http://localhost:28880 (HTTP)" -ForegroundColor White
} else {
    Write-Host "   - Site A: http://localhost:18880 (HTTP)" -ForegroundColor White
    Write-Host "   - Site B: http://localhost:28880 (HTTP)" -ForegroundColor White
}

Write-Host ""
Write-Host "💡 Suggerimenti Windows:" -ForegroundColor Cyan
Write-Host "   - Usa PowerShell come amministratore per evitare problemi di permessi" -ForegroundColor Gray
Write-Host "   - Se hai problemi con OpenSSL, installa tramite: choco install openssl" -ForegroundColor Gray
Write-Host "   - Per debug Docker: docker compose logs [servizio]" -ForegroundColor Gray