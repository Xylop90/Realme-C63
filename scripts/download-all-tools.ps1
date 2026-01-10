#Requires -Version 5.1
<#
.SYNOPSIS
    Automated Download Script for All Required Tools and Drivers - Realme C63 (RMX3939)
    
.DESCRIPTION
    This PowerShell script automatically downloads all required tools, drivers, and programs
    needed for Realme C63 (RMX3939) bootloader unlock, TWRP installation, and rooting.
    
    Downloads include:
    - ADB and Fastboot tools
    - USB drivers (Google, Universal, Realme, OPPO)
    - TWRP Recovery
    - Magisk (Root)
    - SP Flash Tool (emergency recovery)
    
.PARAMETER DownloadPath
    Directory where all files will be downloaded (default: C:\Realme-C63-Downloads)
    
.PARAMETER SkipOptional
    Skip optional downloads (SP Flash Tool, utilities)
    
.EXAMPLE
    .\download-all-tools.ps1
    .\download-all-tools.ps1 -DownloadPath "D:\MyDownloads"
    .\download-all-tools.ps1 -SkipOptional
    
.NOTES
    Author: Xylop90 / Elektronikx-Center-Matte
    Created: 2026-01-10
    Requires: Windows 10/11, Internet connection
#>

param(
    [string]$DownloadPath = "C:\Realme-C63-Downloads",
    [switch]$SkipOptional
)

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  REALME C63 (RMX3939) - COMPREHENSIVE DOWNLOAD TOOL" -ForegroundColor Cyan
Write-Host "  Version 1.0 - PowerShell Edition" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Define download URLs
$Downloads = @{
    # Essential Tools
    ADBPlatformTools = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    MinimalADB       = "https://androidfilehost.com/?fid=746010030569952951"
    
    # USB Drivers
    GoogleUSBDriver  = "https://dl.google.com/android/repository/usb_driver_r13-windows.zip"
    UniversalADBDriver = "https://adb.clockworkmod.com/latest/UniversalAdbDriverSetup.msi"
    RealmeUSBDriver  = "https://github.com/Xylop90/Realme-C63/releases/download/drivers/realme-usb-driver.zip"
    OPPOUSBDriver    = "https://github.com/Xylop90/Realme-C63/releases/download/drivers/oppo-usb-driver.zip"
    
    # Recovery and Root Tools
    TWRP_RMX3939     = "https://github.com/Xylop90/Realme-C63/releases/download/recovery/twrp-rmx3939.img"
    MagiskLatest     = "https://github.com/topjohnwu/Magisk/releases/latest/download/Magisk-v26.4.apk"
    MagiskCanary     = "https://github.com/topjohnwu/Magisk/releases/download/canary/Magisk-canary.apk"
    
    # Flash Tools (Optional)
    SPFlashTool      = "https://spflashtool.com/download/SP_Flash_Tool_v5.2352_Win.zip"
}

# Create directory structure
$Directories = @{
    Root      = $DownloadPath
    Tools     = Join-Path $DownloadPath "1-Essential-Tools"
    Drivers   = Join-Path $DownloadPath "2-USB-Drivers"
    Recovery  = Join-Path $DownloadPath "3-Recovery-TWRP"
    Root      = Join-Path $DownloadPath "4-Root-Magisk"
    Flash     = Join-Path $DownloadPath "5-Flash-Tools"
    Docs      = Join-Path $DownloadPath "6-Documentation"
}

Write-Host "Creating directory structure..." -ForegroundColor Yellow
foreach ($dir in $Directories.Values) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "✓ Created: $dir" -ForegroundColor Green
    }
}

# Download function
function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$Destination,
        [string]$Description
    )
    
    try {
        Write-Host ""
        Write-Host "Downloading: $Description" -ForegroundColor Cyan
        Write-Host "URL: $Url" -ForegroundColor Gray
        Write-Host "Destination: $Destination" -ForegroundColor Gray
        
        # Use WebClient for progress
        $webClient = New-Object System.Net.WebClient
        
        # Register progress event
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action {
            Write-Progress -Activity "Downloading $Description" -Status "$($EventArgs.ProgressPercentage)% Complete" -PercentComplete $EventArgs.ProgressPercentage
        } | Out-Null
        
        # Start download
        $webClient.DownloadFile($Url, $Destination)
        
        # Unregister event
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        $webClient.Dispose()
        
        Write-Progress -Activity "Downloading $Description" -Completed
        Write-Host "✓ Downloaded successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Download failed: $_" -ForegroundColor Red
        return $false
    }
}

