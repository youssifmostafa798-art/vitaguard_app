param(
    [string]$ServiceName = "VitaGuardBackend",
    [string]$NssmPath = "C:\tools\nssm\nssm.exe"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $NssmPath)) {
    throw "nssm.exe not found at $NssmPath"
}

$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $existing) {
    Write-Output "Service $ServiceName does not exist."
    exit 0
}

& $NssmPath stop $ServiceName | Out-Null
& $NssmPath remove $ServiceName confirm | Out-Null
Write-Output "Removed service $ServiceName."
