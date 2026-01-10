#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Ultimate AI-Powered Auto-Installer for Realme C63 (RMX3939)

.DESCRIPTION
    Main orchestrator script for automated bootloader unlock, root installation,
    and complete device setup with intelligent decision-making and fallback mechanisms.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 2.0.0
    Created: 2026-01-10
    
.EXAMPLE
    .\Install-RealmeC63-Ultimate.ps1
    .\Install-RealmeC63-Ultimate.ps1 -SkipBootloaderUnlock
    .\Install-RealmeC63-Ultimate.ps1 -UnlockOnly
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipBootloaderUnlock,

    [Parameter(Mandatory=$false)]
    [switch]$SkipRoot,

    [Parameter(Mandatory=$false)]
    [switch]$UnlockOnly,

    [Parameter(Mandatory=$false)]
    [switch]$RootOnly,

    [Parameter(Mandatory=$false)]
    [string]$Language = "de"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get script root directory
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$ProjectRoot = Split-Path -Parent $ScriptRoot

# Import all modules
$ModulePath = Join-Path $ProjectRoot "scripts\modules"
$Modules = @(
    "Logger.psm1",
    "UI-Helper.psm1",
    "Error-Handler.psm1",
    "Device-Manager.psm1",
    "Download-Manager.psm1",
    "Hash-Verifier.psm1",
    "Python-Manager.psm1",
    "Bootloader-Unlock.psm1",
    "Root-Manager.psm1"
)

foreach ($Module in $Modules) {
    $ModuleFile = Join-Path $ModulePath $Module
    if (Test-Path $ModuleFile) {
        Import-Module $ModuleFile -Force
    }
    else {
        Write-Error "Module not found: $ModuleFile"
        exit 1
    }
}

# Initialize logger
Initialize-Logger -LogPath (Join-Path $ProjectRoot "work\logs")

# Initialize localization
Initialize-Localization -Language $Language

# Initialize error handler
Initialize-ErrorHandler -CheckpointPath (Join-Path $ProjectRoot "work\checkpoints")

# Main installation function
function Start-Installation {
    [CmdletBinding()]
    param()

    try {
        # Show banner
        Clear-Host
        Show-Banner

        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  ULTIMATE AI-POWERED AUTO-INSTALLER FOR REALME C63 (RMX3939)  ║" -ForegroundColor Cyan
        Write-Host "║                         VERSION 2.0.0                          ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Xtreme XA-I KI Elektronikx-Center-Matte Cyber ®" -ForegroundColor Gray
        Write-Host "  By Alexander Mathey" -ForegroundColor Gray
        Write-Host ""

        # Create checkpoint
        $mainCheckpoint = New-Checkpoint -Name "InstallationStart"

        # System check
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host " SYSTEM-CHECK / SYSTEM CHECK" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        # Check if running as admin
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Error "Dieses Skript muss als Administrator ausgeführt werden / This script must be run as administrator"
            return
        }
        Write-Host "✓ Administrator-Rechte erkannt / Administrator rights detected" -ForegroundColor Green

        # Check ADB/Fastboot
        $adbAvailable = Test-ADBAvailable
        if ($adbAvailable) {
            Write-Host "✓ ADB verfügbar / ADB available" -ForegroundColor Green
        }
        else {
            Write-Warning "ADB nicht gefunden / ADB not found"
            Write-Host "ADB wird heruntergeladen / Downloading ADB..." -ForegroundColor Cyan
            
            # Download ADB/Fastboot
            $platformToolsUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
            $platformToolsDest = Join-Path $ProjectRoot "work\downloads\platform-tools.zip"
            
            $downloadResult = Get-RemoteFile -Url $platformToolsUrl -Destination $platformToolsDest
            
            if ($downloadResult.Success) {
                # Extract
                $extractPath = Join-Path $ProjectRoot "work\extracted\platform-tools"
                Expand-Archive -Path $platformToolsDest -DestinationPath $extractPath -Force
                
                # Add to PATH temporarily
                $adbPath = Join-Path $extractPath "platform-tools"
                $env:PATH = "$adbPath;$env:PATH"
                
                Write-Host "✓ ADB installiert / ADB installed" -ForegroundColor Green
            }
            else {
                Write-Error "Fehler beim Download von ADB / Failed to download ADB"
                return
            }
        }

        $fastbootAvailable = Test-FastbootAvailable
        if ($fastbootAvailable) {
            Write-Host "✓ Fastboot verfügbar / Fastboot available" -ForegroundColor Green
        }

        Write-Host ""

        # Show main menu
        $selectedOption = Show-InstallationMenu

        switch ($selectedOption) {
            1 { # Full installation
                Invoke-FullInstallation
            }
            2 { # Bootloader unlock only
                Invoke-BootloaderUnlockOnly
            }
            3 { # Root only
                Invoke-RootOnly
            }
            4 { # Device info
                Show-DeviceInfo
            }
            5 { # Exit
                Write-Host "Installation abgebrochen / Installation cancelled" -ForegroundColor Yellow
                return
            }
        }

        # Installation complete
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║              INSTALLATION ABGESCHLOSSEN / COMPLETE             ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""

        # Cleanup old checkpoints
        Clear-OldCheckpoints -DaysOld 7

        Write-Host "Drücken Sie eine Taste zum Beenden / Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Error "Installation failed: $_"
        Write-Log "Installation failed: $_" "ERROR"
        
        # Show rollback option
        $rollback = Show-Confirmation -Message "Möchten Sie einen Rollback durchführen? / Perform rollback?"
        if ($rollback) {
            Invoke-Rollback -CheckpointName "InstallationStart"
        }
    }
}

