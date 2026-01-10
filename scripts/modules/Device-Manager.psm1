<#
.SYNOPSIS
    Device-Manager fuer USB-Geraete-Erkennung und Verwaltung

.DESCRIPTION
    Funktionen fuer:
    - USB-Device-Detection
    - SPD-Mode-Detection  
    - ADB-Device-Check
    - COM-Port-Enumeration

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

# Lade Logger wenn verfuegbar
$modulePath = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $modulePath "modules\Logger.psm1") -Force -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Erkennt angeschlossene USB-Geraete

.EXAMPLE
    Get-USBDevices
#>
function Get-USBDevices {
    [CmdletBinding()]
    param()

    try {
        $devices = Get-PnpDevice -Class USB | Where-Object { $_.Status -eq "OK" }
        return $devices
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler beim Abrufen der USB-Geraete: $_" -Exception $_.Exception
        }
        return $null
    }
}

<#
.SYNOPSIS
    Prueft ob ein SPD-Geraet verbunden ist

.EXAMPLE
    Test-SPDDevice
#>
function Test-SPDDevice {
    [CmdletBinding()]
    param()

    try {
        $spdDevices = Get-PnpDevice | Where-Object {
            $_.FriendlyName -like "*Spreadtrum*" -or 
            $_.FriendlyName -like "*SPD*" -or
            $_.InstanceId -like "*USB\VID_1782*"  # Spreadtrum Vendor ID
        }

        if ($spdDevices) {
            if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                Write-SuccessLog "SPD-Geraet erkannt: $($spdDevices[0].FriendlyName)"
            }
            return $true
        }
        else {
            if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
                Write-InfoLog "Kein SPD-Geraet erkannt"
            }
            return $false
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei SPD-Geraete-Pruefung: $_" -Exception $_.Exception
        }
        return $false
    }
}

<#
.SYNOPSIS
    Prueft ADB-Geraete mit adb.exe

.PARAMETER AdbPath
    Pfad zu adb.exe

.EXAMPLE
    Test-ADBDevice -AdbPath "C:\platform-tools\adb.exe"
#>
function Test-ADBDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$AdbPath = "adb.exe"
    )

    try {
        if (-not (Test-Path -Path $AdbPath)) {
            # Versuche adb im PATH zu finden
            $AdbPath = (Get-Command adb.exe -ErrorAction SilentlyContinue).Source
            if (-not $AdbPath) {
                if (Get-Command Write-WarnLog -ErrorAction SilentlyContinue) {
                    Write-WarnLog "adb.exe nicht gefunden"
                }
                return $false
            }
        }

        $devices = & $AdbPath devices 2>$null | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
        
        if ($devices) {
            if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                Write-SuccessLog "ADB-Geraet erkannt"
            }
            return $true
        }
        else {
            if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
                Write-InfoLog "Kein ADB-Geraet erkannt"
            }
            return $false
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei ADB-Geraete-Pruefung: $_" -Exception $_.Exception
        }
        return $false
    }
}

<#
.SYNOPSIS
    Listet verfuegbare COM-Ports auf

.EXAMPLE
    Get-COMPorts
#>
function Get-COMPorts {
    [CmdletBinding()]
    param()

    try {
        $ports = [System.IO.Ports.SerialPort]::GetPortNames()
        return $ports
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler beim Abrufen der COM-Ports: $_" -Exception $_.Exception
        }
        return @()
    }
}

<#
.SYNOPSIS
    Wartet auf Geraete-Verbindung

.PARAMETER TimeoutSeconds
    Timeout in Sekunden

.PARAMETER DeviceType
    Geraete-Typ (SPD, ADB)

.EXAMPLE
    Wait-ForDevice -TimeoutSeconds 30 -DeviceType "SPD"
#>
function Wait-ForDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,

        [Parameter(Mandatory = $false)]
        [ValidateSet("SPD", "ADB")]
        [string]$DeviceType = "SPD"
    )

    $startTime = Get-Date

    if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
        Write-InfoLog "Warte auf $DeviceType-Geraet (Timeout: ${TimeoutSeconds}s)..."
    }

    while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
        $detected = $false

        switch ($DeviceType) {
            "SPD" { $detected = Test-SPDDevice }
            "ADB" { $detected = Test-ADBDevice }
        }

        if ($detected) {
            return $true
        }

        Start-Sleep -Seconds 2
        Write-Host "." -NoNewline -ForegroundColor Yellow
    }

    Write-Host ""
    if (Get-Command Write-WarnLog -ErrorAction SilentlyContinue) {
        Write-WarnLog "Timeout: Kein $DeviceType-Geraet erkannt"
    }
    return $false
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Get-USBDevices',
    'Test-SPDDevice',
    'Test-ADBDevice',
    'Get-COMPorts',
    'Wait-ForDevice'
)
