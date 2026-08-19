# Prunes D:\DSH\app\node_modules down to the runtime-minimal footprint for
# win32-x64. Removes only artifacts that are provably unused at runtime:
# source maps, type declarations, TypeScript/JS source, docs, and native
# binaries / debug symbols for other platforms or architectures.
$ErrorActionPreference = 'Stop'
$nm = Join-Path (Split-Path -Parent $PSScriptRoot) 'app\node_modules'

function Remove-Tree($path) {
    if (Test-Path $path) { Remove-Item $path -Recurse -Force }
}

# 1) Text artifacts that are never loaded at runtime.
Get-ChildItem $nm -Recurse -File -Include *.map, *.d.ts, *.ts, *.md -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }

# 2) node-pty: keep only the win32-x64 prebuilds (minus debug symbols) + JS glue.
$pty = Join-Path $nm 'node-pty'
foreach ($dir in 'darwin-arm64','darwin-x64','win32-arm64') { Remove-Tree (Join-Path $pty "prebuilds\$dir") }
Get-ChildItem (Join-Path $pty 'prebuilds\win32-x64') -Recurse -Filter *.pdb -File -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item $_.FullName -Force }
foreach ($dir in 'build','deps','third_party','src','scripts') { Remove-Tree (Join-Path $pty $dir) }
Remove-Item (Join-Path $pty 'binding.gyp') -Force -ErrorAction SilentlyContinue

# 3) sharp: drop the WebAssembly build (win32-x64 native build is installed).
Remove-Tree (Join-Path $nm '@img\sharp-wasm32')

Write-Output "prune complete"
