#Requires -Version 5.1
<#
.SYNOPSIS
    Automated Installation Wizard for Realme C63 on Windows 11
    
.DESCRIPTION
    This script provides an automated installation wizard for setting up ADB/Fastboot,
    USB drivers, device verification, bootloader unlocking, recovery flashing, and ROM flashing
    for Realme C63 devices on Windows 11.
    
.PARAMETER WorkingDirectory
    Base directory for installation and temporary files (default: C:\Realme-C63-Tools)
    
.PARAMETER SkipADB
    Skip ADB/Fastboot download if already installed
    
.PARAMETER SkipDrivers
    Skip USB driver installation
    
.EXAMPLE
    .\install-windows.ps1
    .\install-windows.ps1 -WorkingDirectory "D:\MyTools" -SkipADB
    
.NOTES
    Author: Realme C63 Installation Wizard
    Created: 2026-01-10
    Requires: Windows 11, Administrator privileges
#>

param(
    [string]$WorkingDirectory = "C:\Realme-C63-Tools",
    [switch]$SkipADB,
    [switch]$SkipDrivers
)

# ============================================================================
# GLOBAL VARIABLES AND CONFIGURATION
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Color codes for console output
$Colors = @{
    Info    = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Prompt  = "Magenta"
}

# Directory structure
$Paths = @{
    Root      = $WorkingDirectory
    ADB       = Join-Path $WorkingDirectory "adb"
    Drivers   = Join-Path $WorkingDirectory "drivers"
    Recovery  = Join-Path $WorkingDirectory "recovery"
    ROM       = Join-Path $WorkingDirectory "rom"
    Logs      = Join-Path $WorkingDirectory "logs"
}

# URLs for downloads
$Downloads = @{
    ADBPlatformTools = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    RealmeLdacDriver = "https://realme-device-drivers.s3.amazonaws.com/realme-usb-driver-windows.zip"
}

# Log file
$LogFile = Join-Path $Paths.Logs "installation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
    Write messages to console and log file with timestamps and color coding
    #>
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorType = $Colors[$Level]
    
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Host $LogMessage -ForegroundColor $ColorType
    
    # Ensure log directory exists
    if (-not (Test-Path $Paths.Logs)) {
        New-Item -Path $Paths.Logs -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $LogFile -Value $LogMessage -Force
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
    Verify script is running with administrator privileges
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Banner {
    <#
    .SYNOPSIS
    Display welcome banner
    #>
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "║     REALME C63 - AUTOMATED INSTALLATION WIZARD             ║" -ForegroundColor Cyan
    Write-Host "║                  Windows 11 Edition                        ║" -ForegroundColor Cyan
    Write-Host "║                                                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Installation wizard started" "Info"
}

function Show-Menu {
    <#
    .SYNOPSIS
    Display main menu and get user selection
    #>
    param(
        [string[]]$Options,
        [string]$Title = "Select an option"
    )
    
    Write-Host ""
    Write-Host "┌─ $Title" -ForegroundColor $Colors.Prompt
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "│  $($i + 1). $($Options[$i])" -ForegroundColor White
    }
    Write-Host "└─" -ForegroundColor $Colors.Prompt
    
    do {
        [int]$selection = Read-Host "Enter your choice (1-$($Options.Count))"
        if ($selection -ge 1 -and $selection -le $Options.Count) {
            return $selection - 1
        }
        Write-Host "Invalid selection. Please try again." -ForegroundColor $Colors.Warning
    } while ($true)
}

function Test-InternetConnection {
    <#
    .SYNOPSIS
    Test internet connectivity
    #>
    try {
        $null = Test-Connection -ComputerName "google.com" -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Log "Internet connection test failed" "Warning"
        return $false
    }
}

function New-DirectoryStructure {
    <#
    .SYNOPSIS
    Create required directory structure
    #>
    Write-Log "Creating directory structure..." "Info"
    
    foreach ($path in $Paths.Values) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Log "Created directory: $path" "Success"
        }
    }
}

