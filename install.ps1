$ErrorActionPreference = "Stop"

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
    Write-Host "WARNING: 'docker-compose.yml' not found in the current directory." -ForegroundColor Yellow
    $userPath = Read-Host "Enter the absolute path to your n8n installation folder (where docker-compose.yml is located)"
    
    if (-not (Test-Path $userPath)) {
        Write-Host "ERROR: The specified path does not exist." -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path (Join-Path $userPath "docker-compose.yml"))) {
        Write-Host "ERROR: 'docker-compose.yml' not found in the specified directory." -ForegroundColor Red
        exit 1
    }
    
    Set-Location -Path $userPath
    $currentDir = Get-Location
    Write-Host "Changed working directory to: $currentDir" -ForegroundColor Green
}

# 4. Copy update script from the npm package to the installation directory
Write-Host "Copying $targetScript..." -ForegroundColor Yellow
try {
    $sourceScript = Join-Path $PSScriptRoot $targetScript
    Copy-Item -Path $sourceScript -Destination "$currentDir\$targetScript" -Force
} catch {
    Write-Host "ERROR: Could not copy $targetScript." -ForegroundColor Red
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
$taskDescription = "n8n Auto-Updater: Automatically runs daily at 4:00 AM to safely export workflows, pull the latest stable n8n Docker image, restart the container if an update is found, and prune old images to save disk space. Logs are kept in the n8n installation directory."
Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null

Write-Host ""
Write-Host "--- Installation Successful! ---" -ForegroundColor Green
Write-Host "n8n will now update automatically every day at 4:00 AM."
Write-Host "A backup of your workflows will be kept for 7 days in: $currentDir\backups"
Write-Host "Logs are available in: $currentDir\logs\update-n8n.log"
