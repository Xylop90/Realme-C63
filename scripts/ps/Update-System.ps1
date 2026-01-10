<#
.SYNOPSIS
    System update manager for Realme C63 installation tools
    
.DESCRIPTION
    Checks for and installs updates for all installation tools including
    Magisk, ADB Platform Tools, Python, drivers, and scripts
    
.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0
    
.EXAMPLE
    .\Update-System.ps1
    .\Update-System.ps1 -CheckOnly
#>

[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Import required modules
$modulesPath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulesPath "Update-Manager.psm1") -Force
Import-Module (Join-Path $modulesPath "Logger.psm1") -Force
Import-Module (Join-Path $modulesPath "UI-Helper.psm1") -Force

Write-ColoredMessage "Checking for updates..." "Cyan"

# Check Magisk updates
Write-ColoredMessage "`nChecking Magisk..." "White"
$magiskUpdate = Check-MagiskUpdate
if ($magiskUpdate.UpdateAvailable) {
    Write-ColoredMessage "✓ Magisk update available: $($magiskUpdate.LatestVersion)" "Green"
    if (-not $CheckOnly) {
        Update-Magisk
    }
} else {
    Write-ColoredMessage "✓ Magisk is up to date ($($magiskUpdate.CurrentVersion))" "Green"
}

# Check ADB updates
Write-ColoredMessage "`nChecking ADB Platform Tools..." "White"
$adbUpdate = Check-ADBUpdate
if ($adbUpdate.UpdateAvailable) {
    Write-ColoredMessage "✓ ADB update available" "Green"
    if (-not $CheckOnly) {
        Update-ADBTools
    }
} else {
    Write-ColoredMessage "✓ ADB Platform Tools are up to date" "Green"
}

# Check Python updates
Write-ColoredMessage "`nChecking Python..." "White"
$pythonUpdate = Check-PythonUpdate
if ($pythonUpdate.UpdateAvailable) {
    Write-ColoredMessage "✓ Python update available: $($pythonUpdate.LatestVersion)" "Green"
} else {
    Write-ColoredMessage "✓ Python is up to date" "Green"
}

# Show summary
Write-ColoredMessage "`n=== Update Summary ===" "Cyan"
Show-UpdateStatus

if ($CheckOnly) {
    Write-ColoredMessage "`nCheck complete. Use without -CheckOnly to install updates." "Yellow"
} else {
    Write-ColoredMessage "`nAll updates applied successfully!" "Green"
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