function Download-File {
    <#
    .SYNOPSIS
    Download file with progress indication
    #>
    param(
        [string]$URL,
        [string]$Destination,
        [string]$Description = "File"
    )
    
    try {
        Write-Log "Downloading $Description..." "Info"
        
        $ProgressPreference = "Continue"
        Invoke-WebRequest -Uri $URL -OutFile $Destination -UseBasicParsing
        $ProgressPreference = "SilentlyContinue"
        
        if (Test-Path $Destination) {
            Write-Log "$Description downloaded successfully: $Destination" "Success"
            return $true
        }
        else {
            Write-Log "Failed to download $Description" "Error"
            return $false
        }
    }
    catch {
        Write-Log "Download error for $Description : $_" "Error"
        return $false
    }
}

function Expand-ZipFile {
    <#
    .SYNOPSIS
    Extract ZIP archive
    #>
    param(
        [string]$ZipFile,
        [string]$Destination,
        [string]$Description = "Archive"
    )
    
    try {
        Write-Log "Extracting $Description..." "Info"
        
        if (Test-Path $ZipFile) {
            Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force
            Write-Log "$Description extracted successfully" "Success"
            return $true
        }
        else {
            Write-Log "$Description file not found: $ZipFile" "Error"
            return $false
        }
    }
    catch {
        Write-Log "Extraction error for $Description : $_" "Error"
        return $false
    }
}

# ============================================================================
# ADB/FASTBOOT INSTALLATION
# ============================================================================

function Install-ADBFastboot {
    <#
    .SYNOPSIS
    Download and install Android Debug Bridge and Fastboot
    #>
    Write-Log "Starting ADB/Fastboot installation..." "Info"
    
    # Check if ADB already exists
    $adbPath = Join-Path $Paths.ADB "adb.exe"
    if ((Test-Path $adbPath) -and $SkipADB) {
        Write-Log "ADB already installed at $adbPath - skipping download" "Info"
        return $true
    }
    
    # Check internet connection
    if (-not (Test-InternetConnection)) {
        Write-Log "Internet connection required for ADB download" "Error"
        Read-Host "Press Enter to continue..."
        return $false
    }
    
    # Download Platform Tools
    $zipFile = Join-Path $Paths.ADB "platform-tools.zip"
    if (-not (Download-File -URL $Downloads.ADBPlatformTools -Destination $zipFile -Description "Android Platform Tools")) {
        Write-Log "Failed to download ADB/Fastboot" "Error"
        return $false
    }
    
    # Extract Platform Tools
    $extractPath = Join-Path $Paths.ADB "extracted"
    if (-not (Expand-ZipFile -ZipFile $zipFile -Destination $extractPath -Description "Platform Tools")) {
        return $false
    }
    
    # Move files to ADB directory
    try {
        $platformToolsPath = Get-ChildItem -Path $extractPath -Directory -Filter "platform-tools" | Select-Object -First 1
        if ($platformToolsPath) {
            Get-ChildItem -Path $platformToolsPath.FullName | Move-Item -Destination $Paths.ADB -Force
            Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Log "ADB/Fastboot installed successfully at $($Paths.ADB)" "Success"
        return $true
    }
    catch {
        Write-Log "Error organizing ADB files: $_" "Error"
        return $false
    }
}

function Add-ADBToPath {
    <#
    .SYNOPSIS
    Add ADB directory to system PATH environment variable
    #>
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        
        if ($currentPath -notlike "*$($Paths.ADB)*") {
            $newPath = "$currentPath;$($Paths.ADB)"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            Write-Log "ADB added to system PATH" "Success"
            return $true
        }
        else {
            Write-Log "ADB already in system PATH" "Info"
            return $true
        }
    }
    catch {
        Write-Log "Error adding ADB to PATH: $_" "Error"
        return $false
    }
}

# ============================================================================
# USB DRIVER INSTALLATION
# ============================================================================

