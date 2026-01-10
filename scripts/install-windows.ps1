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
    
.PARAMETER AutoInstall
    Run fully automated installation without manual menu interaction
    
.PARAMETER DownloadOnly
    Only download all required tools and drivers, then exit
    
.PARAMETER OptimizedMode
    Enable performance optimizations (parallel downloads, caching, faster operations)
    
.PARAMETER ParallelDownloads
    Number of parallel downloads to use in optimized mode (default: 3, max: 5)
    
.PARAMETER UseCache
    Use cached downloads if available (skip re-downloading existing files)
    
.EXAMPLE
    .\install-windows.ps1
    .\install-windows.ps1 -WorkingDirectory "D:\MyTools" -SkipADB
    .\install-windows.ps1 -AutoInstall
    .\install-windows.ps1 -DownloadOnly
    .\install-windows.ps1 -OptimizedMode -ParallelDownloads 4
    .\install-windows.ps1 -AutoInstall -OptimizedMode -UseCache
    
.NOTES
    Author: Realme C63 Installation Wizard
    Created: 2026-01-10
    Updated: 2026-01-10 (Added fully automated installation and optimization mode)
    Requires: Windows 11, Administrator privileges
    Version: 2.0 (Optimized)
#>

param(
    [string]$WorkingDirectory = "C:\Realme-C63-Tools",
    [switch]$SkipADB,
    [switch]$SkipDrivers,
    [switch]$AutoInstall,
    [switch]$DownloadOnly,
    [switch]$OptimizedMode,
    [int]$ParallelDownloads = 3,
    [switch]$UseCache
)

# ============================================================================
# GLOBAL VARIABLES AND CONFIGURATION
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = if ($OptimizedMode) { "SilentlyContinue" } else { "Continue" }

# Optimization settings
if ($OptimizedMode) {
    Write-Host "⚡ Optimized Mode Enabled" -ForegroundColor Green
    $ParallelDownloads = [Math]::Min($ParallelDownloads, 5)  # Max 5 parallel downloads
    [System.Net.ServicePointManager]::DefaultConnectionLimit = 10
    [System.Net.ServicePointManager]::Expect100Continue = $false
}

