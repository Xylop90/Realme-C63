<#
.SYNOPSIS
    ADB backup manager for Realme C63
    
.DESCRIPTION
    Creates and manages device backups using ADB backup protocol
    Supports full, incremental, and selective backups
    
.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0
    
.EXAMPLE
    .\Backup-Device.ps1
    .\Backup-Device.ps1 -BackupType Full
    .\Backup-Device.ps1 -Restore -BackupFile "backup.ab"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Full", "Apps", "Data", "System")]
    [string]$BackupType = "Full",
    
    [Parameter()]
    [switch]$Restore,
    
    [Parameter()]
    [string]$BackupFile,
    
    [Parameter()]
    [switch]$NoCompression
)

$ErrorActionPreference = "Stop"

# Import required modules
$modulesPath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulesPath "Device-Manager.psm1") -Force
Import-Module (Join-Path $modulesPath "Logger.psm1") -Force
Import-Module (Join-Path $modulesPath "UI-Helper.psm1") -Force

# Setup backup directory
$backupDir = Join-Path $PSScriptRoot "..\..\work\backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

function New-DeviceBackup {
    param(
        [string]$Type,
        [bool]$Compress
    )
    
    Write-ColoredMessage "Creating device backup..." "Cyan"
    
    # Check device connection
    if (-not (Test-DeviceConnected)) {
        Write-ColoredMessage "Error: No device connected" "Red"
        return $false
    }
    
    # Generate backup filename
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $backupDir "realme-c63-$Type-$timestamp.ab"
    
    # Build ADB backup command
    $adbArgs = @("backup")
    
    switch ($Type) {
        "Full" {
            $adbArgs += "-all"
            $adbArgs += "-apk"
            $adbArgs += "-shared"
            $adbArgs += "-system"
        }
        "Apps" {
            $adbArgs += "-noapk"
        }
        "Data" {
            $adbArgs += "-all"
            $adbArgs += "-noapk"
        }
        "System" {
            $adbArgs += "-system"
        }
    }
    
    if (-not $Compress) {
        $adbArgs += "-nocompress"
    }
    
    $adbArgs += "-f"
    $adbArgs += "`"$backupPath`""
    
    Write-ColoredMessage "Backup type: $Type" "White"
    Write-ColoredMessage "Destination: $backupPath" "White"
    Write-Host ""
    Write-ColoredMessage "⚠ Please confirm backup on device screen!" "Yellow"
    Write-Host ""
    
    # Execute backup
    try {
        $process = Start-Process "adb" -ArgumentList $adbArgs -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0 -and (Test-Path $backupPath)) {
            $fileSize = (Get-Item $backupPath).Length / 1MB
            Write-ColoredMessage "✓ Backup completed successfully!" "Green"
            Write-ColoredMessage "  Size: $([math]::Round($fileSize, 2)) MB" "White"
            Write-ColoredMessage "  Path: $backupPath" "White"
            return $true
        } else {
            Write-ColoredMessage "✗ Backup failed!" "Red"
            return $false
        }
    } catch {
        Write-ColoredMessage "Error during backup: $_" "Red"
        return $false
    }
}

function Restore-DeviceBackup {
    param([string]$FilePath)
    
    Write-ColoredMessage "Restoring device backup..." "Cyan"
    
    # Check device connection
    if (-not (Test-DeviceConnected)) {
        Write-ColoredMessage "Error: No device connected" "Red"
        return $false
    }
    
    # Check backup file exists
    if (-not (Test-Path $FilePath)) {
        Write-ColoredMessage "Error: Backup file not found: $FilePath" "Red"
        return $false
    }
    
    Write-ColoredMessage "Backup file: $FilePath" "White"
    Write-Host ""
    Write-ColoredMessage "⚠ Please confirm restore on device screen!" "Yellow"
    Write-Host ""
    
    # Execute restore
    try {
        $process = Start-Process "adb" -ArgumentList "restore `"$FilePath`"" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-ColoredMessage "✓ Restore completed successfully!" "Green"
            return $true
        } else {
            Write-ColoredMessage "✗ Restore failed!" "Red"
            return $false
        }
    } catch {
        Write-ColoredMessage "Error during restore: $_" "Red"
        return $false
    }
}

function Show-BackupList {
    Write-ColoredMessage "`nAvailable backups:" "Cyan"
    $backups = Get-ChildItem -Path $backupDir -Filter "*.ab" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-ColoredMessage "No backups found" "Yellow"
        return
    }
    
    $index = 1
    foreach ($backup in $backups) {
        $size = $backup.Length / 1MB
        Write-Host "[$index]" -ForegroundColor Cyan -NoNewline
        Write-Host " $($backup.Name)" -NoNewline
        Write-Host " - $([math]::Round($size, 2)) MB" -ForegroundColor Gray -NoNewline
        Write-Host " - $($backup.LastWriteTime)" -ForegroundColor DarkGray
        $index++
    }
}

# Main execution
Write-ColoredMessage "═══ Realme C63 Backup Manager ═══" "Cyan"
Write-Host ""

if ($Restore) {
    if ($BackupFile) {
        Restore-DeviceBackup -FilePath $BackupFile
    } else {
        Show-BackupList
        Write-Host ""
        $selection = Read-Host "Enter backup number to restore (or 0 to cancel)"
        if ($selection -gt 0) {
            $backups = Get-ChildItem -Path $backupDir -Filter "*.ab" | Sort-Object LastWriteTime -Descending
            if ($selection -le $backups.Count) {
                Restore-DeviceBackup -FilePath $backups[$selection - 1].FullName
            }
        }
    }
} else {
    $compress = -not $NoCompression
    New-DeviceBackup -Type $BackupType -Compress $compress
    Write-Host ""
    Show-BackupList
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
