<#
.SYNOPSIS
    Setup and manage administrator permissions for Realme C63 installation
    
.DESCRIPTION
    Verifies and manages administrator rights, handles UAC elevation,
    and manages Windows services required for driver installation
    
.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0
    
.EXAMPLE
    .\Setup-Permissions.ps1
#>

[CmdletBinding()]
param(
    [switch]$Elevated,
    [switch]$Force
)

# Function to test if running as administrator
function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to elevate the script
function Invoke-ElevateScript {
    param([string]$ScriptPath)
    
    Write-Host "Elevating to administrator..." -ForegroundColor Yellow
    
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -Elevated"
    
    try {
        Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
        exit 0
    } catch {
        Write-Host "Failed to elevate: $_" -ForegroundColor Red
        exit 1
    }
}

# Main execution
if (-not $Elevated) {
    if (-not (Test-IsAdministrator)) {
        Write-Host "Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
        Invoke-ElevateScript -ScriptPath $MyInvocation.MyCommand.Path
    }
}

Write-Host "Running with administrator privileges" -ForegroundColor Green

# Setup necessary permissions
Write-Host "Configuring system permissions..." -ForegroundColor Cyan

# Enable developer mode (for ADB)
Write-Host "Enabling developer features..." -ForegroundColor Cyan
try {
    $devMode = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path $devMode)) {
        New-Item -Path $devMode -Force | Out-Null
    }
    Set-ItemProperty -Path $devMode -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord -Force
    Write-Host "✓ Developer mode enabled" -ForegroundColor Green
} catch {
    Write-Host "⚠ Warning: Could not enable developer mode: $_" -ForegroundColor Yellow
}

# Check Windows firewall rules for ADB
Write-Host "Configuring firewall rules..." -ForegroundColor Cyan
try {
    $adbRule = Get-NetFirewallRule -DisplayName "Android Debug Bridge" -ErrorAction SilentlyContinue
    if (-not $adbRule) {
        New-NetFirewallRule -DisplayName "Android Debug Bridge" `
            -Direction Inbound -Protocol TCP -LocalPort 5037 `
            -Action Allow -Profile Any | Out-Null
        Write-Host "✓ ADB firewall rule created" -ForegroundColor Green
    } else {
        Write-Host "✓ ADB firewall rule already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Warning: Could not configure firewall: $_" -ForegroundColor Yellow
}

Write-Host "`nPermission setup complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