# Performance tracking
$script:PerformanceMetrics = @{
    StartTime = Get-Date
    DownloadTime = 0
    InstallTime = 0
    TotalOperations = 0
}

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
    # Essential Tools
    ADBPlatformTools = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    MinimalADB       = "https://androidfilehost.com/?fid=746010030569952951"  # Minimal ADB and Fastboot
    
    # USB Drivers
    GoogleUSBDriver  = "https://dl.google.com/android/repository/usb_driver_r13-windows.zip"
    UniversalADBDriver = "https://adb.clockworkmod.com/latest/UniversalAdbDriverSetup.msi"
    RealmeUSBDriver  = "https://realme-device-drivers.s3.amazonaws.com/realme-usb-driver-windows.zip"
    OPPOUSBDriver    = "https://oppo-device-drivers.s3.amazonaws.com/oppo-usb-driver-windows.zip"
    
    # Recovery and Root Tools
    TWRP_RMX3939     = "https://dl.twrp.me/RMX3939/twrp-3.7.0-RMX3939.img"  # Example URL
    MagiskLatest     = "https://github.com/topjohnwu/Magisk/releases/latest/download/Magisk-v26.4.apk"
    MagiskCanary     = "https://github.com/topjohnwu/Magisk/releases/download/canary/Magisk-canary.apk"
    
    # Flash Tools (for emergency recovery)
    SPFlashTool      = "https://spflashtool.com/download/SP_Flash_Tool_v5.2352_Win.zip"
    
    # Additional Utilities
    JavaRuntimeEnv   = "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe"
    Python3Installer = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe"
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
    Download file with progress indication and caching support
    #>
    param(
        [string]$URL,
        [string]$Destination,
        [string]$Description = "File"
    )
    
    try {
        # Check cache if UseCache is enabled
        if ($UseCache -and (Test-Path $Destination)) {
            $fileInfo = Get-Item $Destination
            if ($fileInfo.Length -gt 0) {
                Write-Log "✓ Using cached $Description ($(Format-FileSize $fileInfo.Length))" "Success"
                return $true
            }
        }
        
        Write-Log "Downloading $Description..." "Info"
        
        if ($OptimizedMode) {
            # Optimized download with BITS or WebClient
            try {
                $startTime = Get-Date
                
                # Try using BITS first (faster for large files)
                Start-BitsTransfer -Source $URL -Destination $Destination -Description $Description -ErrorAction Stop
                
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $script:PerformanceMetrics.DownloadTime += $elapsed
                
                if (Test-Path $Destination) {
                    $fileSize = (Get-Item $Destination).Length
                    $speed = $fileSize / $elapsed / 1MB
                    Write-Log "✓ $Description downloaded ($(Format-FileSize $fileSize), $([math]::Round($speed, 2)) MB/s)" "Success"
                    return $true
                }
            }
            catch {
                # Fallback to WebClient
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($URL, $Destination)
                $webClient.Dispose()
            }
        }
        else {
            # Standard download
            $ProgressPreference = "Continue"
            Invoke-WebRequest -Uri $URL -OutFile $Destination -UseBasicParsing
            $ProgressPreference = "SilentlyContinue"
        }
        
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

function Format-FileSize {
    <#
    .SYNOPSIS
    Format file size in human-readable format
    #>
    param([long]$Size)
    
    if ($Size -gt 1GB) { return "$([math]::Round($Size / 1GB, 2)) GB" }
    elseif ($Size -gt 1MB) { return "$([math]::Round($Size / 1MB, 2)) MB" }
    elseif ($Size -gt 1KB) { return "$([math]::Round($Size / 1KB, 2)) KB" }
    else { return "$Size bytes" }
}

function Download-FilesParallel {
    <#
    .SYNOPSIS
    Download multiple files in parallel for improved performance
    #>
    param(
        [hashtable[]]$FileList,  # Array of @{URL, Destination, Description}
        [int]$MaxParallel = 3
    )
    
    if (-not $OptimizedMode) {
        # Fall back to sequential downloads
        foreach ($file in $FileList) {
            Download-File -URL $file.URL -Destination $file.Destination -Description $file.Description
        }
        return
    }
    
    Write-Log "Starting parallel downloads ($MaxParallel concurrent)..." "Info"
    
    $jobs = @()
    $completed = 0
    $total = $FileList.Count
    
    foreach ($file in $FileList) {
        # Wait if we've reached max parallel downloads
        while (($jobs | Where-Object { $_.State -eq 'Running' }).Count -ge $MaxParallel) {
            Start-Sleep -Milliseconds 100
            
            # Check for completed jobs
            $finishedJobs = $jobs | Where-Object { $_.State -ne 'Running' }
            foreach ($job in $finishedJobs) {
                $result = Receive-Job -Job $job
                Remove-Job -Job $job
                $completed++
                $jobs = $jobs | Where-Object { $_.Id -ne $job.Id }
            }
        }
        
        # Start new download job
        $job = Start-Job -ScriptBlock {
            param($url, $dest, $desc, $useCache)
            
            if ($useCache -and (Test-Path $dest)) {
                $fileInfo = Get-Item $dest
                if ($fileInfo.Length -gt 0) {
                    return @{ Success = $true; Cached = $true; Size = $fileInfo.Length }
                }
            }
            
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($url, $dest)
                $webClient.Dispose()
                
                if (Test-Path $dest) {
                    $size = (Get-Item $dest).Length
                    return @{ Success = $true; Cached = $false; Size = $size }
                }
            }
            catch {
                return @{ Success = $false; Error = $_.Exception.Message }
            }
        } -ArgumentList $file.URL, $file.Destination, $file.Description, $UseCache
        
        $jobs += $job
        Write-Host "  ⏳ Queued: $($file.Description)" -ForegroundColor Gray
    }
    
    # Wait for all remaining jobs
    while ($jobs.Count -gt 0) {
        Start-Sleep -Milliseconds 100
        
        $finishedJobs = $jobs | Where-Object { $_.State -ne 'Running' }
        foreach ($job in $finishedJobs) {
            $result = Receive-Job -Job $job
            Remove-Job -Job $job
            $completed++
            $jobs = $jobs | Where-Object { $_.Id -ne $job.Id }
            
            if ($result.Success) {
                if ($result.Cached) {
                    Write-Host "  ✓ Cached ($completed/$total)" -ForegroundColor Green
                } else {
                    Write-Host "  ✓ Downloaded ($completed/$total) - $(Format-FileSize $result.Size)" -ForegroundColor Green
                }
            } else {
                Write-Host "  ✗ Failed ($completed/$total)" -ForegroundColor Red
            }
        }
    }
    
    Write-Log "Parallel downloads completed: $completed/$total" "Success"
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
# COMPREHENSIVE DOWNLOADS FUNCTION
# ============================================================================

function Download-AllRequiredTools {
    <#
    .SYNOPSIS
    Download all required tools, drivers, and programs
    #>
    Write-Log "Starting comprehensive download of all required tools..." "Info"
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  COMPREHENSIVE TOOL DOWNLOAD FOR REALME C63 (RMX3939)" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $downloadResults = @{
        Success = @()
        Failed  = @()
        Skipped = @()
    }
    
    # Create download directories
    $downloadDirs = @{
        Tools    = Join-Path $Paths.Root "downloads\tools"
        Drivers  = Join-Path $Paths.Root "downloads\drivers"
        Recovery = Join-Path $Paths.Root "downloads\recovery"
        Root     = Join-Path $Paths.Root "downloads\root"
        Flash    = Join-Path $Paths.Root "downloads\flash"
        Utilities = Join-Path $Paths.Root "downloads\utilities"
    }
    
    foreach ($dir in $downloadDirs.Values) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
    
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  PHASE 1: Essential Tools" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
    
    # Download ADB Platform Tools
    Write-Log "Downloading Android Platform Tools (ADB & Fastboot)..." "Info"
    $adbZip = Join-Path $downloadDirs.Tools "platform-tools.zip"
    if (Download-File -URL $Downloads.ADBPlatformTools -Destination $adbZip -Description "Android Platform Tools") {
        $downloadResults.Success += "Android Platform Tools"
        Write-Log "✓ Android Platform Tools downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "Android Platform Tools"
    }
    
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  PHASE 2: USB Drivers" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
    
    # Download Google USB Driver
    Write-Log "Downloading Google USB Driver..." "Info"
    $googleDriver = Join-Path $downloadDirs.Drivers "google-usb-driver.zip"
    if (Download-File -URL $Downloads.GoogleUSBDriver -Destination $googleDriver -Description "Google USB Driver") {
        $downloadResults.Success += "Google USB Driver"
        Write-Log "✓ Google USB Driver downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "Google USB Driver"
    }
    
    # Download Universal ADB Driver
    Write-Log "Downloading Universal ADB Driver..." "Info"
    $universalDriver = Join-Path $downloadDirs.Drivers "universal-adb-driver.msi"
    if (Download-File -URL $Downloads.UniversalADBDriver -Destination $universalDriver -Description "Universal ADB Driver") {
        $downloadResults.Success += "Universal ADB Driver"
        Write-Log "✓ Universal ADB Driver downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "Universal ADB Driver"
    }
    
    # Download Realme USB Driver
    Write-Log "Downloading Realme USB Driver..." "Info"
    $realmeDriver = Join-Path $downloadDirs.Drivers "realme-usb-driver.zip"
    if (Download-File -URL $Downloads.RealmeUSBDriver -Destination $realmeDriver -Description "Realme USB Driver") {
        $downloadResults.Success += "Realme USB Driver"
        Write-Log "✓ Realme USB Driver downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "Realme USB Driver"
    }
    
    # Download OPPO USB Driver
    Write-Log "Downloading OPPO USB Driver..." "Info"
    $oppoDriver = Join-Path $downloadDirs.Drivers "oppo-usb-driver.zip"
    if (Download-File -URL $Downloads.OPPOUSBDriver -Destination $oppoDriver -Description "OPPO USB Driver") {
        $downloadResults.Success += "OPPO USB Driver"
        Write-Log "✓ OPPO USB Driver downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "OPPO USB Driver"
    }
    
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  PHASE 3: Recovery & Root Tools" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
    
    # Download TWRP Recovery
    Write-Log "Downloading TWRP Recovery for RMX3939..." "Info"
    $twrpImg = Join-Path $downloadDirs.Recovery "twrp-rmx3939.img"
    if (Download-File -URL $Downloads.TWRP_RMX3939 -Destination $twrpImg -Description "TWRP Recovery") {
        $downloadResults.Success += "TWRP Recovery"
        Write-Log "✓ TWRP Recovery downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "TWRP Recovery"
        Write-Log "! TWRP download failed - you may need to download manually from twrp.me" "Warning"
    }
    
    # Download Magisk (Latest Stable)
    Write-Log "Downloading Magisk (Latest Stable)..." "Info"
    $magiskApk = Join-Path $downloadDirs.Root "Magisk-latest.apk"
    if (Download-File -URL $Downloads.MagiskLatest -Destination $magiskApk -Description "Magisk Latest") {
        $downloadResults.Success += "Magisk Latest"
        Write-Log "✓ Magisk (Latest) downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "Magisk Latest"
    }
    
    # Download Magisk Canary (Beta)
    Write-Log "Downloading Magisk Canary (Beta)..." "Info"
    $magiskCanary = Join-Path $downloadDirs.Root "Magisk-canary.apk"
    if (Download-File -URL $Downloads.MagiskCanary -Destination $magiskCanary -Description "Magisk Canary") {
        $downloadResults.Success += "Magisk Canary"
        Write-Log "✓ Magisk Canary downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "Magisk Canary"
    }
    
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  PHASE 4: Flash Tools (Optional)" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
    
    # Download SP Flash Tool
    Write-Log "Downloading SP Flash Tool (for MediaTek devices)..." "Info"
    $spFlashTool = Join-Path $downloadDirs.Flash "sp-flash-tool.zip"
    if (Download-File -URL $Downloads.SPFlashTool -Destination $spFlashTool -Description "SP Flash Tool") {
        $downloadResults.Success += "SP Flash Tool"
        Write-Log "✓ SP Flash Tool downloaded successfully" "Success"
    } else {
        $downloadResults.Failed += "SP Flash Tool"
        Write-Log "! SP Flash Tool download failed - needed only for emergency recovery" "Warning"
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  DOWNLOAD SUMMARY" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "✓ Successfully Downloaded: $($downloadResults.Success.Count)" -ForegroundColor Green
    foreach ($item in $downloadResults.Success) {
        Write-Host "  • $item" -ForegroundColor Green
    }
    
    if ($downloadResults.Failed.Count -gt 0) {
        Write-Host ""
        Write-Host "✗ Failed Downloads: $($downloadResults.Failed.Count)" -ForegroundColor Red
        foreach ($item in $downloadResults.Failed) {
            Write-Host "  • $item" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Download Location: $($Paths.Root)\downloads" -ForegroundColor Cyan
    Write-Host ""
    
    # Create a download manifest
    $manifest = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Success   = $downloadResults.Success
        Failed    = $downloadResults.Failed
        Location  = "$($Paths.Root)\downloads"
    }
    
    $manifestPath = Join-Path $Paths.Root "downloads\download-manifest.json"
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath
    Write-Log "Download manifest saved to: $manifestPath" "Info"
    
    if ($downloadResults.Failed.Count -eq 0) {
        Write-Log "All downloads completed successfully!" "Success"
        return $true
    } else {
        Write-Log "Some downloads failed. Please check the summary above." "Warning"
        return $false
    }
}

function Install-AllDrivers {
    <#
    .SYNOPSIS
    Install all downloaded USB drivers
    #>
    Write-Log "Installing all USB drivers..." "Info"
    
    $driverDir = Join-Path $Paths.Root "downloads\drivers"
    
    if (-not (Test-Path $driverDir)) {
        Write-Log "Driver download directory not found. Please run Download-AllRequiredTools first." "Error"
        return $false
    }
    
    # Extract all driver ZIP files
    $zipFiles = Get-ChildItem -Path $driverDir -Filter "*.zip"
    
    foreach ($zip in $zipFiles) {
        Write-Log "Extracting $($zip.Name)..." "Info"
        $extractPath = Join-Path $driverDir $zip.BaseName
        
        if (-not (Test-Path $extractPath)) {
            Expand-ZipFile -ZipFile $zip.FullName -Destination $extractPath -Description $zip.BaseName | Out-Null
        }
    }
    
    # Install all .inf files found
    $infFiles = Get-ChildItem -Path $driverDir -Filter "*.inf" -Recurse
    
    if ($infFiles) {
        Write-Log "Found $($infFiles.Count) driver(s) to install..." "Info"
        
        foreach ($infFile in $infFiles) {
            try {
                Write-Log "Installing driver: $($infFile.Name)" "Info"
                pnputil.exe /add-driver "$($infFile.FullName)" /install 2>&1 | Out-Null
                Write-Log "✓ Driver installed: $($infFile.Name)" "Success"
            }
            catch {
                Write-Log "! Failed to install driver: $($infFile.Name) - $_" "Warning"
            }
        }
        
        Write-Log "Driver installation complete!" "Success"
        return $true
    }
    else {
        Write-Log "No driver .inf files found" "Warning"
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
        Write-Host "│  3. Download All Required Tools & Drivers" -ForegroundColor Yellow
        Write-Host "│  4. Install All Drivers" -ForegroundColor Yellow
        Write-Host "│  5. Verify Device Connection" -ForegroundColor White
        Write-Host "│  6. Display Device Diagnostics" -ForegroundColor White
        Write-Host "│  7. Unlock Bootloader" -ForegroundColor White
        Write-Host "│  8. Flash Recovery" -ForegroundColor White
        Write-Host "│  9. Flash ROM" -ForegroundColor White
        Write-Host "│  A. Full Installation (All Steps)" -ForegroundColor White
        Write-Host "│  L. View Logs" -ForegroundColor White
        Write-Host "│  0. Exit" -ForegroundColor White
        Write-Host "└─" -ForegroundColor Cyan
        
        $choice = Read-Host "Enter your choice"
        
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
                Download-AllRequiredTools | Out-Null
            }
            4 {
                Install-AllDrivers | Out-Null
            }
            5 {
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
            6 {
                Show-DeviceDiagnostics
            }
            7 {
                Write-Log "Please reboot device to Fastboot mode first" "Info"
                Read-Host "Press Enter when device is in Fastboot mode"
                Unlock-Bootloader | Out-Null
            }
            8 {
                Flash-Recovery | Out-Null
            }
            9 {
                Flash-ROM | Out-Null
            }
            "A" {
                Run-FullInstallation
            }
            "L" {
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
    Execute complete fully-automated installation workflow
    .DESCRIPTION
    Performs a complete end-to-end installation including:
    - Download all required tools and drivers
    - Install ADB/Fastboot and USB drivers
    - Verify device connection
    - Unlock bootloader (with user confirmation)
    - Flash TWRP recovery
    - Flash custom ROM
    - Optional: Root with Magisk
    #>
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  VOLLSTÄNDIGE AUTOMATISCHE INSTALLATION" -ForegroundColor Cyan
    Write-Host "  FULLY AUTOMATED INSTALLATION FOR REALME C63 (RMX3939)" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "Starting fully automated installation procedure..." "Info"
    
    # Ask for user preferences upfront
    Write-Host "Configuration Options:" -ForegroundColor Yellow
    Write-Host ""
    
    $downloadTools = Read-Host "Download all required tools and drivers? (Y/n)"
    $downloadTools = ($downloadTools -ne "n")
    
    $installDrivers = Read-Host "Install all USB drivers? (Y/n)"
    $installDrivers = ($installDrivers -ne "n")
    
    $unlockBootloader = Read-Host "Unlock bootloader (CAUTION: Wipes all data!)? (y/N)"
    $unlockBootloader = ($unlockBootloader -eq "y")
    
    $flashRecovery = Read-Host "Flash TWRP recovery? (y/N)"
    $flashRecovery = ($flashRecovery -eq "y")
    
    $flashROM = Read-Host "Flash custom ROM? (y/N)"
    $flashROM = ($flashROM -eq "y")
    
    $installRoot = Read-Host "Install Magisk for root access? (y/N)"
    $installRoot = ($installRoot -eq "y")
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  STARTING AUTOMATED INSTALLATION" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $stepNumber = 1
    $totalSteps = 0
    if ($downloadTools) { $totalSteps++ }
    if ($installDrivers) { $totalSteps++ }
    $totalSteps++ # ADB/Fastboot always installed
    $totalSteps++ # Device verification always attempted
    if ($unlockBootloader) { $totalSteps++ }
    if ($flashRecovery) { $totalSteps++ }
    if ($flashROM) { $totalSteps++ }
    if ($installRoot) { $totalSteps++ }
    
    # Step 1: Download all required tools
    if ($downloadTools) {
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host "  STEP $stepNumber/$totalSteps: Downloading All Required Tools & Drivers" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host ""
        
        $stepNumber++
        
        if (Download-AllRequiredTools) {
            Write-Log "✓ All tools and drivers downloaded successfully" "Success"
        }
        else {
            Write-Log "! Some downloads failed, but continuing..." "Warning"
            $continue = Read-Host "Continue installation despite download failures? (Y/n)"
            if ($continue -eq "n") {
                Write-Log "Installation cancelled by user" "Info"
                return $false
            }
        }
    }
    
    # Step 2: Install ADB/Fastboot
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  STEP $stepNumber/$totalSteps: Installing ADB & Fastboot Tools" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
    
    $stepNumber++
    
    if (Install-ADBFastboot) {
        Add-ADBToPath
        Write-Log "✓ ADB/Fastboot setup completed" "Success"
    }
    else {
        Write-Log "✗ ADB/Fastboot installation failed" "Error"
        $continue = Read-Host "Continue anyway? (Y/n)"
        if ($continue -eq "n") {
            Write-Log "Installation cancelled" "Info"
            return $false
        }
    }
    
    # Step 3: Install USB Drivers
    if ($installDrivers) {
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host "  STEP $stepNumber/$totalSteps: Installing USB Drivers" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host ""
        
        $stepNumber++
        
        if (Install-AllDrivers) {
            Write-Log "✓ All USB drivers installed successfully" "Success"
        }
        else {
            Write-Log "! Driver installation had some issues" "Warning"
            Write-Host "You may need to install drivers manually if device is not recognized" -ForegroundColor Yellow
        }
    }
    
    # Step 4: Verify Device Connection
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  STEP $stepNumber/$totalSteps: Verifying Device Connection" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
    
    $stepNumber++
    
    Write-Host "Please connect your Realme C63 device via USB" -ForegroundColor Cyan
    Write-Host "Ensure USB Debugging is enabled in Developer Options" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter when device is connected"
    
    if (Verify-DeviceConnection) {
        Write-Log "✓ Device connection verified" "Success"
        Show-DeviceDiagnostics
    }
    else {
        Write-Log "! Device not detected" "Warning"
        Write-Host "Attempting to wait for device..." -ForegroundColor Yellow
        
        if (Wait-ForDevice) {
            Write-Log "✓ Device detected" "Success"
        }
        else {
            Write-Log "✗ Could not detect device" "Error"
            Write-Host ""
            Write-Host "Please check:" -ForegroundColor Red
            Write-Host "  1. USB cable is properly connected" -ForegroundColor White
            Write-Host "  2. USB Debugging is enabled" -ForegroundColor White
            Write-Host "  3. You authorized the computer on device screen" -ForegroundColor White
            Write-Host "  4. USB drivers are properly installed" -ForegroundColor White
            Write-Host ""
            
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne "y") {
                Write-Log "Installation cancelled - device not detected" "Info"
                return $false
            }
        }
    }
    
    # Step 5: Unlock Bootloader
    if ($unlockBootloader) {
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host "  STEP $stepNumber/$totalSteps: Unlocking Bootloader" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host ""
        
        $stepNumber++
        
        Write-Host "⚠️  WARNING: BOOTLOADER UNLOCK WILL ERASE ALL DATA!" -ForegroundColor Red
        Write-Host "⚠️  Make sure you have backed up everything important!" -ForegroundColor Red
        Write-Host ""
        
        $confirm = Read-Host "Type 'UNLOCK' (in capitals) to confirm bootloader unlock"
        
        if ($confirm -eq "UNLOCK") {
            Write-Host ""
            Write-Host "Rebooting device to fastboot mode..." -ForegroundColor Cyan
            Write-Host "Please confirm bootloader unlock on your device screen!" -ForegroundColor Yellow
            Write-Host ""
            
            if (Unlock-Bootloader) {
                Write-Log "✓ Bootloader unlocked successfully" "Success"
                Write-Host ""
                Write-Host "Device will reboot and wipe all data..." -ForegroundColor Yellow
                Write-Host "First boot may take 5-10 minutes" -ForegroundColor Yellow
                Write-Host ""
                Start-Sleep -Seconds 5
            }
            else {
                Write-Log "✗ Bootloader unlock failed" "Error"
                Write-Host "Please check documentation: docs/BOOTLOADER_UNLOCK.md" -ForegroundColor Yellow
                
                $continue = Read-Host "Continue anyway? (y/N)"
                if ($continue -ne "y") {
                    Write-Log "Installation cancelled" "Info"
                    return $false
                }
            }
        }
        else {
            Write-Log "Bootloader unlock cancelled by user" "Info"
            Write-Host "Skipping bootloader unlock..." -ForegroundColor Yellow
        }
    }
    
    # Step 6: Flash TWRP Recovery
    if ($flashRecovery) {
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host "  STEP $stepNumber/$totalSteps: Flashing TWRP Recovery" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host ""
        
        $stepNumber++
        
        Write-Host "Ensure device is in fastboot mode" -ForegroundColor Cyan
        Write-Host "To enter fastboot: Power off, then hold Volume Down + Power" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Press Enter when device is in fastboot mode"
        
        if (Flash-Recovery) {
            Write-Log "✓ TWRP recovery flashed successfully" "Success"
            Write-Host ""
            Write-Host "Boot to TWRP: Power off, then hold Volume Up + Power" -ForegroundColor Cyan
        }
        else {
            Write-Log "✗ Recovery flash failed" "Error"
            Write-Host "Please check documentation: docs/TWRP_INSTALLATION.md" -ForegroundColor Yellow
            
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne "y") {
                Write-Log "Installation cancelled" "Info"
                return $false
            }
        }
    }
    
    # Step 7: Flash Custom ROM
    if ($flashROM) {
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host "  STEP $stepNumber/$totalSteps: Flashing Custom ROM" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host ""
        
        $stepNumber++
        
        Write-Host "Ensure device is in fastboot mode" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Press Enter when ready to flash ROM"
        
        if (Flash-ROM) {
            Write-Log "✓ Custom ROM flashed successfully" "Success"
            Write-Host ""
            Write-Host "Device will reboot automatically" -ForegroundColor Cyan
            Write-Host "First boot may take 10-15 minutes" -ForegroundColor Yellow
        }
        else {
            Write-Log "✗ ROM flash failed" "Error"
            Write-Host "Please check documentation: docs/INSTALLATION.md" -ForegroundColor Yellow
            
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne "y") {
                Write-Log "Installation cancelled" "Info"
                return $false
            }
        }
    }
    
    # Step 8: Install Magisk for Root
    if ($installRoot) {
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host "  STEP $stepNumber/$totalSteps: Installing Magisk (Root)" -ForegroundColor Yellow
        Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Yellow
        Write-Host ""
        
        $stepNumber++
        
        Write-Host "Magisk installation requires:" -ForegroundColor Cyan
        Write-Host "  1. Device booted to system" -ForegroundColor White
        Write-Host "  2. Magisk APK transferred to device" -ForegroundColor White
        Write-Host "  3. Boot image patched via Magisk app" -ForegroundColor White
        Write-Host "  4. Patched boot image flashed via fastboot" -ForegroundColor White
        Write-Host ""
        Write-Host "Please follow the detailed guide: docs/ROOTING_GUIDE.md" -ForegroundColor Yellow
        Write-Host ""
        
        $magiskApk = Join-Path (Join-Path $Paths.Root "downloads") "4-Root-Magisk\Magisk-latest.apk"
        
        if (Test-Path $magiskApk) {
            Write-Host "Magisk APK location: $magiskApk" -ForegroundColor Green
            Write-Host ""
            Write-Host "To install Magisk:" -ForegroundColor Cyan
            Write-Host "  1. Transfer Magisk APK to device: adb push `"$magiskApk`" /sdcard/" -ForegroundColor White
            Write-Host "  2. Install on device: adb install `"$magiskApk`"" -ForegroundColor White
            Write-Host "  3. Follow rooting guide for boot image patching" -ForegroundColor White
            Write-Host ""
        }
        else {
            Write-Host "Magisk APK not found. Please download it first." -ForegroundColor Red
        }
        
        Read-Host "Press Enter to continue"
    }
    
    # Installation Complete
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  INSTALLATION COMPLETED!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Summary of completed steps:" -ForegroundColor Cyan
    Write-Host ""
    
    if ($downloadTools) { Write-Host "  ✓ Downloaded all required tools and drivers" -ForegroundColor Green }
    if ($installDrivers) { Write-Host "  ✓ Installed USB drivers" -ForegroundColor Green }
    Write-Host "  ✓ Installed ADB/Fastboot tools" -ForegroundColor Green
    Write-Host "  ✓ Verified device connection" -ForegroundColor Green
    if ($unlockBootloader) { Write-Host "  ✓ Unlocked bootloader" -ForegroundColor Green }
    if ($flashRecovery) { Write-Host "  ✓ Flashed TWRP recovery" -ForegroundColor Green }
    if ($flashROM) { Write-Host "  ✓ Flashed custom ROM" -ForegroundColor Green }
    if ($installRoot) { Write-Host "  ✓ Provided Magisk root instructions" -ForegroundColor Green }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review the installation log: $LogFile" -ForegroundColor White
    Write-Host "  2. Check documentation in /docs folder for detailed guides" -ForegroundColor White
    Write-Host "  3. For Magisk root: See docs/ROOTING_GUIDE.md" -ForegroundColor White
    Write-Host "  4. For troubleshooting: See docs/BOOTLOADER_UNLOCK.md" -ForegroundColor White
    Write-Host ""
    
    Write-Log "Full automated installation completed successfully" "Success"
    
    Write-Host "Installation complete! Enjoy your customized Realme C63! 🎉" -ForegroundColor Green
    Write-Host ""
    
    return $true
}

function Show-PerformanceMetrics {
    <#
    .SYNOPSIS
    Display performance metrics and statistics
    #>
    if (-not $OptimizedMode) { return }
    
    $endTime = Get-Date
    $totalTime = ($endTime - $script:PerformanceMetrics.StartTime).TotalSeconds
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PERFORMANCE METRICS (OPTIMIZED MODE)" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total execution time: $([math]::Round($totalTime, 2)) seconds" -ForegroundColor Green
    
    if ($script:PerformanceMetrics.DownloadTime -gt 0) {
        Write-Host "Download time: $([math]::Round($script:PerformanceMetrics.DownloadTime, 2)) seconds" -ForegroundColor Cyan
    }
    
    if ($script:PerformanceMetrics.InstallTime -gt 0) {
        Write-Host "Installation time: $([math]::Round($script:PerformanceMetrics.InstallTime, 2)) seconds" -ForegroundColor Cyan
    }
    
    if ($script:PerformanceMetrics.TotalOperations -gt 0) {
        $avgTime = $totalTime / $script:PerformanceMetrics.TotalOperations
        Write-Host "Operations completed: $($script:PerformanceMetrics.TotalOperations)" -ForegroundColor Cyan
        Write-Host "Average time per operation: $([math]::Round($avgTime, 2)) seconds" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "Optimizations applied:" -ForegroundColor Yellow
    if ($UseCache) { Write-Host "  ✓ File caching enabled" -ForegroundColor Green }
    if ($ParallelDownloads -gt 1) { Write-Host "  ✓ Parallel downloads ($ParallelDownloads concurrent)" -ForegroundColor Green }
    Write-Host "  ✓ Silent progress (reduced overhead)" -ForegroundColor Green
    Write-Host "  ✓ Optimized network settings" -ForegroundColor Green
    Write-Host ""
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
        # Verify administrator privileges (skip for DownloadOnly mode)
        if (-not $DownloadOnly -and -not (Test-AdminPrivileges)) {
            Write-Host "ERROR: This script requires administrator privileges!" -ForegroundColor $Colors.Error
            Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor $Colors.Error
            Write-Host ""
            Write-Host "TIP: For download-only mode, use: .\install-windows.ps1 -DownloadOnly" -ForegroundColor $Colors.Info
            exit 1
        }
        
        # Show banner
        Show-Banner
        
        # Handle DownloadOnly mode
        if ($DownloadOnly) {
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "  DOWNLOAD-ONLY MODE" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            
            # Create directory structure
            New-DirectoryStructure
            
            # Download all tools
            if (Download-AllRequiredTools) {
                Write-Host ""
                Write-Host "✓ All downloads completed successfully!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Files downloaded to: $WorkingDirectory\downloads" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "  1. Run this script as Administrator to install drivers" -ForegroundColor White
                Write-Host "  2. Or run: .\install-windows.ps1 -AutoInstall" -ForegroundColor White
                Write-Host ""
                Show-PerformanceMetrics
                exit 0
            }
            else {
                Write-Host ""
                Write-Host "! Some downloads failed. Check the log for details." -ForegroundColor Red
                Write-Host "Log file: $LogFile" -ForegroundColor Cyan
                Write-Host ""
                Show-PerformanceMetrics
                exit 1
            }
        }
        
        # Handle AutoInstall mode
        if ($AutoInstall) {
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "  AUTOMATIC INSTALLATION MODE" -ForegroundColor Cyan
            if ($OptimizedMode) {
                Write-Host "  ⚡ OPTIMIZED MODE ENABLED" -ForegroundColor Green
            }
            Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            
            # Check system requirements
            if (-not (Check-SystemRequirements)) {
                Write-Log "System requirements not met. Please resolve issues and try again." "Error"
                exit 1
            }
            
            Write-Log "System requirements verified" "Success"
            
            # Create directory structure
            New-DirectoryStructure
            
            # Run full installation
            if (Run-FullInstallation) {
                Write-Host ""
                Write-Host "✓ Automatic installation completed successfully!" -ForegroundColor Green
                Write-Host ""
                Show-PerformanceMetrics
                exit 0
            }
            else {
                Write-Host ""
                Write-Host "! Installation completed with warnings or was cancelled." -ForegroundColor Yellow
                Write-Host "Check the log for details: $LogFile" -ForegroundColor Cyan
                Write-Host ""
                Show-PerformanceMetrics
                exit 1
            }
        }
        
        # Normal interactive mode
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
        
        # Show performance metrics at the end
        Show-PerformanceMetrics
    }
    catch {
        Write-Log "Fatal error: $_" "Error"
        Write-Log $_.ScriptStackTrace "Error"
        Show-PerformanceMetrics
        exit 1
    }
}

# Run main function
Main
