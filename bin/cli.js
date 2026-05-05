#!/usr/bin/env node

const { execSync } = require('child_process');
const os = require('os');
const path = require('path');

console.log('--- n8n-update: Cross-Platform Installer ---');

const packageRoot = path.join(__dirname, '..');

try {
  if (os.platform() === 'win32') {
    console.log('Detected Windows. Launching PowerShell installer...');
    const installScript = path.join(packageRoot, 'install.ps1');
    const psCommand = `powershell -NoProfile -ExecutionPolicy Bypass -File "${installScript}" "${packageRoot}"`;
    execSync(psCommand, { stdio: 'inherit' });
  } else {
    console.log('Detected Linux/macOS. Launching Bash installer...');
    const installScript = path.join(packageRoot, 'install.sh');
    const shCommand = `bash "${installScript}" "${packageRoot}"`;
    execSync(shCommand, { stdio: 'inherit' });
  }
} catch (error) {
  console.error('\nERROR: Installation failed.');
  process.exit(1);
}