# Download counters
$successCount = 0
$failCount = 0
$totalItems = 0

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  STARTING DOWNLOADS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Phase 1: Essential Tools
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "  PHASE 1: Essential Tools (ADB & Fastboot)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow

$totalItems++
$dest = Join-Path $Directories.Tools "platform-tools.zip"
if (Download-FileWithProgress -Url $Downloads.ADBPlatformTools -Destination $dest -Description "Android Platform Tools") {
    $successCount++
} else {
    $failCount++
}

# Phase 2: USB Drivers
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "  PHASE 2: USB Drivers" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow

# Google USB Driver
$totalItems++
$dest = Join-Path $Directories.Drivers "google-usb-driver.zip"
if (Download-FileWithProgress -Url $Downloads.GoogleUSBDriver -Destination $dest -Description "Google USB Driver") {
    $successCount++
} else {
    $failCount++
}

# Universal ADB Driver
$totalItems++
$dest = Join-Path $Directories.Drivers "universal-adb-driver.msi"
if (Download-FileWithProgress -Url $Downloads.UniversalADBDriver -Destination $dest -Description "Universal ADB Driver") {
    $successCount++
} else {
    $failCount++
}

# Realme USB Driver
$totalItems++
$dest = Join-Path $Directories.Drivers "realme-usb-driver.zip"
if (Download-FileWithProgress -Url $Downloads.RealmeUSBDriver -Destination $dest -Description "Realme USB Driver") {
    $successCount++
} else {
    $failCount++
}

# OPPO USB Driver
$totalItems++
$dest = Join-Path $Directories.Drivers "oppo-usb-driver.zip"
if (Download-FileWithProgress -Url $Downloads.OPPOUSBDriver -Destination $dest -Description "OPPO USB Driver") {
    $successCount++
} else {
    $failCount++
}

# Phase 3: Recovery (TWRP)
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "  PHASE 3: Custom Recovery (TWRP)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow

$totalItems++
$dest = Join-Path $Directories.Recovery "twrp-rmx3939.img"
if (Download-FileWithProgress -Url $Downloads.TWRP_RMX3939 -Destination $dest -Description "TWRP Recovery for RMX3939") {
    $successCount++
} else {
    $failCount++
    Write-Host "! Note: You may need to download TWRP manually from https://twrp.me" -ForegroundColor Yellow
}

# Phase 4: Root (Magisk)
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "  PHASE 4: Root Tools (Magisk)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow

# Magisk Latest
$totalItems++
$dest = Join-Path $Directories.Root "Magisk-latest.apk"
if (Download-FileWithProgress -Url $Downloads.MagiskLatest -Destination $dest -Description "Magisk Latest Stable") {
    $successCount++
} else {
    $failCount++
}

# Magisk Canary
$totalItems++
$dest = Join-Path $Directories.Root "Magisk-canary.apk"
if (Download-FileWithProgress -Url $Downloads.MagiskCanary -Destination $dest -Description "Magisk Canary (Beta)") {
    $successCount++
} else {
    $failCount++
}

# Phase 5: Flash Tools (Optional)
if (-not $SkipOptional) {
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  PHASE 5: Flash Tools (Optional - For Emergency)" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    
    $totalItems++
    $dest = Join-Path $Directories.Flash "sp-flash-tool.zip"
    if (Download-FileWithProgress -Url $Downloads.SPFlashTool -Destination $dest -Description "SP Flash Tool") {
        $successCount++
    } else {
        $failCount++
    }
}

# Create README in each folder
Write-Host ""
Write-Host "Creating README files..." -ForegroundColor Yellow

$readmeTools = @"
# Essential Tools

## Android Platform Tools (ADB & Fastboot)
- File: platform-tools.zip
- Extract this file to use ADB and Fastboot commands
- Add to system PATH for easy access

## Usage:
1. Extract platform-tools.zip
2. Open Command Prompt in the extracted folder
3. Run: adb devices (to check connected devices)
4. Run: fastboot devices (when device is in fastboot mode)

For more information, see: https://developer.android.com/studio/command-line/adb
"@

$readmeDrivers = @"
# USB Drivers

Install these drivers to ensure your computer can communicate with your Realme C63 device.