function Install-USBDrivers {
    <#
    .SYNOPSIS
    Download and install Realme USB drivers
    #>
    Write-Log "Starting USB driver installation..." "Info"
    
    if ($SkipDrivers) {
        Write-Log "USB driver installation skipped (--SkipDrivers flag)" "Info"
        return $true
    }
    
    # Check internet connection
    if (-not (Test-InternetConnection)) {
        Write-Log "Internet connection required for driver download" "Error"
        Read-Host "Press Enter to continue..."
        return $false
    }
    
    # Download drivers
    $driverZip = Join-Path $Paths.Drivers "realme-drivers.zip"
    if (-not (Download-File -URL $Downloads.RealmeLdacDriver -Destination $driverZip -Description "Realme USB Drivers")) {
        Write-Log "Could not download drivers - trying offline installation" "Warning"
        return $false
    }
    
    # Extract drivers
    if (-not (Expand-ZipFile -ZipFile $driverZip -Destination $Paths.Drivers -Description "USB Drivers")) {
        return $false
    }
    
    # Try to install drivers
    try {
        $infFiles = Get-ChildItem -Path $Paths.Drivers -Filter "*.inf" -Recurse
        
        if ($infFiles) {
            foreach ($infFile in $infFiles) {
                Write-Log "Installing driver: $($infFile.Name)" "Info"
                pnputil.exe /add-driver "$($infFile.FullName)" /install | Out-Null
                Write-Log "Driver installed: $($infFile.Name)" "Success"
            }
        }
        else {
            Write-Log "No .inf driver files found in extracted drivers" "Warning"
        }
        
        return $true
    }
    catch {
        Write-Log "Error installing drivers: $_" "Error"
        return $false
    }
}

# ============================================================================
# DEVICE CONNECTION VERIFICATION
# ============================================================================

function Verify-DeviceConnection {
    <#
    .SYNOPSIS
    Verify device connection via ADB
    #>
    Write-Log "Verifying device connection..." "Info"
    
    $adbPath = Join-Path $Paths.ADB "adb.exe"
    
    if (-not (Test-Path $adbPath)) {
        Write-Log "ADB executable not found at $adbPath" "Error"
        return $false
    }
    
    try {
        # Start ADB server
        Write-Log "Starting ADB server..." "Info"
        & $adbPath start-server | Out-Null
        
        Start-Sleep -Seconds 2
        
        # List connected devices
        Write-Log "Scanning for connected devices..." "Info"
        $devices = & $adbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S+' }
        
        if ($devices) {
            Write-Log "Connected devices found:" "Success"
            foreach ($device in $devices) {
                Write-Host "  $device" -ForegroundColor Green
            }
            return $true
        }
        else {
            Write-Log "No devices detected" "Warning"
            Write-Log "Please ensure:" "Info"
            Write-Log "  1. Device is connected via USB cable" "Info"
            Write-Log "  2. USB debugging is enabled on device" "Info"
            Write-Log "  3. You accept the RSA fingerprint prompt on device" "Info"
            return $false
        }
    }
    catch {
        Write-Log "Error verifying device connection: $_" "Error"
        return $false
    }
}

function Wait-ForDevice {
    <#
    .SYNOPSIS
    Wait for device to be connected with timeout
    #>
    param(
        [int]$TimeoutSeconds = 30
    )
    
    Write-Log "Waiting for device connection (timeout: ${TimeoutSeconds}s)..." "Info"
    
    $adbPath = Join-Path $Paths.ADB "adb.exe"
    $startTime = Get-Date
    
    try {
        while ((New-TimeSpan -Start $startTime).TotalSeconds -lt $TimeoutSeconds) {
            $devices = & $adbPath devices 2>$null | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
            
            if ($devices) {
                Write-Log "Device connected!" "Success"
                return $true
            }
            
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 1
        }
        
        Write-Log "Device connection timeout" "Warning"
        return $false
    }
    catch {
        Write-Log "Error waiting for device: $_" "Error"
        return $false
    }
}

# ============================================================================
# BOOTLOADER UNLOCK
# ============================================================================

