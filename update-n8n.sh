#!/bin/bash

# Portability: Get the directory where this script is located
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/update-n8n.log"
BACKUP_DIR="$PROJECT_DIR/backups"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

# Ensure essential directories exist
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

write_log() {
    local message="$1"
    if [ -n "$message" ]; then
        local timestamp
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "[$timestamp] $message" >> "$LOG_FILE"
    fi
}

# Validation
if ! command -v docker &> /dev/null; then
    write_log "ERROR: docker command not found. Please ensure Docker is installed."
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    write_log "ERROR: docker-compose.yml not found in $PROJECT_DIR. Cannot proceed."
    exit 1
fi

write_log "Starting scheduled n8n update check (Linux/macOS)."

# 1. SECURITY: Rolling Backup
TIMESTAMP=$(date "+%Y%m%d")
BACKUP_FILE="$BACKUP_DIR/workflows_auto_$TIMESTAMP.json"

if docker exec n8n n8n export:workflow --all --output=/home/node/last_backup.json &> /dev/null; then
    docker cp n8n:/home/node/last_backup.json "$BACKUP_FILE" &> /dev/null
    write_log "Backup created: $BACKUP_FILE"
else
    write_log "Warning: Failed to create workflow backup. Proceeding with update anyway."
fi

# 2. BACKUP CLEANUP: Retention 7 days
find "$BACKUP_DIR" -name "workflows_auto_*.json" -type f -mtime +7 -delete
write_log "Old backups cleaned (retention: 7 days)."

# 3. UPDATE: Pull image
write_log "Pulling latest n8n image..."
if docker compose -f "$COMPOSE_FILE" pull n8n >> "$LOG_FILE" 2>&1; then
    # 4. RESTART: Recreate container if image changed
    write_log "Applying updates to n8n container if needed..."
    if UP_OUTPUT=$(docker compose -f "$COMPOSE_FILE" up -d n8n 2>&1); then
        if echo "$UP_OUTPUT" | grep -qE "Started|Recreated"; then
            write_log "SUCCESS: n8n was updated to a newer version and restarted."
        else
            write_log "INFO: n8n is already up-to-date (no restart was necessary)."
        fi
        
        # 5. MAINTENANCE: Prune images
        docker image prune -f &> /dev/null
        write_log "Old docker images pruned."
        write_log "n8n update routine completed successfully."
    else
        write_log "ERROR: Failed to restart n8n container."
        write_log "$UP_OUTPUT"
        exit 1
    fi
else
    write_log "ERROR: Failed to pull n8n image."
    exit 1
fi
