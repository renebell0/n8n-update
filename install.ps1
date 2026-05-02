$ErrorActionPreference = "Stop"

$repoUrl = "https://raw.githubusercontent.com/TU-USUARIO/n8n-windows-auto-updater/main"
$targetScript = "update-n8n.ps1"
$currentDir = Get-Location

Write-Host "--- n8n Windows Auto-Updater Installer ---" -ForegroundColor Cyan

# 1. Admin Check
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Please run this installer as Administrator." -ForegroundColor Red
    exit 1
}

# 2. Dependency Check: Docker
$dockerExe = Get-Command docker.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $dockerExe) {
    if (Test-Path "C:\Program Files\Docker\Docker\resources\bin\docker.exe") {
        $dockerExe = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
    } else {
        Write-Host "ERROR: Docker is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install Docker Desktop before running this installer."
        exit 1
    }
}

# 3. Dependency Check: n8n (docker-compose.yml)
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "ERROR: 'docker-compose.yml' not found in the current directory." -ForegroundColor Red
    Write-Host "Please run this installer inside your n8n installation folder."
    exit 1
}

# 4. Download update script
Write-Host "Downloading $targetScript..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "$repoUrl/$targetScript" -OutFile "$currentDir\$targetScript" -UseBasicParsing
} catch {
    Write-Host "ERROR: Could not download $targetScript from GitHub." -ForegroundColor Red
    exit 1
}

# 5. Create directories
Write-Host "Creating logs and backups directories..." -ForegroundColor Yellow
if (-not (Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" | Out-Null }
if (-not (Test-Path "backups")) { New-Item -ItemType Directory -Path "backups" | Out-Null }

# 6. Configure Scheduled Task
Write-Host "Configuring Windows Scheduled Task (n8n-daily-update)..." -ForegroundColor Yellow
$taskName = "n8n-daily-update"
$scriptPath = Join-Path $currentDir $targetScript
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At 4am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Remove existing task if it exists
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Register new task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null

Write-Host ""
Write-Host "--- Installation Successful! ---" -ForegroundColor Green
Write-Host "n8n will now update automatically every day at 4:00 AM."
Write-Host "A backup of your workflows will be kept for 7 days in: $currentDir\backups"
Write-Host "Logs are available in: $currentDir\logs\update-n8n.log"
