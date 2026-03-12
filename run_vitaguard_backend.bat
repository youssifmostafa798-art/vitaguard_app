@echo off
setlocal

:: VitaGuard Backend — Automatic Startup Script for Windows
:: This script handles dependency installation, database migrations, and server startup.

echo [VitaGuard] Starting automatic backend initialization...

:: 1. Navigate to backend directory
cd /d "%~dp0\backend"

:: 2. Check for UV (faster dependency manager)
echo [VitaGuard] Checking for dependency manager...
where uv >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [VitaGuard] Found 'uv'. Synchronizing dependencies...
    uv sync
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Failed to sync dependencies with 'uv'.
        pause
        exit /b %ERRORLEVEL%
    )
    set PY_EXE=uv run python
) else (
    echo [VitaGuard] 'uv' not found. Falling back to standard 'pip' and 'python'...
    where python >nul 2>nul
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Python not found in PATH. Please install Python 3.10+.
        pause
        exit /b %ERRORLEVEL%
    )
    
    :: Check for .venv
    if not exist .venv (
        echo [VitaGuard] Creating virtual environment...
        python -m venv .venv
    )
    
    call .venv\Scripts\activate
    echo [VitaGuard] Installing/updating requirements...
    pip install -r requirements.txt --quiet
    set PY_EXE=python
)

:: 3. Launch the Backend
echo [VitaGuard] Launching server (with automatic migrations)...
echo.
%PY_EXE% scripts/start_server.py

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Backend crashed or failed to start.
    pause
    exit /b %ERRORLEVEL%
)

endlocal
