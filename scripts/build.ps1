# Build script: installs the bundled dsh web app into app/ and prunes it down
# to the minimal runtime footprint (win32-x64).
$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $PSScriptRoot   # repo root
$appDir = Join-Path $root 'app'

New-Item -ItemType Directory -Force -Path $appDir | Out-Null

$manifest = @'
{
  "name": "dsh-desktop-app",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "dependencies": {
    "@deepseek-ai/dsh": "0.1.0-rc.6"
  }
}
'@
Set-Content -Path (Join-Path $appDir 'package.json') -Value $manifest -Encoding UTF8

Write-Host "Installing @deepseek-ai/dsh (this can take a few minutes)..."
Push-Location $appDir
try {
    npm install --omit=dev --no-audit --no-fund --loglevel=error
    if ($LASTEXITCODE -ne 0) { throw "npm install exited with code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

Write-Host "Pruning to the minimal runtime footprint..."
& (Join-Path $root 'tools\prune-app.ps1')

Write-Host "Build complete. Double-click DSH.vbs to launch."