## Included Drivers:
1. **Google USB Driver** - Official Google Android USB driver
2. **Universal ADB Driver** - Universal driver for most Android devices
3. **Realme USB Driver** - Realme-specific driver
4. **OPPO USB Driver** - OPPO driver (Realme is OPPO sub-brand)

## Installation:
1. Extract all ZIP files
2. Run .msi installers or install via Device Manager
3. Restart computer after installation
4. Connect device and verify with: adb devices

**Note:** Install in order: Google → Universal → Realme → OPPO
"@

$readmeRecovery = @"
# TWRP Recovery for Realme C63 (RMX3939)

## File: twrp-rmx3939.img

## Installation:
1. Unlock bootloader first (see documentation)
2. Boot device to fastboot mode
3. Run: fastboot flash recovery twrp-rmx3939.img
4. Boot to recovery: fastboot reboot recovery

## Alternative (Temporary Boot):
1. Run: fastboot boot twrp-rmx3939.img
2. Device boots into TWRP without permanent installation

For more information, see: ../6-Documentation/TWRP_INSTALLATION.md
"@

$readmeRoot = @"
# Magisk - Root Solution

## Files:
- **Magisk-latest.apk** - Latest stable release
- **Magisk-canary.apk** - Beta/development version (use stable unless testing)

## Installation:
1. Install Magisk APK on device
2. Transfer boot.img to device
3. Open Magisk app → Install → Patch boot.img
4. Transfer patched image back to PC
5. Flash: fastboot flash boot magisk_patched.img

## Features:
- Systemless root
- SafetyNet support (with modules)
- Magisk modules support
- Hide root from apps

For detailed instructions, see: ../6-Documentation/ROOTING_GUIDE.md
"@

$readmeFlash = @"
# SP Flash Tool (Emergency Recovery)

## File: sp-flash-tool.zip

**WARNING:** Only use SP Flash Tool if you have:
- Bricked device
- Corrupted bootloader
- Cannot access fastboot mode
- Stock firmware file for your device

## Usage:
1. Download stock firmware for RMX3939
2. Extract SP Flash Tool
3. Run Flash_tool.exe
4. Load scatter file from firmware
5. Connect device in EDL/Meta mode
6. Click Download button

**CAUTION:** Incorrect use can permanently brick your device!

Only use this tool as a last resort for device recovery.
"@

# Write README files
Set-Content -Path (Join-Path $Directories.Tools "README.txt") -Value $readmeTools
Set-Content -Path (Join-Path $Directories.Drivers "README.txt") -Value $readmeDrivers
Set-Content -Path (Join-Path $Directories.Recovery "README.txt") -Value $readmeRecovery
Set-Content -Path (Join-Path $Directories.Root "README.txt") -Value $readmeRoot
if (-not $SkipOptional) {
    Set-Content -Path (Join-Path $Directories.Flash "README.txt") -Value $readmeFlash
}

Write-Host "✓ README files created in each folder" -ForegroundColor Green

# Download summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DOWNLOAD SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total items: $totalItems" -ForegroundColor White
Write-Host "✓ Successful: $successCount" -ForegroundColor Green
Write-Host "✗ Failed: $failCount" -ForegroundColor Red
Write-Host ""
Write-Host "Download location: $DownloadPath" -ForegroundColor Cyan
Write-Host ""

# Create download manifest
$manifest = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalItems = $totalItems
    Successful = $successCount
    Failed = $failCount
    DownloadPath = $DownloadPath
    Downloads = $Downloads
}

$manifestPath = Join-Path $DownloadPath "download-manifest.json"
$manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath
Write-Host "✓ Download manifest saved: $manifestPath" -ForegroundColor Green

# Next steps
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Install USB drivers from: $($Directories.Drivers)" -ForegroundColor White
Write-Host "2. Extract and setup ADB from: $($Directories.Tools)" -ForegroundColor White
Write-Host "3. Read documentation in: $($Directories.Docs)" -ForegroundColor White
Write-Host "4. Follow guides for bootloader unlock and rooting" -ForegroundColor White
Write-Host ""
Write-Host "For detailed instructions, see the repository documentation:" -ForegroundColor Yellow
Write-Host "https://github.com/Xylop90/Realme-C63/tree/main/docs" -ForegroundColor Cyan
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "⚠ Some downloads failed. Please check URLs or download manually." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Download completed! Press any key to exit..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
