# n8n-update: Cross-Platform Auto-Updater (Docker)

[![npm version](https://img.shields.io/npm/v/n8n-update.svg)](https://www.npmjs.com/package/n8n-update)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![SLSA Provenance](https://img.shields.io/badge/SLSA-Level%203-blue)](https://slsa.dev)

A professional, cross-platform automated solution to keep your **n8n** instance updated on **Windows, Linux, and macOS** using Docker.

## Features

- 🚀 **Universal Compatibility:** Works on Windows (PowerShell), Linux (Bash), and macOS (Bash).
- 📦 **NPM Ready:** Install and configure in one command with `npx n8n-update`.
- 💾 **Safe Backups:** Automatically exports workflows to JSON before every update.
- 🔄 **Smart Retention:** Keeps only the last 7 days of backups to save disk space.
- 🧹 **Automatic Pruning:** Removes old Docker images (~1GB each) after updating.
- 🛡️ **Supply Chain Security:** Published with SLSA provenance for verified builds.

## Prerequisites

1.  **Docker Desktop** (Windows/macOS) or **Docker Engine** (Linux).
2.  **n8n** must be running via `docker-compose.yml`.
3.  **Node.js** (Optional, for `npx` usage).

## Installation

Run this command inside your n8n installation folder (where `docker-compose.yml` is located):

### Option A: Using NPM (Recommended)
```bash
npx n8n-update
```

### Option B: Using PowerShell (Windows Only)
```powershell
irm https://raw.githubusercontent.com/renebell0/n8n-update/main/install.ps1 | iex
```

### Option C: Using Bash (Linux/macOS Only)
```bash
curl -fsSL https://raw.githubusercontent.com/renebell0/n8n-update/main/install.sh | bash
```

## How it works

1.  **Windows:** Sets up a Scheduled Task (`n8n-daily-update`) using the SYSTEM account.
2.  **Linux/macOS:** Configures a `cron` job to run daily at 04:00 AM.
3.  **Daily Routine:**
    - Export workflows to `./backups`.
    - Delete backups older than 7 days.
    - Pull latest `n8nio/n8n:stable` image.
    - Restart container if an update is available.
    - Prune old Docker images.

## Maintenance

- **Updating the Updater:** To update this tool to the newest version, simply run the installation command again: `npx n8n-update@latest`.
- **Logs:** Check activity at `./logs/update-n8n.log`.
- **Manual Execution:** Run `./update-n8n.sh` or `.\update-n8n.ps1` anytime.

## Safety & Security

- **Data Integrity:** Only performs `docker compose up -d`, preserving your volumes.
- **Provenance:** This package is built and published via GitHub Actions with SLSA provenance, ensuring the code you run matches the source.
