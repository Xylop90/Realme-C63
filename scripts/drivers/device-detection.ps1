#Requires -Version 5.1
<#
.SYNOPSIS
    USB-Geräte-Erkennung für Realme C63
    
.DESCRIPTION
    Erkennt angeschlossene Realme C63 Geräte über USB VID/PID
    
.NOTES
    Author: Elektronikx-Center-Matte by Alexander Mathey
    Version: 1.0
    Date: 2026-01-10
#>

param(
    [string]$WorkingDirectory = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

# Importiere Module
. "$WorkingDirectory\scripts\lib\logger.ps1"

# ============================================================================
# DEVICE IDENTIFICATION
# ============================================================================

$Script:DeviceIDs = @{
    Realme = @{
        VID = "0x2207"
        PIDs = @("0x0006", "0x0010", "0x0011")
        Name = "Realme C63 (RMX3939)"
    }
    Unisoc = @{
        VID = "0x1782"
        PIDs = @("0x4D00", "0x4D01")
        Name = "Unisoc/Spreadtrum Device"
    }
}

function Get-USBDevices {
    <#
    .SYNOPSIS
    Liste alle USB-Geräte auf
    #>
    
    try {
        $usbDevices = Get-PnpDevice -Class USB | Where-Object { $_.Status -eq "OK" }
        return $usbDevices
    }
    catch {
        Write-LogError "Fehler beim Abrufen der USB-Geräte: $($_.Exception.Message)"
        return @()
    }
}

function Test-RealmeDevice {
    <#
    .SYNOPSIS
    Prüft ob Realme C63 angeschlossen ist
    #>
    
    Write-LogInfo "Suche nach Realme C63 Gerät..."
    
    $devices = Get-USBDevices
    
    foreach ($device in $devices) {
        $deviceId = $device.InstanceId
        
        # Prüfe auf Realme VID/PID
        if ($deviceId -match "VID_2207&PID_000[0-9A-F]") {
            Write-LogInfo "Realme/SPD Gerät gefunden: $($device.FriendlyName)"
            Write-LogDebug "Device ID: $deviceId"
            return $true
        }
        
        # Prüfe auf Unisoc VID/PID
        if ($deviceId -match "VID_1782&PID_4D0[0-9A-F]") {
            Write-LogInfo "Unisoc Gerät gefunden: $($device.FriendlyName)"
            Write-LogDebug "Device ID: $deviceId"
            return $true
        }
    }
    
    Write-LogWarning "Kein Realme C63 Gerät gefunden"
    return $false
}

function Get-DeviceInfo {
    <#
    .SYNOPSIS
    Hole detaillierte Geräteinformationen
    #>
    
    $adbExe = Join-Path $WorkingDirectory "work\platform-tools\adb.exe"
    
    if (-not (Test-Path $adbExe)) {
        Write-LogWarning "ADB nicht verfügbar für Geräte-Informationen"
        return $null
    }
    
    try {
        # Starte ADB Server
        & $adbExe start-server 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        # Prüfe Verbindung
        $devices = & $adbExe devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
        
        if (-not $devices) {
            Write-LogWarning "Kein Gerät über ADB erreichbar"
            return $null
        }
        
        # Hole Geräteinformationen
        $info = @{
            Model = (& $adbExe shell getprop ro.product.model 2>&1).Trim()
            Manufacturer = (& $adbExe shell getprop ro.product.manufacturer 2>&1).Trim()
            AndroidVersion = (& $adbExe shell getprop ro.build.version.release 2>&1).Trim()
            BuildID = (& $adbExe shell getprop ro.build.id 2>&1).Trim()
            Serial = (& $adbExe shell getprop ro.serialno 2>&1).Trim()
            Codename = (& $adbExe shell getprop ro.product.device 2>&1).Trim()
        }
        
        Write-LogInfo "Geräte-Informationen abgerufen:"
        Write-LogInfo "  Model: $($info.Model)"
        Write-LogInfo "  Manufacturer: $($info.Manufacturer)"
        Write-LogInfo "  Android: $($info.AndroidVersion)"
        Write-LogInfo "  Build: $($info.BuildID)"
        
        return $info
    }
    catch {
        Write-LogError "Fehler beim Abrufen der Geräte-Informationen: $($_.Exception.Message)"
        return $null
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Get-USBDevices',
    'Test-RealmeDevice',
    'Get-DeviceInfo'
)