function Unlock-Bootloader {
    <#
    .SYNOPSIS
    Unlock device bootloader via Fastboot
    #>
    Write-Log "Starting bootloader unlock procedure..." "Info"
    
    $fastbootPath = Join-Path $Paths.ADB "fastboot.exe"
    
    if (-not (Test-Path $fastbootPath)) {
        Write-Log "Fastboot executable not found" "Error"
        return $false
    }
    
    try {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║               BOOTLOADER UNLOCK WARNING                    ║" -ForegroundColor Yellow
        Write-Host "║                                                            ║" -ForegroundColor Yellow
        Write-Host "║  Unlocking the bootloader will:                            ║" -ForegroundColor Yellow
        Write-Host "║  • ERASE all data on your device                           ║" -ForegroundColor Yellow
        Write-Host "║  • Void your device warranty                               ║" -ForegroundColor Yellow
        Write-Host "║  • Enable installation of custom ROMs                      ║" -ForegroundColor Yellow
        Write-Host "║                                                            ║" -ForegroundColor Yellow
        Write-Host "║  Ensure your data is backed up before proceeding!          ║" -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        
        $confirm = Read-Host "Type 'YES' to unlock bootloader"
        
        if ($confirm -ne "YES") {
            Write-Log "Bootloader unlock cancelled by user" "Info"
            return $false
        }
        
        Write-Log "Waiting for device in Fastboot mode..." "Info"
        Write-Log "You should see 'fastboot' in the device connection status" "Info"
        
        $bootloaderLocked = & $fastbootPath getvar locked 2>&1
        
        if ($bootloaderLocked -match "locked: yes") {
            Write-Log "Device bootloader is locked. Sending unlock command..." "Info"
            & $fastbootPath flashing unlock | Out-Null
            
            Write-Log "Unlock command sent to device" "Info"
            Write-Log "Press the volume down button to confirm unlock on device" "Warning"
            
            Start-Sleep -Seconds 3
            Write-Log "Bootloader unlock completed" "Success"
            return $true
        }
        elseif ($bootloaderLocked -match "locked: no") {
            Write-Log "Device bootloader is already unlocked" "Info"
            return $true
        }
        else {
            Write-Log "Could not determine bootloader lock status" "Warning"
            return $false
        }
    }
    catch {
        Write-Log "Error unlocking bootloader: $_" "Error"
        return $false
    }
}

# ============================================================================
# RECOVERY FLASHING
# ============================================================================

function Flash-Recovery {
    <#
    .SYNOPSIS
    Flash custom recovery image
    #>
    Write-Log "Starting recovery flashing procedure..." "Info"
    
    $fastbootPath = Join-Path $Paths.ADB "fastboot.exe"
    
    # Get recovery image path
    Write-Host ""
    Write-Host "Select recovery image to flash:" -ForegroundColor $Colors.Prompt
    
    $recoveryImages = Get-ChildItem -Path $Paths.Recovery -Filter "*.img" | Select-Object -ExpandProperty FullName
    
    if (-not $recoveryImages) {
        Write-Log "No recovery images found in $($Paths.Recovery)" "Warning"
        Write-Log "Please place recovery image (.img) in the recovery directory" "Info"
        return $false
    }
    
    if ($recoveryImages -is [string]) {
        $selectedRecovery = $recoveryImages
    }
    else {
        $selection = Show-Menu -Options $recoveryImages -Title "Recovery Images"
        $selectedRecovery = $recoveryImages[$selection]
    }
    
    try {
        Write-Log "Flashing recovery image: $selectedRecovery" "Info"
        & $fastbootPath flash recovery $selectedRecovery
        
        Write-Log "Recovery image flashed successfully" "Success"
        return $true
    }
    catch {
        Write-Log "Error flashing recovery: $_" "Error"
        return $false
    }
}

# ============================================================================
# ROM FLASHING
# ============================================================================

