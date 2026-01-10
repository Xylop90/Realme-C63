@echo off
REM ============================================================================
REM Realme C63 Ultimate Auto-Installer - Main Entry Point
REM Version: 2.0.0
REM Author: Xylop90 / Elektronikx-Center-Matte
REM Description: KI-gestützter Auto-Installer mit vollautomatischem Setup
REM ============================================================================

setlocal enabledelayedexpansion
title Realme C63 Ultimate Auto-Installer v2.0

REM ============================================================================
REM CONFIGURATION
REM ============================================================================
set "SCRIPT_VERSION=2.0.0"
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\ps\Install-RealmeC63-Ultimate.ps1"
set "MIN_PS_VERSION=5.1"

REM ============================================================================
REM ASCII BANNER
REM ============================================================================
:show_banner
cls
color 0B
echo.
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║                                                                       ║
echo  ║     🚀 REALME C63 ULTIMATE AUTO-INSTALLER v%SCRIPT_VERSION% 🚀          ║
echo  ║                                                                       ║
echo  ║     ✅ Bootloader Unlock (Vollautomatisch)                           ║
echo  ║     ✅ Root-Zugriff (Magisk)                                         ║
echo  ║     ✅ Custom Recovery (TWRP - falls verfügbar)                     ║
echo  ║     ✅ Automatische Updates                                          ║
echo  ║     ✅ KI-basierte Entscheidungsfindung                             ║
echo  ║                                                                       ║
echo  ║     Copyright © Elektronikx-Center-Matte by Alexander Mathey         ║
echo  ║                                                                       ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.
goto :check_admin

REM ============================================================================
REM CHECK ADMINISTRATOR PRIVILEGES
REM ============================================================================
:check_admin
echo [*] Prüfe Administrator-Rechte...
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [FEHLER] Dieses Script benötigt Administrator-Rechte!
    echo.
    echo Bitte führen Sie eine der folgenden Aktionen aus:
    echo   1. Rechtsklick auf INSTALL.bat ^> "Als Administrator ausführen"
    echo   2. Starten Sie eine Eingabeaufforderung als Administrator
    echo.
    echo [*] Versuche automatische Elevation...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b 0
)
echo [OK] Administrator-Rechte bestätigt
echo.
goto :check_windows_version

REM ============================================================================
REM CHECK WINDOWS VERSION
REM ============================================================================
:check_windows_version
echo [*] Prüfe Windows-Version...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%" == "10.0" (
    echo [OK] Windows 10/11 erkannt
) else (
    color 0E
    echo [WARNUNG] Windows 10 oder 11 wird empfohlen
    echo [INFO] Aktuelle Version: %VERSION%
)
echo.
goto :check_powershell

REM ============================================================================
REM CHECK POWERSHELL VERSION
REM ============================================================================
:check_powershell
echo [*] Prüfe PowerShell-Installation...
where powershell.exe >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [FEHLER] PowerShell wurde nicht gefunden!
    echo [INFO] Bitte installieren Sie PowerShell 5.1 oder höher
    pause
    exit /b 1
)

REM Check PowerShell version
for /f "tokens=*" %%a in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set PS_MAJOR=%%a
for /f "tokens=*" %%a in ('powershell -Command "$PSVersionTable.PSVersion.Minor"') do set PS_MINOR=%%a

echo [OK] PowerShell %PS_MAJOR%.%PS_MINOR% gefunden
if %PS_MAJOR% LSS 5 (
    color 0C
    echo [FEHLER] PowerShell 5.1 oder höher wird benötigt!
    echo [INFO] Aktuelle Version: %PS_MAJOR%.%PS_MINOR%
    echo [INFO] Bitte aktualisieren Sie PowerShell
    pause
    exit /b 1
)
echo.
goto :check_dependencies

REM ============================================================================
REM CHECK OPTIONAL DEPENDENCIES
REM ============================================================================
:check_dependencies
echo [*] Prüfe optionale Abhängigkeiten...

REM Check Python (optional for Unisoc unlock)
where python.exe >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2" %%a in ('python --version 2^>^&1') do echo [OK] Python %%a gefunden
) else (
    echo [INFO] Python nicht gefunden - wird bei Bedarf automatisch installiert
)

echo.
goto :check_internet

REM ============================================================================
REM CHECK INTERNET CONNECTION
REM ============================================================================
:check_internet
echo [*] Prüfe Internetverbindung...
ping -n 1 google.com >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Internetverbindung verfügbar
) else (
    color 0E
    echo [WARNUNG] Keine Internetverbindung erkannt
    echo [INFO] Einige Features benötigen Internet für Downloads
)
echo.
goto :check_updates

