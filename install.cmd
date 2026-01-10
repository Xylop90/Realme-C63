@echo off
REM ============================================================================
REM Realme C63 (RMX3939) - Zero-Touch Automated Installation System
REM Master Bootstrap Entry Point
REM Author: Elektronikx-Center-Matte by Alexander Mathey
REM Date: 2026-01-10
REM Version: 1.0
REM ============================================================================

setlocal enabledelayedexpansion
color 0B

REM ============================================================================
REM CONFIGURATION
REM ============================================================================
set "SCRIPT_VERSION=1.0.0"
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\bootstrap\master-installer.ps1"
set "LOG_DIR=%SCRIPT_DIR%logs"

REM ============================================================================
REM HEADER
REM ============================================================================
cls
echo.
echo ================================================================================
echo        Realme C63 (RMX3939) - Vollautomatische Installation
echo                     Version %SCRIPT_VERSION%
echo ================================================================================
echo.
echo Copyright (C) 2026 Elektronikx-Center-Matte by Alexander Mathey
echo.

REM ============================================================================
REM ADMINISTRATOR-RECHTE PRÜFEN UND ANFORDERN
REM ============================================================================
echo [*] Pruefe Administrator-Rechte...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Administrator-Rechte erforderlich
    echo [*] Fordere Elevation an...
    
    REM Elevation mit PowerShell
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b 0
)

echo [OK] Administrator-Rechte verifiziert
echo.

REM ============================================================================
REM VERZEICHNISSE ERSTELLEN
REM ============================================================================
echo [*] Erstelle Verzeichnisstruktur...
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%SCRIPT_DIR%work" mkdir "%SCRIPT_DIR%work"
if not exist "%SCRIPT_DIR%config" mkdir "%SCRIPT_DIR%config"
if not exist "%SCRIPT_DIR%backup" mkdir "%SCRIPT_DIR%backup"
if not exist "%SCRIPT_DIR%firmware" mkdir "%SCRIPT_DIR%firmware"
echo [OK] Verzeichnisse erstellt
echo.

REM ============================================================================
REM POWERSHELL VERSION PRÜFEN
REM ============================================================================
echo [*] Pruefe PowerShell Version...
powershell -Command "$PSVersionTable.PSVersion.Major" > "%TEMP%\ps_version.txt"
set /p PS_VERSION=<"%TEMP%\ps_version.txt"
del "%TEMP%\ps_version.txt"

if %PS_VERSION% LSS 5 (
    echo [ERROR] PowerShell 5.1 oder hoeher erforderlich
    echo [INFO] Aktuelle Version: %PS_VERSION%
    echo [INFO] Bitte Windows Update ausfuehren
    pause
    exit /b 1
)
echo [OK] PowerShell Version %PS_VERSION% gefunden
echo.

REM ============================================================================
REM EXECUTION POLICY SETZEN
REM ============================================================================
echo [*] Setze PowerShell Execution Policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" >nul 2>&1
echo [OK] Execution Policy gesetzt
echo.

REM ============================================================================
REM MASTER INSTALLER STARTEN
REM ============================================================================
echo [*] Starte Master Installer...
echo.
echo ================================================================================
echo.

REM Starte PowerShell Script mit Bypass
powershell -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" -WorkingDirectory "%SCRIPT_DIR%"

REM Prüfe Exit Code
if %errorlevel% equ 0 (
    echo.
    echo ================================================================================
    echo [OK] Installation erfolgreich abgeschlossen!
    echo ================================================================================
    echo.
    echo Logs finden Sie in: %LOG_DIR%
    echo.
) else (
    echo.
    echo ================================================================================
    echo [ERROR] Installation mit Fehler beendet (Code: %errorlevel%)
    echo ================================================================================
    echo.
    echo Bitte pruefen Sie die Logs in: %LOG_DIR%
    echo.
)

pause
endlocal
exit /b %errorlevel%
