#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/renebell0/n8n-update/main"
TARGET_SCRIPT="update-n8n.sh"
CURRENT_DIR="$(pwd)"

echo "--- n8n Auto-Updater Installer (Linux/macOS) ---"

# 1. Dependency Check: Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH."
    echo "Please install Docker Desktop or Docker Engine before running this installer."
    exit 1
fi

# 2. Dependency Check: n8n (docker-compose.yml)
if [ ! -f "docker-compose.yml" ]; then
    echo "ERROR: 'docker-compose.yml' not found in the current directory."
    echo "Please run this installer inside your n8n installation folder."
    exit 1
fi

# 3. Download update script
echo "Downloading $TARGET_SCRIPT..."
if ! curl -fsSL "$REPO_URL/$TARGET_SCRIPT" -o "$CURRENT_DIR/$TARGET_SCRIPT"; then
    echo "ERROR: Could not download $TARGET_SCRIPT from GitHub."
    exit 1
fi

chmod +x "$CURRENT_DIR/$TARGET_SCRIPT"

# 4. Create directories
echo "Creating logs and backups directories..."
mkdir -p "logs"
mkdir -p "backups"

# 5. Configure Crontab
echo "Configuring Crontab (n8n daily update at 04:00 AM)..."
SCRIPT_PATH="$CURRENT_DIR/$TARGET_SCRIPT"
CRON_JOB="0 4 * * * $SCRIPT_PATH"

# Add cron job only if it doesn't exist
(crontab -l 2>/dev/null | grep -Fv "$SCRIPT_PATH"; echo "$CRON_JOB") | crontab -

echo ""
echo "--- Installation Successful! ---"
echo "n8n will now update automatically every day at 4:00 AM."
echo "A backup of your workflows will be kept for 7 days in: $CURRENT_DIR/backups"
echo "Logs are available in: $CURRENT_DIR/logs/update-n8n.log"
