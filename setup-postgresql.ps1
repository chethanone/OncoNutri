# PostgreSQL Installation and Setup Script for OncoNutri+

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  PostgreSQL Setup for OncoNutri+" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if PostgreSQL is already installed
$psql = Get-Command psql -ErrorAction SilentlyContinue
if ($psql) {
    Write-Host "PostgreSQL is already installed!" -ForegroundColor Green
    Write-Host "Location: $($psql.Source)" -ForegroundColor Cyan
    Write-Host ""
    
    $setupDb = Read-Host "Do you want to setup the OncoNutri database? (y/n)"
    if ($setupDb -ne "y") {
        Write-Host "Setup cancelled." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "PostgreSQL is not installed." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installation Instructions:" -ForegroundColor White
    Write-Host "1. Visit: https://www.postgresql.org/download/windows/" -ForegroundColor Cyan
    Write-Host "2. Download PostgreSQL 16 (or latest stable version)" -ForegroundColor Cyan
    Write-Host "3. Run the installer with default settings" -ForegroundColor Cyan
    Write-Host "4. Remember the password you set for 'postgres' user" -ForegroundColor Cyan
    Write-Host "5. After installation, restart this terminal and run this script again" -ForegroundColor Cyan
    Write-Host ""
    
    $openBrowser = Read-Host "Open download page in browser? (y/n)"
    if ($openBrowser -eq "y") {
        Start-Process "https://www.postgresql.org/download/windows/"
    }
    
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 0
}

# Setup database
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Database Setup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$dbHost = Read-Host "Database Host (press Enter for 'localhost')"
if ([string]::IsNullOrEmpty($dbHost)) { $dbHost = "localhost" }

$dbPort = Read-Host "Database Port (press Enter for '5432')"
if ([string]::IsNullOrEmpty($dbPort)) { $dbPort = "5432" }

$dbUser = Read-Host "Database User (press Enter for 'postgres')"
if ([string]::IsNullOrEmpty($dbUser)) { $dbUser = "postgres" }

Write-Host ""
Write-Host "Please enter the password for user '$dbUser':" -ForegroundColor Yellow
$dbPassword = Read-Host -AsSecureString
$dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))

Write-Host ""
Write-Host "Step 1: Creating database 'onconutri'..." -ForegroundColor Green

$env:PGPASSWORD = $dbPasswordPlain

# Check if database exists
$dbExists = psql -h $dbHost -p $dbPort -U $dbUser -lqt 2>&1 | Select-String -Pattern "onconutri"

if ($dbExists) {
    Write-Host "Database 'onconutri' already exists!" -ForegroundColor Yellow
    $recreate = Read-Host "Drop and recreate? (y/n)"
    if ($recreate -eq "y") {
        psql -h $dbHost -p $dbPort -U $dbUser -c "DROP DATABASE IF EXISTS onconutri;"
        Write-Host "Database dropped." -ForegroundColor Yellow
    } else {
        Write-Host "Using existing database." -ForegroundColor Cyan
        $skipSchema = $true
    }
}

if (-not $skipSchema) {
    # Create database
    $result = psql -h $dbHost -p $dbPort -U $dbUser -c "CREATE DATABASE onconutri;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to create database: $result" -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}

Write-Host ""
Write-Host "Step 2: Running database schema..." -ForegroundColor Green

$schemaPath = "c:\OncoNutri+\backend\database\schema.sql"
if (-not (Test-Path $schemaPath)) {
    Write-Host "Schema file not found at: $schemaPath" -ForegroundColor Red
    exit 1
}

$result = psql -h $dbHost -p $dbPort -U $dbUser -d onconutri -f $schemaPath 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Schema applied successfully!" -ForegroundColor Green
} else {
    Write-Host "Schema application had issues (may be normal if tables exist)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 3: Running migrations..." -ForegroundColor Green

$migrationPath = "c:\OncoNutri+\backend\database\migrations\V1__initial_schema.sql"
if (Test-Path $migrationPath) {
    psql -h $dbHost -p $dbPort -U $dbUser -d onconutri -f $migrationPath 2>&1 | Out-Null
    Write-Host "Migration V1 applied" -ForegroundColor Green
}

$migration2Path = "c:\OncoNutri+\backend\database\migrations\V2__add_patient_summary_view.sql"
if (Test-Path $migration2Path) {
    psql -h $dbHost -p $dbPort -U $dbUser -d onconutri -f $migration2Path 2>&1 | Out-Null
    Write-Host "Migration V2 applied" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 4: Loading sample data (optional)..." -ForegroundColor Green
$loadSample = Read-Host "Load sample data? (y/n)"

if ($loadSample -eq "y") {
    $samplePath = "c:\OncoNutri+\backend\database\sample_data.sql"
    if (Test-Path $samplePath) {
        psql -h $dbHost -p $dbPort -U $dbUser -d onconutri -f $samplePath 2>&1 | Out-Null
        Write-Host "Sample data loaded" -ForegroundColor Green
    } else {
        Write-Host "Sample data file not found" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Step 5: Verifying database..." -ForegroundColor Green

$tableCount = psql -h $dbHost -p $dbPort -U $dbUser -d onconutri -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>&1
Write-Host "Found $($tableCount.Trim()) tables in database" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Creating .env file for backend..." -ForegroundColor Green

$envPath = "c:\OncoNutri+\backend\node_server\.env"
if (Test-Path $envPath) {
    Write-Host ".env file already exists" -ForegroundColor Yellow
    $overwriteEnv = Read-Host "Overwrite? (y/n)"
    if ($overwriteEnv -ne "y") {
        Write-Host "Skipping .env creation" -ForegroundColor Cyan
        $skipEnv = $true
    }
}

if (-not $skipEnv) {
    # Generate random JWT secret
    $jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    
    $envContent = @"
# Database Configuration
DB_HOST=$dbHost
DB_PORT=$dbPort
DB_NAME=onconutri
DB_USER=$dbUser
DB_PASSWORD=$dbPasswordPlain

# JWT Configuration
JWT_SECRET=$jwtSecret
JWT_EXPIRES_IN=7d

# Server Configuration
PORT=5000
NODE_ENV=development

# ML Service Configuration
ML_SERVICE_URL=http://localhost:8000

# CORS Configuration
CORS_ORIGIN=http://localhost:3000
"@
    
    Set-Content -Path $envPath -Value $envContent
    Write-Host ".env file created with database credentials" -ForegroundColor Green
}

# Clear password from environment
$env:PGPASSWORD = $null

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Database Information:" -ForegroundColor Yellow
Write-Host "  Host: $dbHost" -ForegroundColor White
Write-Host "  Port: $dbPort" -ForegroundColor White
Write-Host "  Database: onconutri" -ForegroundColor White
Write-Host "  User: $dbUser" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start the Node.js backend: cd backend\node_server ; npm start" -ForegroundColor White
Write-Host "2. Start the ML service: cd backend\fastapi_ml ; python main.py" -ForegroundColor White
Write-Host "3. Start the Flutter app: cd frontend ; flutter run -d chrome" -ForegroundColor White
Write-Host ""
Write-Host "Or use the service manager: .\start-services.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
