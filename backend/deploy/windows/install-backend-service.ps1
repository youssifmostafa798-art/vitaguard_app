param(
    [string]$ServiceName = "VitaGuardBackend",
    [string]$NssmPath = "C:\tools\nssm\nssm.exe",
    [string]$BackendPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pythonExe = Join-Path $BackendPath ".venv\Scripts\python.exe"
$launcher = Join-Path $BackendPath "scripts\start_server.py"
$logDir = Join-Path $BackendPath "logs"

if (-not (Test-Path $NssmPath)) {
    throw "nssm.exe not found at $NssmPath"
}

if (-not (Test-Path $pythonExe)) {
    throw "Virtual environment python not found at $pythonExe"
}

if (-not (Test-Path $launcher)) {
    throw "Launcher script not found at $launcher"
}

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    & $NssmPath stop $ServiceName | Out-Null
    & $NssmPath remove $ServiceName confirm | Out-Null
}

& $NssmPath install $ServiceName $pythonExe $launcher | Out-Null
& $NssmPath set $ServiceName AppDirectory $BackendPath | Out-Null
& $NssmPath set $ServiceName Start SERVICE_AUTO_START | Out-Null
& $NssmPath set $ServiceName AppStdout (Join-Path $logDir "service.out.log") | Out-Null
& $NssmPath set $ServiceName AppStderr (Join-Path $logDir "service.err.log") | Out-Null
& $NssmPath set $ServiceName AppRotateFiles 1 | Out-Null
& $NssmPath set $ServiceName AppRotateOnline 1 | Out-Null
& $NssmPath set $ServiceName AppRotateBytes 10485760 | Out-Null
& $NssmPath set $ServiceName AppExit Default Restart | Out-Null

sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/15000/restart/30000 | Out-Null
sc.exe failureflag $ServiceName 1 | Out-Null

Start-Service -Name $ServiceName
Get-Service -Name $ServiceName
