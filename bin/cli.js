#!/usr/bin/env node

const { execSync } = require('child_process');
const os = require('os');

const REPO_USER = 'renebell0'; // CHANGE THIS AFTER CREATING REPO
const RAW_URL = `https://raw.githubusercontent.com/${REPO_USER}/n8n-update/main`;

console.log('--- n8n-update: Cross-Platform Installer ---');

try {
  if (os.platform() === 'win32') {
    console.log('Detected Windows. Launching PowerShell installer...');
    const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -Command "irm ${RAW_URL}/install.ps1 | iex"`;
    execSync(psCommand, { stdio: 'inherit' });
  } else {
    console.log('Detected Linux/macOS. Launching Bash installer...');
    const shCommand = `bash -c "$(curl -fsSL ${RAW_URL}/install.sh)"`;
    execSync(shCommand, { stdio: 'inherit' });
  }
} catch (error) {
  console.error('\nERROR: Installation failed.');
  process.exit(1);
}