function Show-InstallationMenu {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " INSTALLATION-MENÜ / INSTALLATION MENU" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $menuItems = @(
        "Vollständige Installation / Full Installation (Unlock + Root)",
        "Nur Bootloader entsperren / Bootloader Unlock Only",
        "Nur Root installieren / Root Only",
        "Geräteinformationen anzeigen / Show Device Info",
        "Beenden / Exit"
    )

    return Show-Menu -Title "Bitte wählen Sie eine Option / Please select an option:" -Options $menuItems
}

function Invoke-FullInstallation {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " VOLLSTÄNDIGE INSTALLATION / FULL INSTALLATION" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Device detection
    Write-Host "[1/4] Geräteerkennung / Device Detection" -ForegroundColor Yellow
    $deviceInfo = Invoke-SafeOperation -Operation {
        Get-DeviceStatus
    } -ErrorMessage "Geräteerkennung fehlgeschlagen / Device detection failed"

    if ($deviceInfo.DeviceConnected) {
        Write-Host "✓ Gerät erkannt / Device detected: $($deviceInfo.Model)" -ForegroundColor Green
    }
    else {
        Write-Warning "Kein Gerät erkannt / No device detected"
        Write-Host "Bitte verbinden Sie Ihr Gerät und aktivieren Sie USB-Debugging" -ForegroundColor Yellow
        Write-Host "Please connect your device and enable USB debugging" -ForegroundColor Yellow
        
        $connected = Wait-ForDevice -Mode "ADB" -TimeoutSeconds 120
        if (-not $connected) {
            throw "Device not connected"
        }
    }

    # Step 2: Bootloader unlock
    Write-Host ""
    Write-Host "[2/4] Bootloader entsperren / Bootloader Unlock" -ForegroundColor Yellow
    
    $isUnlocked = Test-BootloaderUnlocked
    if ($isUnlocked) {
        Write-Host "✓ Bootloader bereits entsperrt / Bootloader already unlocked" -ForegroundColor Green
    }
    else {
        $unlockResult = Unlock-Bootloader
        
        if (-not $unlockResult.Success) {
            throw "Bootloader unlock failed: $($unlockResult.Error)"
        }
        
        Write-Host "✓ Bootloader erfolgreich entsperrt / Bootloader successfully unlocked" -ForegroundColor Green
    }

    # Step 3: Download firmware (optional)
    Write-Host ""
    Write-Host "[3/4] Firmware-Download (Optional)" -ForegroundColor Yellow
    
    $downloadFirmware = Show-Confirmation -Message "Möchten Sie Firmware herunterladen? / Download firmware?"
    
    if ($downloadFirmware) {
        Write-Host "Firmware-Download noch nicht implementiert / Firmware download not yet implemented" -ForegroundColor Yellow
        Write-Host "Bitte laden Sie Firmware manuell herunter von / Please download firmware manually from:" -ForegroundColor Yellow
        Write-Host "- https://www.getdroidtips.com/realme-c63-firmware/" -ForegroundColor Cyan
        Write-Host "- https://gsmmafia.com/realme-c63-rmx3939-flash-file/" -ForegroundColor Cyan
        
        $firmwarePath = Read-Host "Pfad zur Firmware-Datei / Path to firmware file (oder leer lassen / or leave empty)"
    }
    else {
        $firmwarePath = ""
    }

    # Step 4: Root installation
    Write-Host ""
    Write-Host "[4/4] Root-Installation / Root Installation" -ForegroundColor Yellow
    
    $rootParams = @{}
    if (-not [string]::IsNullOrWhiteSpace($firmwarePath) -and (Test-Path $firmwarePath)) {
        $rootParams['FirmwarePath'] = $firmwarePath
    }
    
    $rootResult = Install-MagiskRoot @rootParams
    
    if (-not $rootResult.Success) {
        throw "Root installation failed: $($rootResult.Error)"
    }
    
    Write-Host "✓ Root erfolgreich installiert / Root successfully installed" -ForegroundColor Green
}

