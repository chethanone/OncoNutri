# OncoNutri+ Quick Start Script
# This script helps you start all services

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  OncoNutri+ Service Manager" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Green

# Check Node.js
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "[X] Node.js not found!" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Node.js: $(node --version)" -ForegroundColor Green

# Check Python
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "[X] Python not found!" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Python: $(python --version)" -ForegroundColor Green

# Check Flutter
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "[X] Flutter not found!" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Flutter: Installed" -ForegroundColor Green

# Check PostgreSQL (optional)
$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
    Write-Host "[!] PostgreSQL not found (optional for now)" -ForegroundColor Yellow
} else {
    Write-Host "[✓] PostgreSQL: Installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Service Options" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Start Node.js Backend (Port 5000)" -ForegroundColor White
Write-Host "2. Start FastAPI ML Service (Port 8000)" -ForegroundColor White
Write-Host "3. Start Flutter App (Mobile/Web)" -ForegroundColor White
Write-Host "4. Start All Services" -ForegroundColor White
Write-Host "5. Setup Database" -ForegroundColor White
Write-Host "6. Check Service Status" -ForegroundColor White
Write-Host "0. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice"

switch ($choice) {
    "1" {
        Write-Host "Starting Node.js Backend..." -ForegroundColor Green
        Set-Location "c:\OncoNutri+\backend\node_server"
        
        if (-not (Test-Path ".env")) {
            Write-Host "Creating .env file from template..." -ForegroundColor Yellow
            Copy-Item ".env.example" ".env"
            Write-Host "Please edit .env file with your database credentials!" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
        
        npm start
    }
    "2" {
        Write-Host "Starting FastAPI ML Service..." -ForegroundColor Green
        Set-Location "c:\OncoNutri+\backend\fastapi_ml"
        
        if (-not (Test-Path "logs")) {
            New-Item -ItemType Directory -Path "logs" | Out-Null
        }
        
        python main.py
    }
    "3" {
        Write-Host "Starting Flutter App..." -ForegroundColor Green
        Write-Host "Choose platform:" -ForegroundColor Cyan
        Write-Host "1. Web (Chrome)" -ForegroundColor White
        Write-Host "2. Android Emulator" -ForegroundColor White
        Write-Host "3. Windows Desktop" -ForegroundColor White
        
        $platform = Read-Host "Enter platform"
        Set-Location "c:\OncoNutri+\frontend"
        
        switch ($platform) {
            "1" { flutter run -d chrome }
            "2" { flutter run -d android }
            "3" { flutter run -d windows }
            default { flutter run }
        }
    }
    "4" {
        Write-Host "Starting all services..." -ForegroundColor Green
        Write-Host "This will open 3 new terminal windows" -ForegroundColor Yellow
        
        # Start Node.js Backend
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\OncoNutri+\backend\node_server'; if (-not (Test-Path '.env')) { Copy-Item '.env.example' '.env' }; npm start"
        
        # Start FastAPI ML
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'c:\OncoNutri+\backend\fastapi_ml'; if (-not (Test-Path 'logs')) { New-Item -ItemType Directory -Path 'logs' }; python main.py"
        
        # Wait a bit for services to start
        Write-Host "Waiting for services to start..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        Write-Host "Backend running at: http://localhost:5000" -ForegroundColor Green
        Write-Host "ML Service running at: http://localhost:8000" -ForegroundColor Green
        Write-Host ""
        Write-Host "Press any key to start Flutter app..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        
        Set-Location "c:\OncoNutri+\frontend"
        flutter run -d chrome
    }
    "5" {
        Write-Host "Database Setup" -ForegroundColor Green
        Write-Host "Please ensure PostgreSQL is installed and running" -ForegroundColor Yellow
        Write-Host ""
        
        $dbHost = Read-Host "Database Host (default: localhost)"
        if ([string]::IsNullOrEmpty($dbHost)) { $dbHost = "localhost" }
        
        $dbUser = Read-Host "Database User (default: postgres)"
        if ([string]::IsNullOrEmpty($dbUser)) { $dbUser = "postgres" }
        
        $dbPassword = Read-Host "Database Password" -AsSecureString
        $dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))
        
        Write-Host "Creating database..." -ForegroundColor Cyan
        $env:PGPASSWORD = $dbPasswordPlain
        
        # Create database
        psql -h $dbHost -U $dbUser -c "CREATE DATABASE onconutri;"
        
        # Run schema
        Set-Location "c:\OncoNutri+\backend\database"
        psql -h $dbHost -U $dbUser -d onconutri -f "schema.sql"
        
        Write-Host "Database setup complete!" -ForegroundColor Green
    }
    "6" {
        Write-Host "Checking service status..." -ForegroundColor Green
        Write-Host ""
        
        # Check Node.js backend
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -Method GET -TimeoutSec 2 -UseBasicParsing
            Write-Host "[✓] Node.js Backend: Running" -ForegroundColor Green
        } catch {
            Write-Host "[X] Node.js Backend: Not running" -ForegroundColor Red
        }
        
        # Check FastAPI ML
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 2 -UseBasicParsing
            Write-Host "[✓] FastAPI ML Service: Running" -ForegroundColor Green
        } catch {
            Write-Host "[X] FastAPI ML Service: Not running" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    "0" {
        Write-Host "Goodbye!" -ForegroundColor Cyan
        exit 0
    }
    default {
        Write-Host "Invalid choice!" -ForegroundColor Red
    }
}
