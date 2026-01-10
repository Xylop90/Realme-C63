@echo off
REM ============================================================================
REM REALME C63 (RMX3939) - ULTIMATE AI-POWERED AUTO-INSTALLER
REM Version: 2.0.0
REM Created: 2026-01-10
REM Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
REM ============================================================================

setlocal EnableDelayedExpansion

REM Set console to UTF-8 for proper character display
chcp 65001 >nul 2>&1

title Realme C63 Ultimate Installer v2.0

REM Colors and styling
color 0B

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                                                                ║
echo ║   ██████╗ ███████╗ █████╗ ██╗     ███╗   ███╗███████╗         ║
echo ║   ██╔══██╗██╔════╝██╔══██╗██║     ████╗ ████║██╔════╝         ║
echo ║   ██████╔╝█████╗  ███████║██║     ██╔████╔██║█████╗           ║
echo ║   ██╔══██╗██╔══╝  ██╔══██║██║     ██║╚██╔╝██║██╔══╝           ║
echo ║   ██║  ██║███████╗██║  ██║███████╗██║ ╚═╝ ██║███████╗         ║
echo ║   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝         ║
echo ║                                                                ║
echo ║              C63 (RMX3939) ULTIMATE INSTALLER v2.0            ║
echo ║          Unlock • Root • TWRP • Firmware • Updates            ║
echo ║                                                                ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo Copyright © Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This installer requires Administrator privileges!
    echo.
    echo Please right-click on INSTALL.bat and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo [OK] Running with Administrator privileges
echo.

REM Check PowerShell version
for /f "tokens=*" %%i in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.Major"') do set PS_VERSION=%%i

if %PS_VERSION% LSS 5 (
    echo [ERROR] PowerShell 5.1 or higher required!
    echo Current version: %PS_VERSION%
    echo.
    echo Please update PowerShell: https://aka.ms/powershell
    pause
    exit /b 1
)

echo [OK] PowerShell version %PS_VERSION% detected
echo.

REM Set execution policy for current process
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force"

echo Starting Ultimate Installer...
echo.

REM Launch the main PowerShell installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ps\Install-RealmeC63-Ultimate.ps1"

set INSTALLER_EXIT_CODE=%errorLevel%

echo.
echo ═══════════════════════════════════════════════════════════════
echo.

if %INSTALLER_EXIT_CODE% equ 0 (
    echo [SUCCESS] Installation completed successfully!
    echo.
    echo Please check the generated report in: work\reports\
) else (
    echo [ERROR] Installation failed with exit code: %INSTALLER_EXIT_CODE%
    echo.
    echo Please check the log file in: work\logs\
)

echo.
echo Press any key to exit...
pause >nul

exit /b %INSTALLER_EXIT_CODE%
