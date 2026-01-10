<#
.SYNOPSIS
    Clean workspace and temporary files.

.DESCRIPTION
    Cleanup script that removes temporary files, old logs,
    old checkpoints, and downloads while preserving important data.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Deep,
    
    [Parameter()]
    [switch]$DryRun,
    
    [Parameter()]
    [int]$KeepDays = 7
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulePath "Logger.psm1") -Force
Import-Module (Join-Path $modulePath "UI-Helper.psm1") -Force

function Remove-OldLogs {
    param([int]$Days)
    
    $logDir = Join-Path $PSScriptRoot "..\..\work\logs"
    if (-not (Test-Path $logDir)) { return }
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $oldLogs = Get-ChildItem $logDir -Recurse | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    Write-ColoredMessage "Found $($oldLogs.Count) old log files" "Cyan"
    
    foreach ($log in $oldLogs) {
        if (-not $DryRun) {
            Remove-Item $log.FullName -Force
            Write-Log "Deleted: $($log.FullName)"
        } else {
            Write-Host "Would delete: $($log.FullName)"
        }
    }
}

function Remove-OldCheckpoints {
    param([int]$Days)
    
    $checkpointDir = Join-Path $PSScriptRoot "..\..\work\checkpoints"
    if (-not (Test-Path $checkpointDir)) { return }
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $oldCheckpoints = Get-ChildItem $checkpointDir -Recurse | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    Write-ColoredMessage "Found $($oldCheckpoints.Count) old checkpoints" "Cyan"
    
    foreach ($checkpoint in $oldCheckpoints) {
        if (-not $DryRun) {
            Remove-Item $checkpoint.FullName -Force -Recurse
            Write-Log "Deleted: $($checkpoint.FullName)"
        } else {
            Write-Host "Would delete: $($checkpoint.FullName)"
        }
    }
}

function Remove-TempFiles {
    $tempDirs = @(
        (Join-Path $PSScriptRoot "..\..\work\extracted"),
        (Join-Path $PSScriptRoot "..\..\work\downloads\temp")
    )
    
    foreach ($dir in $tempDirs) {
        if (Test-Path $dir) {
            $items = Get-ChildItem $dir -Recurse
            Write-ColoredMessage "Found $($items.Count) temp files in $dir" "Cyan"
            
            if (-not $DryRun) {
                Remove-Item $dir -Recurse -Force
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Log "Cleaned: $dir"
            } else {
                Write-Host "Would clean: $dir"
            }
        }
    }
}

function Remove-OldDownloads {
    param([int]$Days)
    
    $downloadDir = Join-Path $PSScriptRoot "..\..\work\downloads"
    if (-not (Test-Path $downloadDir)) { return }
    
    $cutoffDate = (Get-Date).AddDays(-$Days * 2) # Keep downloads longer
    $oldDownloads = Get-ChildItem $downloadDir -File | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    Write-ColoredMessage "Found $($oldDownloads.Count) old downloads" "Cyan"
    
    foreach ($download in $oldDownloads) {
        Write-Host "  $($download.Name) - $($download.LastWriteTime)"
    }
    
    if ($oldDownloads.Count -gt 0) {
        $confirm = Read-Host "Delete old downloads? (yes/no)"
        if ($confirm -eq "yes" -and -not $DryRun) {
            foreach ($download in $oldDownloads) {
                Remove-Item $download.FullName -Force
                Write-Log "Deleted: $($download.FullName)"
            }
        }
    }
}

function Get-WorkspaceSize {
    $workDir = Join-Path $PSScriptRoot "..\..\work"
    if (-not (Test-Path $workDir)) { return 0 }
    
    $size = (Get-ChildItem $workDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
    return [math]::Round($size / 1MB, 2)
}

# Main execution
Show-Banner

Write-ColoredMessage "Workspace Cleanup" "Cyan"
Write-ColoredMessage "==================" "Cyan"

$sizeBefore = Get-WorkspaceSize
Write-ColoredMessage "Current workspace size: $sizeBefore MB" "White"

if ($DryRun) {
    Write-ColoredMessage "`n[DRY RUN MODE - No files will be deleted]`n" "Yellow"
}

Write-ColoredMessage "`nCleaning old logs (older than $KeepDays days)..." "Cyan"
Remove-OldLogs -Days $KeepDays

Write-ColoredMessage "`nCleaning old checkpoints (older than $KeepDays days)..." "Cyan"
Remove-OldCheckpoints -Days $KeepDays

Write-ColoredMessage "`nCleaning temporary files..." "Cyan"
Remove-TempFiles

if ($Deep) {
    Write-ColoredMessage "`nCleaning old downloads (older than $($KeepDays * 2) days)..." "Cyan"
    Remove-OldDownloads -Days $KeepDays
}

$sizeAfter = Get-WorkspaceSize
$saved = $sizeBefore - $sizeAfter

Write-ColoredMessage "`n==================" "Cyan"
Write-ColoredMessage "Cleanup Summary" "Cyan"
Write-ColoredMessage "==================" "Cyan"
Write-ColoredMessage "Workspace size before: $sizeBefore MB" "White"
Write-ColoredMessage "Workspace size after: $sizeAfter MB" "White"
Write-ColoredMessage "Space saved: $saved MB" "Green"

if ($DryRun) {
    Write-ColoredMessage "`nRun without -DryRun to actually delete files" "Yellow"
}

Write-ColoredMessage "`nCleanup completed!" "Green"