function Flash-ROM {
    <#
    .SYNOPSIS
    Flash custom ROM via recovery
    #>
    Write-Log "Starting ROM flashing procedure..." "Info"
    
    $adbPath = Join-Path $Paths.ADB "adb.exe"
    
    # Get ROM package path
    Write-Host ""
    Write-Host "Select ROM package to flash:" -ForegroundColor $Colors.Prompt
    
    $romPackages = Get-ChildItem -Path $Paths.ROM -Filter "*.zip" | Select-Object -ExpandProperty FullName
    
    if (-not $romPackages) {
        Write-Log "No ROM packages found in $($Paths.ROM)" "Warning"
        Write-Log "Please place ROM package (.zip) in the ROM directory" "Info"
        return $false
    }
    
    if ($romPackages -is [string]) {
        $selectedROM = $romPackages
    }
    else {
        $selection = Show-Menu -Options $romPackages -Title "ROM Packages"
        $selectedROM = $romPackages[$selection]
    }
    
    try {
        # Copy ROM to device
        Write-Log "Pushing ROM to device storage..." "Info"
        & $adbPath push $selectedROM /data/media/0/
        
        Write-Log "ROM pushed to device" "Success"
        Write-Log "Please boot into recovery and flash the ROM from there" "Info"
        Write-Log "ROM location on device: /data/media/0/$(Split-Path -Leaf $selectedROM)" "Info"
        
        return $true
    }
    catch {
        Write-Log "Error flashing ROM: $_" "Error"
        return $false
    }
}

# ============================================================================
# SYSTEM VERIFICATION AND DIAGNOSTICS
# ============================================================================

function Check-SystemRequirements {
    <#
    .SYNOPSIS
    Verify system meets requirements
    #>
    Write-Log "Checking system requirements..." "Info"
    
    $requirements = @{
        "Windows 11" = [System.Environment]::OSVersion.Version.Major -eq 10 -and [System.Environment]::OSVersion.Version.Build -ge 22000
        "Administrator Privileges" = Test-AdminPrivileges
        "PowerShell 5.1+" = $PSVersionTable.PSVersion.Major -ge 5
    }
    
    $allMet = $true
    
    foreach ($req in $requirements.GetEnumerator()) {
        if ($req.Value) {
            Write-Log "$($req.Key): ✓ OK" "Success"
        }
        else {
            Write-Log "$($req.Key): ✗ FAILED" "Error"
            $allMet = $false
        }
    }
    
    return $allMet
}

function Show-DeviceDiagnostics {
    <#
    .SYNOPSIS
    Display device information and diagnostics
    #>
    Write-Log "Running device diagnostics..." "Info"
    
    $adbPath = Join-Path $Paths.ADB "adb.exe"
    
    if (-not (Test-Path $adbPath)) {
        Write-Log "ADB not available for diagnostics" "Warning"
        return
    }
    
    try {
        Write-Host ""
        Write-Host "Device Information:" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────────" -ForegroundColor Cyan
        
        $deviceInfo = @(
            @{ name = "Model"; cmd = "getprop ro.product.model" }
            @{ name = "Manufacturer"; cmd = "getprop ro.product.manufacturer" }
            @{ name = "Android Version"; cmd = "getprop ro.build.version.release" }
            @{ name = "Build Number"; cmd = "getprop ro.build.display.id" }
            @{ name = "Serial Number"; cmd = "getprop ro.serialno" }
        )
        
        foreach ($info in $deviceInfo) {
            $value = & $adbPath shell $info.cmd 2>$null
            if ($value) {
                Write-Host "$($info.name): $value" -ForegroundColor White
            }
        }
        
        Write-Host ""
    }
    catch {
        Write-Log "Error retrieving device diagnostics: $_" "Warning"
    }
}

# ============================================================================
# INTERACTIVE WIZARD WORKFLOW
# ============================================================================

