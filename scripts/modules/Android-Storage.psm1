<#
.SYNOPSIS
    Android Storage Management Module for Realme C63 (RMX3939)
    
.DESCRIPTION
    Provides comprehensive Android storage management including SD card scanning,
    internal storage access, automatic file/folder creation, and storage optimization
    
.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    
.LINK
    https://github.com/Xylop90/Realme-C63
#>

#Requires -Version 5.1

# Module variables
$script:ModuleName = "Android-Storage"
$script:ModuleVersion = "1.0.0"

<#
.SYNOPSIS
    Scans Android SD card for files and folders
    
.DESCRIPTION
    Performs comprehensive scan of external SD card storage on connected Android device
    
.PARAMETER DeviceSerial
    Device serial number (optional, uses first connected device if not specified)
    
.PARAMETER ScanDepth
    Maximum depth for directory scanning (default: unlimited)
    
.EXAMPLE
    Scan-AndroidSDCard
    
.EXAMPLE
    Scan-AndroidSDCard -DeviceSerial "ABC123" -ScanDepth 3
#>
function Scan-AndroidSDCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$DeviceSerial,
        
        [Parameter(Mandatory=$false)]
        [int]$ScanDepth = -1
    )
    
    try {
        Write-Log "Scanning Android SD card storage..." "INFO"
        
        # Check device connection
        $device = Get-ConnectedDevice
        if (-not $device) {
            throw "No Android device connected"
        }
        
        # Determine SD card paths
        $sdCardPaths = @(
            "/storage/sdcard1",
            "/storage/extSdCard",
            "/mnt/sdcard/external_sd",
            "/storage/external_SD",
            "/mnt/external_sd"
        )
        
        $foundPath = $null
        foreach ($path in $sdCardPaths) {
            $result = & adb shell "test -d $path && echo exists"
            if ($result -match "exists") {
                $foundPath = $path
                break
            }
        }
        
        if (-not $foundPath) {
            Write-Log "No SD card detected on device" "WARN"
            return @{
                Success = $false
                Message = "No SD card found"
                Path = $null
                Files = @()
            }
        }
        
        Write-Log "SD card found at: $foundPath" "INFO"
        
        # Scan SD card
        $scanCommand = "find $foundPath -type f"
        if ($ScanDepth -gt 0) {
            $scanCommand += " -maxdepth $ScanDepth"
        }
        
        $files = & adb shell $scanCommand 2>$null | Where-Object { $_ }
        
        Write-Log "Found $($files.Count) files on SD card" "INFO"
        
        return @{
            Success = $true
            Path = $foundPath
            Files = $files
            Count = $files.Count
        }
        
    } catch {
        Write-Log "Error scanning SD card: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Scans Android internal storage
    
.DESCRIPTION
    Performs comprehensive scan of internal storage on connected Android device
    
.PARAMETER IncludeSystem
    Include system directories in scan
    
.EXAMPLE
    Scan-AndroidInternalStorage
#>
function Scan-AndroidInternalStorage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$IncludeSystem
    )
    
    try {
        Write-Log "Scanning Android internal storage..." "INFO"
        
        # Check device connection
        $device = Get-ConnectedDevice
        if (-not $device) {
            throw "No Android device connected"
        }
        
        # Scan common user directories
        $userPaths = @(
            "/sdcard/Download",
            "/sdcard/DCIM",
            "/sdcard/Documents",
            "/sdcard/Pictures",
            "/sdcard/Music",
            "/sdcard/Movies",
            "/sdcard/Android/data"
        )
        
        $storageInfo = @{}
        
        foreach ($path in $userPaths) {
            $files = & adb shell "find $path -type f 2>/dev/null" | Where-Object { $_ }
            $storageInfo[$path] = @{
                Files = $files
                Count = $files.Count
            }
        }
        
        # Get storage statistics
        $storageStats = & adb shell "df -h /sdcard" | Select-Object -Skip 1
        
        Write-Log "Internal storage scan complete" "INFO"
        
        return @{
            Success = $true
            Directories = $storageInfo
            Statistics = $storageStats
            TotalFiles = ($storageInfo.Values | Measure-Object -Property Count -Sum).Sum
        }
        
    } catch {
        Write-Log "Error scanning internal storage: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Creates installation directories on Android device
    
.DESCRIPTION
    Automatically creates required directories for installation files on Android device
    
.PARAMETER BasePath
    Base path for installation directories (default: /sdcard/RealmeC63-Installer)
    
.EXAMPLE
    New-AndroidInstallationFolders
#>
function New-AndroidInstallationFolders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$BasePath = "/sdcard/RealmeC63-Installer"
    )
    
    try {
        Write-Log "Creating installation folders on Android device..." "INFO"
        
        # Define folder structure
        $folders = @(
            "$BasePath",
            "$BasePath/Firmware",
            "$BasePath/Recovery",
            "$BasePath/Magisk",
            "$BasePath/Backups",
            "$BasePath/Logs",
            "$BasePath/Downloads",
            "$BasePath/Documentation"
        )
        
        $created = @()
        
        foreach ($folder in $folders) {
            $result = & adb shell "mkdir -p $folder && echo created"
            if ($result -match "created") {
                $created += $folder
                Write-Log "Created: $folder" "INFO"
            }
        }
        
        Write-Log "Created $($created.Count) folders on device" "INFO"
        
        return @{
            Success = $true
            BasePath = $BasePath
            Created = $created
            Count = $created.Count
        }
        
    } catch {
        Write-Log "Error creating folders: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Pushes files to Android device storage
    
.DESCRIPTION
    Transfers files from PC to Android device storage locations
    
.PARAMETER SourcePath
    Source file or directory path on PC
    
.PARAMETER DestinationPath
    Destination path on Android device
    
.EXAMPLE
    Push-FilesToAndroid -SourcePath "C:\firmware.zip" -DestinationPath "/sdcard/Download/"
#>
function Push-FilesToAndroid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )
    
    try {
        Write-Log "Pushing files to Android device..." "INFO"
        
        if (-not (Test-Path $SourcePath)) {
            throw "Source path not found: $SourcePath"
        }
        
        # Push file(s)
        $result = & adb push $SourcePath $DestinationPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Files pushed successfully" "INFO"
            return @{
                Success = $true
                Source = $SourcePath
                Destination = $DestinationPath
            }
        } else {
            throw "Failed to push files: $result"
        }
        
    } catch {
        Write-Log "Error pushing files: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Gets Android storage information
    
.DESCRIPTION
    Retrieves comprehensive storage information from Android device
    
.EXAMPLE
    Get-AndroidStorageInfo
#>
function Get-AndroidStorageInfo {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Getting Android storage information..." "INFO"
        
        # Get storage statistics
        $internalStats = & adb shell "df -h /sdcard" | Select-Object -Skip 1
        $systemStats = & adb shell "df -h /system" | Select-Object -Skip 1
        $dataStats = & adb shell "df -h /data" | Select-Object -Skip 1
        
        # Check for SD card
        $hasSDCard = $false
        $sdCardStats = $null
        
        $sdCardPaths = @("/storage/sdcard1", "/storage/extSdCard")
        foreach ($path in $sdCardPaths) {
            $test = & adb shell "test -d $path && echo exists"
            if ($test -match "exists") {
                $hasSDCard = $true
                $sdCardStats = & adb shell "df -h $path" | Select-Object -Skip 1
                break
            }
        }
        
        return @{
            Success = $true
            Internal = $internalStats
            System = $systemStats
            Data = $dataStats
            HasSDCard = $hasSDCard
            SDCard = $sdCardStats
        }
        
    } catch {
        Write-Log "Error getting storage info: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Optimizes Android storage
    
.DESCRIPTION
    Performs storage optimization including cache cleaning and temp file removal
    
.EXAMPLE
    Optimize-AndroidStorage
#>
function Optimize-AndroidStorage {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Optimizing Android storage..." "INFO"
        
        $cleaned = @()
        
        # Clean cache directories
        $cacheDirs = @(
            "/data/cache",
            "/cache",
            "/sdcard/.thumbnails"
        )
        
        foreach ($dir in $cacheDirs) {
            $result = & adb shell "rm -rf $dir/* 2>/dev/null && echo cleaned"
            if ($result -match "cleaned") {
                $cleaned += $dir
            }
        }
        
        Write-Log "Storage optimization complete" "INFO"
        
        return @{
            Success = $true
            CleanedDirectories = $cleaned
            Count = $cleaned.Count
        }
        
    } catch {
        Write-Log "Error optimizing storage: $_" "ERROR"
        throw
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Scan-AndroidSDCard',
    'Scan-AndroidInternalStorage',
    'New-AndroidInstallationFolders',
    'Push-FilesToAndroid',
    'Get-AndroidStorageInfo',
    'Optimize-AndroidStorage'
)