function Invoke-BootloaderUnlockOnly {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " BOOTLOADER ENTSPERREN / BOOTLOADER UNLOCK" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Check if already unlocked
    $isUnlocked = Test-BootloaderUnlocked
    if ($isUnlocked) {
        Write-Host "✓ Bootloader bereits entsperrt / Bootloader already unlocked" -ForegroundColor Green
        return
    }

    # Unlock
    $unlockResult = Unlock-Bootloader
    
    if ($unlockResult.Success) {
        Write-Host "✓ Bootloader erfolgreich entsperrt / Bootloader successfully unlocked" -ForegroundColor Green
    }
    else {
        Write-Error "Bootloader unlock fehlgeschlagen / Bootloader unlock failed: $($unlockResult.Error)"
    }
}

function Invoke-RootOnly {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " ROOT-INSTALLATION / ROOT INSTALLATION" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Check bootloader
    $isUnlocked = Test-BootloaderUnlocked
    if (-not $isUnlocked) {
        Write-Warning "Bootloader ist gesperrt / Bootloader is locked"
        Write-Host "Root-Installation erfordert entsperrten Bootloader / Root installation requires unlocked bootloader" -ForegroundColor Yellow
        
        $unlock = Show-Confirmation -Message "Bootloader jetzt entsperren? / Unlock bootloader now?"
        if ($unlock) {
            Invoke-BootloaderUnlockOnly
        }
        else {
            return
        }
    }

    # Install root
    $rootResult = Install-MagiskRoot
    
    if ($rootResult.Success) {
        Write-Host "✓ Root erfolgreich installiert / Root successfully installed" -ForegroundColor Green
    }
    else {
        Write-Error "Root-Installation fehlgeschlagen / Root installation failed: $($rootResult.Error)"
    }
}

function Show-DeviceInfo {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " GERÄTEINFORMATIONEN / DEVICE INFORMATION" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    $deviceInfo = Get-DeviceInfo
    
    if ($null -eq $deviceInfo) {
        Write-Warning "Kein Gerät verbunden / No device connected"
        return
    }

    Write-Host "Hersteller / Manufacturer: " -NoNewline
    Write-Host $deviceInfo.Manufacturer -ForegroundColor Cyan
    
    Write-Host "Modell / Model: " -NoNewline
    Write-Host $deviceInfo.Model -ForegroundColor Cyan
    
    Write-Host "Android-Version / Android Version: " -NoNewline
    Write-Host $deviceInfo.AndroidVersion -ForegroundColor Cyan
    
    Write-Host "Seriennummer / Serial Number: " -NoNewline
    Write-Host $deviceInfo.SerialNumber -ForegroundColor Cyan
    
    Write-Host "Bootloader-Status / Bootloader Status: " -NoNewline
    $bootloaderStatus = Get-BootloaderStatus
    if ($bootloaderStatus -eq "Unlocked") {
        Write-Host $bootloaderStatus -ForegroundColor Green
    }
    else {
        Write-Host $bootloaderStatus -ForegroundColor Red
    }
    
    Write-Host "Root-Status / Root Status: " -NoNewline
    $isRooted = Test-DeviceRooted
    if ($isRooted) {
        Write-Host "Gerootet / Rooted" -ForegroundColor Green
    }
    else {
        Write-Host "Nicht gerootet / Not rooted" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Entry point
try {
    Start-Installation
}
catch {
    Write-Error "Fatal error: $_"
    Write-Log "Fatal error: $_" "FATAL"
    
    Write-Host ""
    Write-Host "Drücken Sie eine Taste zum Beenden / Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    exit 1
}
