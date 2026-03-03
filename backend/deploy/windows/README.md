# Windows Service Setup (NSSM)

This folder installs VitaGuard backend as a real Windows service without activating `.venv`.

## Prerequisites

- `backend\.venv` already created with project dependencies.
- `nssm.exe` downloaded (https://nssm.cc/download) to `C:\tools\nssm\nssm.exe`, or pass another path.

## Install

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\windows\install-backend-service.ps1
```

Optional arguments:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\windows\install-backend-service.ps1 `
  -ServiceName VitaGuardBackend `
  -NssmPath C:\tools\nssm\nssm.exe `
  -BackendPath C:\Users\ASUS\fultter Pro\vitaguard_app\backend
```

## Remove

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\windows\remove-backend-service.ps1
```