function Show-MainMenu {
    <#
    .SYNOPSIS
    Display and handle main menu interactions
    #>
    do {
        Write-Host ""
        Write-Host "╔─ INSTALLATION WIZARD MENU" -ForegroundColor Cyan
        Write-Host "│  1. Setup ADB/Fastboot" -ForegroundColor White
        Write-Host "│  2. Install USB Drivers" -ForegroundColor White
        Write-Host "│  3. Verify Device Connection" -ForegroundColor White
        Write-Host "│  4. Display Device Diagnostics" -ForegroundColor White
        Write-Host "│  5. Unlock Bootloader" -ForegroundColor White
        Write-Host "│  6. Flash Recovery" -ForegroundColor White
        Write-Host "│  7. Flash ROM" -ForegroundColor White
        Write-Host "│  8. Full Installation (All Steps)" -ForegroundColor White
        Write-Host "│  9. View Logs" -ForegroundColor White
        Write-Host "│  0. Exit" -ForegroundColor White
        Write-Host "└─" -ForegroundColor Cyan
        
        [int]$choice = Read-Host "Enter your choice (0-9)"
        
        switch ($choice) {
            1 {
                if (Install-ADBFastboot) {
                    Add-ADBToPath
                    Write-Log "ADB/Fastboot setup completed" "Success"
                }
            }
            2 {
                Install-USBDrivers | Out-Null
            }
            3 {
                if (Verify-DeviceConnection) {
                    Show-DeviceDiagnostics
                }
                else {
                    $retry = Read-Host "Retry connection? (Y/n)"
                    if ($retry -ne "n") {
                        Wait-ForDevice | Out-Null
                    }
                }
            }
            4 {
                Show-DeviceDiagnostics
            }
            5 {
                Write-Log "Please reboot device to Fastboot mode first" "Info"
                Read-Host "Press Enter when device is in Fastboot mode"
                Unlock-Bootloader | Out-Null
            }
            6 {
                Flash-Recovery | Out-Null
            }
            7 {
                Flash-ROM | Out-Null
            }
            8 {
                Run-FullInstallation
            }
            9 {
                Show-Logs
            }
            0 {
                Write-Log "Installation wizard exiting" "Info"
                Write-Host ""
                Write-Host "Thank you for using Realme C63 Installation Wizard!" -ForegroundColor Green
                Write-Host "For more information, visit the documentation." -ForegroundColor Cyan
                exit 0
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor $Colors.Warning
            }
        }
        
        if ($choice -ne 0) {
            Read-Host "Press Enter to continue..."
        }
        
    } while ($true)
}

function Run-FullInstallation {
    <#
    .SYNOPSIS
    Execute complete installation workflow
    #>
    Write-Log "Starting full installation procedure..." "Info"
    
    $steps = @(
        @{ name = "ADB/Fastboot Setup"; action = { Install-ADBFastboot; Add-ADBToPath } }
        @{ name = "USB Driver Installation"; action = { Install-USBDrivers } }
        @{ name = "Device Connection Verification"; action = { Verify-DeviceConnection } }
    )
    
    foreach ($step in $steps) {
        Write-Host ""
        Write-Host "► $($step.name)" -ForegroundColor $Colors.Prompt
        
        if (& $step.action) {
            Write-Log "$($step.name) completed successfully" "Success"
        }
        else {
            Write-Log "$($step.name) encountered issues" "Warning"
            $continue = Read-Host "Continue anyway? (Y/n)"
            if ($continue -eq "n") {
                Write-Log "Full installation cancelled" "Info"
                return $false
            }
        }
    }
    
    Write-Log "Full installation completed" "Success"
    return $true
}

function Show-Logs {
    <#
    .SYNOPSIS
    Display installation logs
    #>
    Write-Host ""
    Write-Host "╔─ RECENT LOG ENTRIES" -ForegroundColor Cyan
    
    if (Test-Path $LogFile) {
        $logContent = Get-Content -Path $LogFile -Tail 30
        Write-Host $logContent -ForegroundColor White
    }
    else {
        Write-Host "No log file found" -ForegroundColor $Colors.Warning
    }
    
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host "Full log file: $LogFile" -ForegroundColor Cyan
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    <#
    .SYNOPSIS
    Main entry point for the installation wizard
    #>
    try {
        # Verify administrator privileges
        if (-not (Test-AdminPrivileges)) {
            Write-Host "ERROR: This script requires administrator privileges!" -ForegroundColor $Colors.Error
            Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor $Colors.Error
            exit 1
        }
        
        # Show banner
        Show-Banner
        
        # Check system requirements
        if (-not (Check-SystemRequirements)) {
            Write-Log "System requirements not met. Please resolve issues and try again." "Error"
            exit 1
        }
        
        Write-Log "System requirements verified" "Success"
        
        # Create directory structure
        New-DirectoryStructure
        
        # Start interactive wizard
        Show-MainMenu
    }
    catch {
        Write-Log "Fatal error: $_" "Error"
        Write-Log $_.ScriptStackTrace "Error"
        exit 1
    }
}

# Run main function
Main
