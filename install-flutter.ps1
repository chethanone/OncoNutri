# Flutter Installation Script for OncoNutri+
# This script automatically downloads and installs Flutter SDK on Windows

param(
    [string]$InstallPath = "C:\flutter",
    [string]$FlutterVersion = "3.24.5-stable"
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Flutter Installation Script" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator!" -ForegroundColor Yellow
    Write-Host "PATH modification may fail. Consider running as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Step 1: Check if Flutter is already installed
Write-Host "Step 1: Checking for existing Flutter installation..." -ForegroundColor Green
$existingFlutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($existingFlutter) {
    Write-Host "Flutter is already installed at: $($existingFlutter.Source)" -ForegroundColor Yellow
    flutter --version
    Write-Host ""
    $continue = Read-Host "Do you want to continue anyway? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Installation cancelled." -ForegroundColor Red
        exit 0
    }
}

# Step 2: Download Flutter SDK
Write-Host "Step 2: Downloading Flutter SDK..." -ForegroundColor Green
$downloadUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$FlutterVersion.zip"
$downloadPath = "$env:TEMP\flutter_windows.zip"

Write-Host "Downloading from: $downloadUrl" -ForegroundColor Cyan
Write-Host "This may take several minutes (approximately 300 MB)..." -ForegroundColor Cyan

# Remove old download if exists
if (Test-Path $downloadPath) {
    Remove-Item -Path $downloadPath -Force
}

try {
    # Use BitsTransfer for more reliable downloads with resume capability
    Import-Module BitsTransfer
    Start-BitsTransfer -Source $downloadUrl -Destination $downloadPath -Description "Downloading Flutter SDK" -DisplayName "Flutter SDK"
    Write-Host "Download completed!" -ForegroundColor Green
} catch {
    Write-Host "BitsTransfer failed, trying alternative method..." -ForegroundColor Yellow
    try {
        # Fallback to WebClient with retry logic
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $downloadPath)
        Write-Host "Download completed!" -ForegroundColor Green
    } catch {
        Write-Host "Error downloading Flutter: $_" -ForegroundColor Red
        Write-Host "Please download manually from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
        exit 1
    }
}

# Step 3: Extract Flutter SDK
Write-Host "Step 3: Extracting Flutter SDK to $InstallPath..." -ForegroundColor Green

if (Test-Path $InstallPath) {
    Write-Host "Warning: $InstallPath already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -eq "y") {
        Remove-Item -Path $InstallPath -Recurse -Force
    } else {
        Write-Host "Installation cancelled." -ForegroundColor Red
        Remove-Item -Path $downloadPath -Force
        exit 0
    }
}

try {
    Expand-Archive -Path $downloadPath -DestinationPath (Split-Path $InstallPath -Parent) -Force
    Write-Host "Extraction completed!" -ForegroundColor Green
} catch {
    Write-Host "Error extracting Flutter: $_" -ForegroundColor Red
    Remove-Item -Path $downloadPath -Force
    exit 1
}

# Step 4: Add Flutter to PATH
Write-Host "Step 4: Adding Flutter to system PATH..." -ForegroundColor Green
$flutterBinPath = "$InstallPath\bin"

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterBinPath*") {
    try {
        $newPath = "$currentPath;$flutterBinPath"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "Flutter added to PATH successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Error adding Flutter to PATH: $_" -ForegroundColor Red
        Write-Host "You may need to add it manually: $flutterBinPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "Flutter is already in PATH" -ForegroundColor Yellow
}

# Refresh PATH in current session
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

# Step 5: Run Flutter Doctor
Write-Host "Step 5: Running Flutter Doctor..." -ForegroundColor Green
Write-Host "(This will check for required dependencies)" -ForegroundColor Cyan
Write-Host ""

try {
    & "$flutterBinPath\flutter.bat" doctor
} catch {
    Write-Host "Error running flutter doctor: $_" -ForegroundColor Red
}

# Cleanup
if (Test-Path $downloadPath) {
    Remove-Item -Path $downloadPath -Force
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Close and reopen your terminal to ensure PATH is updated" -ForegroundColor White
Write-Host "2. Run 'flutter doctor' to see any remaining dependencies" -ForegroundColor White
Write-Host "3. Install any missing dependencies (Android Studio, VS Code, etc.)" -ForegroundColor White
Write-Host "4. Navigate to the frontend directory and run 'flutter pub get'" -ForegroundColor White
Write-Host ""
Write-Host "Flutter bin path: $flutterBinPath" -ForegroundColor Cyan
Write-Host ""

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
