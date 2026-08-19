# DSH Desktop Launcher
# 1) Opens a splash window immediately (perceived instant startup).
# 2) Reuses one persistent Edge profile (warm start, no leftover profiles).
# Single-instance: the first launch owns the server; later launches reuse it.
# When the last window closes, the owning launcher stops the server.

$ErrorActionPreference = 'Stop'

# Resolve the launcher's own directory regardless of the caller's cwd.
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $root -or -not (Test-Path -LiteralPath $root)) { $root = $PSScriptRoot }
if (-not $root) { $root = Split-Path -Parent $PSCommandPath }

$appBin    = Join-Path $root 'app\node_modules\@deepseek-ai\dsh\lib\bin.js'
$logDir    = Join-Path $root 'logs'
$outLog    = Join-Path $logDir 'dsh.out.log'
$errLog    = Join-Path $logDir 'dsh.err.log'
$traceLog  = Join-Path $logDir 'dsh.trace.log'
$runtimeDir= Join-Path $root 'runtime'
$stateFile = Join-Path $runtimeDir 'state.json'
$edgeProfile = Join-Path $runtimeDir 'edge-profile'
$splashPath  = Join-Path $root 'splash.html'
$port        = 3081

function Write-Trace($msg) {
    try { Add-Content -Path $traceLog -Value ("{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg) -Encoding UTF8 } catch {}
}

function Show-Error($message) {
    Write-Trace "ERROR: $message"
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [void][System.Windows.Forms.MessageBox]::Show($message, 'DSH', 0, 16)
    } catch {
        try { Set-Content -Path (Join-Path $logDir 'launch-error.txt') -Value $message -Encoding UTF8 } catch {}
    }
}

function Test-ProcessAlive($procId) {
    if (-not $procId) { return $false }
    return $null -ne (Get-Process -Id $procId -ErrorAction SilentlyContinue)
}

function Find-Node {
    foreach ($c in @(
        "$env:ProgramFiles\nodejs\node.exe",
        "${env:ProgramFiles(x86)}\nodejs\node.exe",
        "$env:LOCALAPPDATA\Programs\nodejs\node.exe"
    )) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
    $cmd = Get-Command node -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return $cmd.Source }
    return $null
}

function Find-Edge {
    foreach ($c in @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    )) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
    foreach ($rk in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
    )) {
        try {
            $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).'(default)'
            if ($v -and (Test-Path -LiteralPath $v)) { return $v }
        } catch {}
    }
    return $null
}

Write-Trace "start root=$root port=$port"

# --- Prerequisites -----------------------------------------------------------
$nodePath = Find-Node
if (-not $nodePath) {
    Show-Error "未找到 Node.js。请安装 Node.js（https://nodejs.org）后重试。"
    exit 1
}
if (-not (Test-Path -LiteralPath $appBin)) {
    Show-Error "未找到 DSH 应用文件：$appBin"
    exit 1
}
if (-not (Test-Path -LiteralPath $splashPath)) {
    Show-Error "未找到启动页：$splashPath"
    exit 1
}
$edge = Find-Edge
if (-not $edge) {
    Show-Error "未找到 Microsoft Edge（Windows 10/11 自带）。"
    exit 1
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null

# file URL + the port the splash page should poll/redirect to.
$splashUrl = 'file:///' + ($splashPath -replace '\\','/') + '?port=' + $port
$edgeArgs  = "--app=$splashUrl --user-data-dir=`"$edgeProfile`" --no-first-run --no-default-browser-check --disable-extensions --class=DSH --window-size=1440,900"

# --- Single-instance: decide owner vs follower -------------------------------
$owner = $true
if (Test-Path -LiteralPath $stateFile) {
    try {
        $state = Get-Content $stateFile -Raw -ErrorAction Stop | ConvertFrom-Json
        if ($state -and $state.pid -and (Test-ProcessAlive $state.pid)) { $owner = $false }
    } catch {}
}
# Belt-and-suspenders: if something already listens on our port, reuse it.
if ($owner -and (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)) {
    $owner = $false
}
Write-Trace "owner=$owner"

if (-not $owner) {
    # Follower: the server is already running (or starting) — just open a window.
    Start-Process -FilePath $edge -ArgumentList $edgeArgs | Out-Null
    Write-Trace "follower window opened; exit"
    exit 0
}

# --- Owner: start the server, then open the splash window --------------------
Set-Content -Path $outLog -Value '' -Encoding UTF8 -ErrorAction SilentlyContinue
Set-Content -Path $errLog -Value '' -Encoding UTF8 -ErrorAction SilentlyContinue

$server = Start-Process -FilePath $nodePath `
    -ArgumentList @($appBin, '--profile', 'web', '--port', $port) `
    -WorkingDirectory $root `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog `
    -WindowStyle Hidden `
    -PassThru
Write-Trace "server started pid=$($server.Id)"

# Publish state immediately (before the server binds) to close the double-launch race.
@{ pid = $server.Id; port = $port } | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8

$edgeProc = Start-Process -FilePath $edge -ArgumentList $edgeArgs -PassThru
Write-Trace "edge window opened pid=$($edgeProc.Id)"

# --- Wait for the window to close (or the server to die) ---------------------
$ready = $false
while ($true) {
    Start-Sleep -Milliseconds 500

    $serverAlive = Test-ProcessAlive $server.Id
    if (-not $serverAlive) {
        if (-not $ready) {
            # Server died before serving: startup failure (e.g. port busy).
            $errText = Get-Content $errLog -Raw -ErrorAction SilentlyContinue
            $outText = Get-Content $outLog -Raw -ErrorAction SilentlyContinue
            Stop-Process -Id $edgeProc.Id -Force -ErrorAction SilentlyContinue
            Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
            Show-Error "DSH 启动失败（端口 $port 可能被占用）。`n`n输出：`n$outText`n$errText"
            exit 1
        }
        break  # server exited after being ready
    }

    if (-not $ready) {
        $text = Get-Content $outLog -Raw -ErrorAction SilentlyContinue
        if ($text -and $text -match 'http://127\.0\.0\.1:\d+') {
            $ready = $true
            Write-Trace "server ready"
        }
    }

    if (-not (Test-ProcessAlive $edgeProc.Id)) {
        Write-Trace "edge window closed"
        break
    }
}

Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
Write-Trace "done (server stopped)"
