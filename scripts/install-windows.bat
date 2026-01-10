@echo off
REM ============================================================================
REM Xtreme XA-vI ROM - Automated Windows 11 Installation Script
REM Author: Xylop90
REM Date: 2026-01-10
REM Description: Automated installer with ADB/Fastboot, device verification,
REM              backup, recovery flashing, and ROM transfer functionality
REM ============================================================================

setlocal enabledelayedexpansion
color 0A

REM ============================================================================
REM CONFIGURATION VARIABLES
REM ============================================================================
set "SCRIPT_VERSION=1.0"
set "TARGET_DEVICE=Realme C63"
set "ROM_NAME=Xtreme XA-vI"
set "ADB_VERSION=34"
set "PLATFORM_TOOLS_URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
set "BACKUP_DIR=%USERPROFILE%\Desktop\Realme_Backup"
set "WORKING_DIR=%~dp0.."
set "TOOLS_DIR=!WORKING_DIR!\tools"
set "ROM_DIR=!WORKING_DIR!\rom"
set "LOGS_DIR=!WORKING_DIR!\logs"

REM ============================================================================
REM FUNCTION: Display Header
REM ============================================================================
:display_header
cls
echo.
echo ============================================================================
echo       Xtreme XA-vI ROM Automated Installation Tool for Windows 11
echo                        Version !SCRIPT_VERSION!
echo ============================================================================
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Check Administrator Privileges
REM ============================================================================
:check_admin
echo [*] Verifying Administrator Privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [ERROR] This script requires Administrator privileges!
    echo [INFO] Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)
echo [OK] Administrator privileges verified
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Create Required Directories
REM ============================================================================
:create_directories
echo [*] Creating required directories...
if not exist "!TOOLS_DIR!" mkdir "!TOOLS_DIR!"
if not exist "!ROM_DIR!" mkdir "!ROM_DIR!"
if not exist "!LOGS_DIR!" mkdir "!LOGS_DIR!"
if not exist "!BACKUP_DIR!" mkdir "!BACKUP_DIR!"
echo [OK] Directory structure created
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Download and Setup ADB/Fastboot
REM ============================================================================
:setup_adb_fastboot
echo [*] Checking ADB/Fastboot installation...
if exist "!TOOLS_DIR!\platform-tools\adb.exe" (
    echo [OK] ADB/Fastboot already installed
    goto :setup_adb_fastboot_exit
)

echo [*] Downloading Android Platform Tools...
echo [INFO] This may take a few minutes depending on your internet speed...

REM Check if PowerShell is available
powershell -command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('!PLATFORM_TOOLS_URL!', '!TOOLS_DIR!\platform-tools.zip')}" 2>nul
if !errorlevel! equ 0 (
    echo [OK] Platform tools downloaded successfully
) else (
    color 0C
    echo [ERROR] Failed to download Platform Tools
    echo [INFO] Please ensure you have internet connection and PowerShell installed
    echo.
    pause
    exit /b 1
)

echo [*] Extracting platform tools...
cd /d "!TOOLS_DIR!"
powershell -command "& {Expand-Archive -Path '!TOOLS_DIR!\platform-tools.zip' -DestinationPath '!TOOLS_DIR!' -Force}" 2>nul
if !errorlevel! equ 0 (
    echo [OK] Platform tools extracted successfully
    del /f /q "!TOOLS_DIR!\platform-tools.zip"
) else (
    color 0C
    echo [ERROR] Failed to extract platform tools
    pause
    exit /b 1
)

:setup_adb_fastboot_exit
set "ADB_PATH=!TOOLS_DIR!\platform-tools\adb.exe"
set "FASTBOOT_PATH=!TOOLS_DIR!\platform-tools\fastboot.exe"
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Verify Device Connection
REM ============================================================================
:verify_device
echo [*] Verifying device connection...
echo [INFO] Please connect your !TARGET_DEVICE! device via USB
echo [INFO] Enable Developer Mode and USB Debugging on the device
echo.

set "retry_count=0"
set "max_retries=5"

:device_check_loop
"!ADB_PATH!" devices >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=2" %%a in ('"!ADB_PATH!" devices"') do (
        if not "%%a"=="device" if not "%%a"=="List" if not "%%a"=="attached" (
            if "%%a"=="device" (
                set "DEVICE_ID=%%~nxa"
                goto :device_found
            )
        )
    )
)

set /a "retry_count+=1"
if !retry_count! lss !max_retries! (
    echo [*] Waiting for device (Attempt !retry_count!/!max_retries!)...
    timeout /t 3 /nobreak
    goto :device_check_loop
)

color 0C
echo [ERROR] Device not detected after !max_retries! attempts
echo [INFO] Troubleshooting steps:
echo   1. Enable USB Debugging in Developer Options
echo   2. Try a different USB cable or port
echo   3. Install appropriate USB drivers for your device
echo   4. Restart ADB: adb kill-server
echo.
pause
exit /b 1

