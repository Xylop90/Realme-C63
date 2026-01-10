@echo off
REM ============================================================================
REM Realme C63 (RMX3939) - Automatisierter Ein-Klick-Installer
REM Author: Elektronikx-Center-Matte by Alexander Mathey
REM Version: 1.0.0
REM Description: Bootstrapper mit Self-Elevation und PowerShell-Orchestrator
REM ============================================================================

setlocal enabledelayedexpansion

REM ============================================================================
REM ASCII-Art-Banner
REM ============================================================================
cls
echo.
echo ============================================================================
echo   ____            _                    ____ __________
echo  / __ \___  ___ _/ /_ _  ___   ___   / __// /__  / _ )
echo / /_/ / -_)/ _ `/ /  ' \/ -_) / __/ / /_ / _ \/ _ / _ \
echo \____/\__/ \_,_/_/_/_/_/\__/  \__/  \__//_//_/____/___/
echo.
echo         Vollautomatische Installation fuer Realme C63
echo                     Version 1.0.0
echo ============================================================================
echo.

REM ============================================================================
REM Administrator-Rechte pruefen und Self-Elevation
REM ============================================================================
:check_admin
net session >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Administrator-Rechte vorhanden
    goto :start_installation
)

echo [!] Administrator-Rechte erforderlich
echo [*] Starte Self-Elevation...
echo.

REM Self-Elevation mit PowerShell
powershell -Command "Start-Process '%~f0' -Verb RunAs"
exit /b

REM ============================================================================
REM Start der Hauptinstallation
REM ============================================================================
:start_installation
echo [*] Pruefe Windows-Version...

REM Windows-Version pruefen (Windows 10/11)
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%" lss "10.0" (
    color 0C
    echo [FEHLER] Windows 10 oder neuer erforderlich
    echo [INFO] Aktuelle Version: %VERSION%
    pause
    exit /b 1
)
echo [OK] Windows-Version: %VERSION%

REM ============================================================================
REM PowerShell-Version pruefen
REM ============================================================================
echo [*] Pruefe PowerShell-Version...
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [FEHLER] PowerShell 5.1 oder neuer erforderlich
    echo [INFO] Bitte Windows PowerShell aktualisieren
    pause
    exit /b 1
)
echo [OK] PowerShell 5.1+ erkannt

REM ============================================================================
REM Arbeitsverzeichnis festlegen
REM ============================================================================
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\ps\Install-RealmeC63.ps1"

echo [*] Arbeitsverzeichnis: %SCRIPT_DIR%
echo.

REM ============================================================================
REM Hauptskript pruefen
REM ============================================================================
if not exist "%PS_SCRIPT%" (
    color 0C
    echo [FEHLER] Hauptskript nicht gefunden:
    echo %PS_SCRIPT%
    echo.
    echo [INFO] Bitte Repository-Struktur pruefen
    pause
    exit /b 1
)

REM ============================================================================
REM Desktop-Verknuepfung erstellen
REM ============================================================================
echo [*] Erstelle Desktop-Verknuepfung...
powershell -ExecutionPolicy Bypass -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Realme C63 Installer.lnk'); $Shortcut.TargetPath = '%~f0'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.IconLocation = 'shell32.dll,137'; $Shortcut.Description = 'Realme C63 Automatische Installation'; $Shortcut.Save()" >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Desktop-Verknuepfung erstellt
) else (
    echo [!] Desktop-Verknuepfung konnte nicht erstellt werden
)

REM ============================================================================
REM PowerShell-Hauptskript starten
REM ============================================================================
echo.
echo ============================================================================
echo          Starte PowerShell-Hauptinstaller...
echo ============================================================================
echo.
timeout /t 2 /nobreak >nul

REM PowerShell mit Bypass-Policy und NoProfile ausfuehren
powershell -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" -WorkingDirectory "%SCRIPT_DIR%"

set INSTALL_EXIT_CODE=%errorlevel%

REM ============================================================================
REM Installation abgeschlossen
REM ============================================================================
echo.
echo ============================================================================
if %INSTALL_EXIT_CODE% == 0 (
    color 0A
    echo [OK] Installation erfolgreich abgeschlossen!
    echo.
    echo [INFO] Naechste Schritte:
    echo   1. Geraet verbinden und im Download-Modus starten
    echo   2. SPD Flash Tool oeffnen
    echo   3. Firmware-Datei laden und flashen
) else (
    color 0C
    echo [FEHLER] Installation mit Fehlercode %INSTALL_EXIT_CODE% beendet
    echo.
    echo [INFO] Bitte Logdatei pruefen:
    echo   %SCRIPT_DIR%work\logs\
)
echo ============================================================================
echo.

pause
endlocal
exit /b %INSTALL_EXIT_CODE%