REM ============================================================================
REM CHECK FOR UPDATES
REM ============================================================================
:check_updates
echo [*] Prüfe auf Updates...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { $latest = (Invoke-RestMethod -Uri 'https://api.github.com/repos/Xylop90/Realme-C63/releases/latest' -ErrorAction SilentlyContinue).tag_name; if ($latest -and $latest -ne 'v%SCRIPT_VERSION%') { Write-Host '[UPDATE] Neue Version verfügbar: '$latest -ForegroundColor Yellow; Write-Host '[INFO] Besuchen Sie https://github.com/Xylop90/Realme-C63/releases' -ForegroundColor Cyan } else { Write-Host '[OK] Sie verwenden die neueste Version' -ForegroundColor Green } } catch { Write-Host '[INFO] Update-Prüfung übersprungen' -ForegroundColor Gray } }"
echo.
goto :create_shortcut

REM ============================================================================
REM CREATE DESKTOP SHORTCUT
REM ============================================================================
:create_shortcut
echo [*] Erstelle Desktop-Verknüpfung...
set "SHORTCUT_PATH=%USERPROFILE%\Desktop\Realme C63 Installer.lnk"
if exist "%SHORTCUT_PATH%" (
    echo [INFO] Verknüpfung existiert bereits
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $WS = New-Object -ComObject WScript.Shell; $SC = $WS.CreateShortcut('%SHORTCUT_PATH%'); $SC.TargetPath = '%~f0'; $SC.WorkingDirectory = '%SCRIPT_DIR%'; $SC.Description = 'Realme C63 Ultimate Auto-Installer'; $SC.Save() }"
    if exist "%SHORTCUT_PATH%" (
        echo [OK] Desktop-Verknüpfung erstellt
    ) else (
        echo [INFO] Verknüpfung konnte nicht erstellt werden
    )
)
echo.
goto :show_warning

REM ============================================================================
REM SHOW IMPORTANT WARNINGS
REM ============================================================================
:show_warning
color 0E
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║                          ⚠️  WICHTIGE WARNUNG  ⚠️                     ║
echo  ╠═══════════════════════════════════════════════════════════════════════╣
echo  ║                                                                       ║
echo  ║  Bootloader-Unlock führt zu:                                         ║
echo  ║  • KOMPLETTEM DATENVERLUST auf dem Gerät                            ║
echo  ║  • GARANTIEVERLUST                                                   ║
echo  ║  • Widevine DRM: Nur noch SD-Qualität (Netflix, Amazon, etc.)      ║
echo  ║  • Banking-Apps funktionieren möglicherweise nicht mehr             ║
echo  ║  • Keine offiziellen OTA-Updates nach Modifikation                  ║
echo  ║  • BRICK-RISIKO bei Fehlern                                         ║
echo  ║                                                                       ║
echo  ║  ERSTELLEN SIE EIN BACKUP ALLER WICHTIGEN DATEN!                    ║
echo  ║                                                                       ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.
color 0B

set /p "CONFIRM=Möchten Sie fortfahren? (JA/Nein): "
if /i not "%CONFIRM%"=="JA" (
    echo.
    echo [*] Installation abgebrochen
    echo [INFO] Danke für die Nutzung des Realme C63 Auto-Installers!
    pause
    exit /b 0
)
echo.
goto :launch_powershell

REM ============================================================================
REM LAUNCH POWERSHELL SCRIPT
REM ============================================================================
:launch_powershell
echo [*] Starte Haupt-Installer (PowerShell)...
echo.

if not exist "%PS_SCRIPT%" (
    color 0C
    echo [FEHLER] PowerShell-Script nicht gefunden!
    echo [PFAD] %PS_SCRIPT%
    echo.
    echo [INFO] Bitte stellen Sie sicher, dass alle Dateien vorhanden sind
    pause
    exit /b 1
)

REM Execute PowerShell script with elevated privileges and bypass execution policy
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -WorkingDirectory "%SCRIPT_DIR%"

set "EXIT_CODE=%errorlevel%"
echo.
if %EXIT_CODE% equ 0 (
    color 0A
    echo [OK] Installation erfolgreich abgeschlossen!
) else (
    color 0C
    echo [FEHLER] Installation mit Fehlercode %EXIT_CODE% beendet
)
echo.
goto :end

REM ============================================================================
REM END
REM ============================================================================
:end
echo.
echo  ╔═══════════════════════════════════════════════════════════════════════╗
echo  ║                                                                       ║
echo  ║     Vielen Dank für die Nutzung des Realme C63 Auto-Installers!     ║
echo  ║                                                                       ║
echo  ║     Support: https://github.com/Xylop90/Realme-C63/issues           ║
echo  ║     Dokumentation: https://github.com/Xylop90/Realme-C63            ║
echo  ║                                                                       ║
echo  ╚═══════════════════════════════════════════════════════════════════════╝
echo.
pause
endlocal
exit /b %EXIT_CODE%