:device_found
echo [OK] Device detected: !DEVICE_ID!
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Get Device Information
REM ============================================================================
:get_device_info
echo [*] Retrieving device information...
for /f "tokens=*" %%a in ('"!ADB_PATH!" shell getprop ro.product.model"') do set "DEVICE_MODEL=%%a"
for /f "tokens=*" %%a in ('"!ADB_PATH!" shell getprop ro.build.version.release"') do set "ANDROID_VERSION=%%a"
for /f "tokens=*" %%a in ('"!ADB_PATH!" shell getprop ro.serialno"') do set "SERIAL_NUMBER=%%a"

echo [INFO] Device Model: !DEVICE_MODEL!
echo [INFO] Android Version: !ANDROID_VERSION!
echo [INFO] Serial Number: !SERIAL_NUMBER!
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Backup Device Data
REM ============================================================================
:backup_device
echo.
echo ============================================================================
echo                          DEVICE BACKUP
echo ============================================================================
echo.
echo [*] Starting device backup...
echo [INFO] Backup location: !BACKUP_DIR!
echo.

REM Create timestamped backup directory
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set "BACKUP_TIMESTAMP=!mydate!_!mytime!"
set "BACKUP_PATH=!BACKUP_DIR!\backup_!BACKUP_TIMESTAMP!"

mkdir "!BACKUP_PATH!"

echo [*] Backing up application data...
"!ADB_PATH!" backup -apk -shared -all -f "!BACKUP_PATH!\full_backup.adb" 2>nul
if !errorlevel! equ 0 (
    echo [OK] Full device backup completed
) else (
    echo [WARNING] Full backup may require confirmation on device
)

echo [*] Backing up device information...
"!ADB_PATH!" shell dumpsys deviceinitializer > "!BACKUP_PATH!\device_info.txt" 2>nul
"!ADB_PATH!" shell getprop > "!BACKUP_PATH!\device_properties.txt" 2>nul

echo [OK] Backup completed: !BACKUP_PATH!
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Verify ROM Files
REM ============================================================================
:verify_rom_files
echo.
echo ============================================================================
echo                        ROM FILES VERIFICATION
echo ============================================================================
echo.
echo [*] Checking ROM files in: !ROM_DIR!
echo.

if not exist "!ROM_DIR!" (
    color 0C
    echo [ERROR] ROM directory not found: !ROM_DIR!
    echo [INFO] Please place the ROM files in the rom folder
    pause
    exit /b 1
)

set "ROM_FOUND=0"
for %%f in ("!ROM_DIR!\*.zip" "!ROM_DIR!\*.img" "!ROM_DIR!\*.tar") do (
    if exist "%%f" (
        echo [OK] Found ROM: %%~nf
        set "ROM_FOUND=1"
        set "ROM_FILE=%%f"
    )
)

if !ROM_FOUND! equ 0 (
    color 0C
    echo [ERROR] No ROM files found
    echo [INFO] Supported formats: .zip, .img, .tar
    pause
    exit /b 1
)

echo.
goto :eof

REM ============================================================================
REM FUNCTION: Transfer ROM to Device
REM ============================================================================
:transfer_rom
echo.
echo ============================================================================
echo                     ROM TRANSFER TO DEVICE
echo ============================================================================
echo.
echo [*] Transferring ROM file to device storage...
echo [INFO] This may take several minutes depending on file size

REM Create device directory
"!ADB_PATH!" shell mkdir -p /sdcard/XtremeXAvI 2>nul

REM Transfer ROM file
"!ADB_PATH!" push "!ROM_FILE!" /sdcard/XtremeXAvI/ 2>nul
if !errorlevel! equ 0 (
    echo [OK] ROM transferred successfully
) else (
    color 0C
    echo [ERROR] Failed to transfer ROM file
    echo [INFO] Check device storage and connection
    pause
    exit /b 1
)

echo.
goto :eof

REM ============================================================================
REM FUNCTION: Flash Recovery
REM ============================================================================
:flash_recovery
echo.
echo ============================================================================
echo                        RECOVERY FLASHING
echo ============================================================================
echo.

if not exist "!ROM_DIR!\recovery.img" (
    echo [WARNING] Recovery file not found, skipping recovery flash
    echo [INFO] Place recovery.img in the rom folder to enable this step
    echo.
    goto :eof
)

echo [*] Rebooting device to bootloader...
"!ADB_PATH!" reboot bootloader 2>nul
timeout /t 5 /nobreak

echo [*] Flashing recovery partition...
"!FASTBOOT_PATH!" flash recovery "!ROM_DIR!\recovery.img" 2>nul
if !errorlevel! equ 0 (
    echo [OK] Recovery flashed successfully
) else (
    color 0C
    echo [ERROR] Failed to flash recovery
    echo [INFO] Ensure device is in bootloader mode
)

