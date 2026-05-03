$ErrorActionPreference = "Stop"

# Portability: We infer the project directory from where THIS script is located
$projectDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($projectDir)) { $projectDir = Get-Location }

$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
$dockerExe = Join-Path $dockerBin "docker.exe"
$logDir = Join-Path $projectDir "logs"
$logFile = Join-Path $logDir "update-n8n.log"
$backupDir = Join-Path $projectDir "backups"
$composeFile = Join-Path $projectDir "docker-compose.yml"

# Ensure essential directories exist
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

function Write-Log {
    param([string]$Message)
    if ([string]::IsNullOrWhiteSpace($Message)) { return }
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$stamp] $Message"
}

# Helper to run native commands that write to stderr (like docker) 
# without triggering $ErrorActionPreference = "Stop" on non-errors.
function Invoke-NativeCommand {
    param([scriptblock]$Command)
    $oldAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Native command failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $oldAction
    }
}

try {
    # Path validation
    if (-not (Test-Path $dockerExe)) {
        # Try finding docker in PATH if not in standard location
        $dockerExe = Get-Command docker.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if (-not $dockerExe) { throw "docker.exe not found. Please ensure Docker Desktop is installed." }
    }
    
    if (-not (Test-Path $composeFile)) {
        throw "docker-compose.yml not found in $projectDir. Cannot proceed with update."
    }

    $env:PATH = "$(Split-Path $dockerExe);$env:PATH"

    Write-Log "Starting scheduled n8n update check."

    # 1. SECURITY: Rolling Backup
    $timestamp = Get-Date -Format "yyyyMMdd"
    $backupFile = Join-Path $backupDir "workflows_auto_$timestamp.json"
    
    # Try to export, but don't fail the whole update if export fails (e.g. n8n is down)
    try {
        Write-Host "Exporting workflows..."
        Invoke-NativeCommand { & $dockerExe exec n8n n8n export:workflow --all --output=/home/node/last_backup.json 2>$null }
        Invoke-NativeCommand { & $dockerExe cp "n8n:/home/node/last_backup.json" "$backupFile" 2>$null }
        Write-Log "Backup created: $backupFile"
    } catch {
        Write-Log "Warning: Failed to create workflow backup. Proceeding with update anyway. Error: $($_.Exception.Message)"
    }

    # 2. BACKUP CLEANUP: Retention 7 days
    Get-ChildItem -Path $backupDir -Filter "workflows_auto_*.json" | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force
    Write-Log "Old backups cleaned (retention: 7 days)."

    # 3. UPDATE: Pull image
    Write-Log "Pulling latest n8n image..."
    Invoke-NativeCommand { & $dockerExe compose -f $composeFile pull n8n 2>$null }

    # 4. RESTART: Recreate container if image changed
    Write-Log "Restarting n8n container if needed..."
    Invoke-NativeCommand { & $dockerExe compose -f $composeFile up -d n8n 2>$null }

    # 5. MAINTENANCE: Prune images
    Invoke-NativeCommand { & $dockerExe image prune -f 2>$null }
    Write-Log "Old docker images pruned."

    Write-Log "n8n update routine completed successfully."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
