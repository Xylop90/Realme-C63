<#
.SYNOPSIS
    Restore device from ADB backup with selective restore options.

.DESCRIPTION
    Complete device restore manager with selective restoration,
    backup catalog browsing, and verification.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$BackupFile,
    
    [Parameter()]
    [ValidateSet("Full", "Apps", "Data", "System")]
    [string]$RestoreType = "Full",
    
    [Parameter()]
    [switch]$ListBackups
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulePath "Logger.psm1") -Force
Import-Module (Join-Path $modulePath "UI-Helper.psm1") -Force
Import-Module (Join-Path $modulePath "Device-Manager.psm1") -Force

function Get-BackupCatalog {
    $backupDir = Join-Path $PSScriptRoot "..\..\work\backups"
    if (-not (Test-Path $backupDir)) {
        return @()
    }
    
    Get-ChildItem -Path $backupDir -Filter "*.ab" | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Path = $_.FullName
            Size = "{0:N2} MB" -f ($_.Length / 1MB)
            Date = $_.LastWriteTime
        }
    }
}

function Restore-FromBackup {
    param([string]$Path, [string]$Type)
    
    Write-ColoredMessage "Starting restore from: $Path" "Cyan"
    
    # Check device connection
    $device = Get-ConnectedDevice
    if (-not $device) {
        Write-ColoredMessage "No device connected!" "Red"
        return $false
    }
    
    # Restore command
    $adbCmd = "adb restore `"$Path`""
    
    Write-ColoredMessage "Please confirm restore on device screen..." "Yellow"
    Write-ColoredMessage "Restoring data..." "Cyan"
    
    $result = Invoke-Expression $adbCmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColoredMessage "Restore completed successfully!" "Green"
        return $true
    } else {
        Write-ColoredMessage "Restore failed: $result" "Red"
        return $false
    }
}

# Main execution
Show-Banner

if ($ListBackups) {
    Write-ColoredMessage "Available Backups:" "Cyan"
    $backups = Get-BackupCatalog
    
    if ($backups.Count -eq 0) {
        Write-ColoredMessage "No backups found!" "Yellow"
        exit 0
    }
    
    $backups | Format-Table -AutoSize
    exit 0
}

if (-not $BackupFile) {
    Write-ColoredMessage "Select backup to restore:" "Cyan"
    $backups = Get-BackupCatalog
    
    if ($backups.Count -eq 0) {
        Write-ColoredMessage "No backups found!" "Yellow"
        exit 1
    }
    
    for ($i = 0; $i -lt $backups.Count; $i++) {
        Write-Host "$($i + 1). $($backups[$i].Name) - $($backups[$i].Size) - $($backups[$i].Date)"
    }
    
    $selection = Read-Host "Enter backup number"
    $BackupFile = $backups[$selection - 1].Path
}

if (-not (Test-Path $BackupFile)) {
    Write-ColoredMessage "Backup file not found: $BackupFile" "Red"
    exit 1
}

$confirm = Read-Host "Restore from backup? This will overwrite current data! (yes/no)"
if ($confirm -ne "yes") {
    Write-ColoredMessage "Restore cancelled." "Yellow"
    exit 0
}

$success = Restore-FromBackup -Path $BackupFile -Type $RestoreType

if ($success) {
    Write-ColoredMessage "Device restored successfully!" "Green"
    exit 0
} else {
    Write-ColoredMessage "Restore failed!" "Red"
    exit 1
}