echo [*] Rebooting device...
"!FASTBOOT_PATH!" reboot 2>nul
timeout /t 5 /nobreak
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Display Pre-Installation Summary
REM ============================================================================
:pre_installation_summary
echo.
echo ============================================================================
echo                    PRE-INSTALLATION SUMMARY
echo ============================================================================
echo.
echo Device Information:
echo   Model: !DEVICE_MODEL!
echo   Android Version: !ANDROID_VERSION!
echo   Serial: !SERIAL_NUMBER!
echo.
echo ROM Information:
echo   ROM Name: !ROM_NAME!
echo   ROM File: !ROM_FILE!
echo.
echo Installation Target: !TARGET_DEVICE!
echo Backup Location: !BACKUP_DIR!
echo.
echo ============================================================================
echo [!] WARNING: This process will install a custom ROM
echo [!] All data may be lost. Ensure backup is complete!
echo ============================================================================
echo.
set /p "CONFIRM=Do you want to proceed with installation? (Y/N): "
if /i not "!CONFIRM!"=="Y" (
    echo [*] Installation cancelled
    exit /b 0
)
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Complete Installation Guide
REM ============================================================================
:installation_guide
echo.
echo ============================================================================
echo                     INSTALLATION GUIDE
echo ============================================================================
echo.
echo Follow these steps to complete the ROM installation:
echo.
echo 1. ROM Transfer: Completed
echo    - ROM has been transferred to: /sdcard/XtremeXAvI/
echo.
echo 2. Recovery Flash: Completed (if recovery.img was available)
echo.
echo 3. Manual Installation Steps:
echo    a) Boot into recovery mode (Power + Volume Down)
echo    b) Select "Install from storage"
echo    c) Navigate to: /sdcard/XtremeXAvI/
echo    d) Select the ROM .zip file
echo    e) Confirm installation
echo    f) Wait for installation to complete
echo    g) Select "Reboot system"
echo.
echo 4. Post-Installation:
echo    a) Device will reboot (may take 5-10 minutes)
echo    b) Initial setup will start
echo    c) Restore data if needed (optional)
echo.
echo ============================================================================
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Log Summary
REM ============================================================================
:log_summary
echo.
echo [*] Creating installation log...
set "LOG_FILE=!LOGS_DIR!\install_!BACKUP_TIMESTAMP!.log"

(
    echo Installation Log - !date! !time!
    echo ============================================================================
    echo Device: !DEVICE_MODEL! ^(Serial: !SERIAL_NUMBER!^)
    echo ROM: !ROM_NAME!
    echo Installation Status: Completed
    echo ============================================================================
    echo.
    echo Backup Location: !BACKUP_DIR!
    echo ROM Location: !ROM_FILE!
    echo Logs Location: !LOG_FILE!
) > "!LOG_FILE!"

echo [OK] Log file created: !LOG_FILE!
echo.
goto :eof

REM ============================================================================
REM FUNCTION: Display Main Menu
REM ============================================================================
:main_menu
call :display_header
echo.
echo Select an option:
echo.
echo 1. Full Installation (Recommended)
echo 2. Backup Device Only
echo 3. Flash Recovery Only
echo 4. Transfer ROM Only
echo 5. Verify Device Connection
echo 6. Get Device Information
echo 7. Exit
echo.
set /p "MENU_CHOICE=Enter your choice (1-7): "

if "!MENU_CHOICE!"=="1" goto :full_installation
if "!MENU_CHOICE!"=="2" goto :backup_device
if "!MENU_CHOICE!"=="3" goto :flash_recovery
if "!MENU_CHOICE!"=="4" goto :verify_rom_files
if "!MENU_CHOICE!"=="5" goto :verify_device
if "!MENU_CHOICE!"=="6" goto :get_device_info
if "!MENU_CHOICE!"=="7" exit /b 0

echo [ERROR] Invalid choice
timeout /t 2 /nobreak
goto :main_menu

REM ============================================================================
REM FULL INSTALLATION WORKFLOW
REM ============================================================================
:full_installation
call :display_header
echo [*] Starting full installation workflow...
echo.
call :check_admin
call :create_directories
call :setup_adb_fastboot
call :verify_device
call :get_device_info
call :verify_rom_files
call :backup_device
call :transfer_rom
call :flash_recovery
call :pre_installation_summary
if !errorlevel! neq 0 goto :main_menu
call :installation_guide
call :log_summary

echo [OK] Installation workflow completed
echo [*] Press any key to return to main menu...
pause >nul
goto :main_menu

REM ============================================================================
REM MAIN EXECUTION
REM ============================================================================
:main
call :display_header
call :check_admin

if not exist "!TOOLS_DIR!" call :create_directories
if not exist "!ADB_PATH!" call :setup_adb_fastboot

goto :main_menu

REM Start execution
call :main
endlocal
exit /b 0
