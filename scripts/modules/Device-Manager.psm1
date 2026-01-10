#Requires -Version 5.1

<#
.SYNOPSIS
    Device Manager module for ADB/Fastboot/SPD device detection

.DESCRIPTION
    Provides device detection and management capabilities for Android devices
    via ADB, Fastboot, and SPD protocols.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

<#
.SYNOPSIS
    Tests if ADB is available

.EXAMPLE
    $hasAdb = Test-ADBAvailable
#>
function Test-ADBAvailable {
    [CmdletBinding()]
    param()

    try {
        $result = & adb version 2>&1
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Tests if Fastboot is available

.EXAMPLE
    $hasFastboot = Test-FastbootAvailable
#>
function Test-FastbootAvailable {
    [CmdletBinding()]
    param()

    try {
        $result = & fastboot --version 2>&1
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Gets list of ADB devices

.EXAMPLE
    $devices = Get-ADBDevices
#>
function Get-ADBDevices {
    [CmdletBinding()]
    param()

    try {
        if (-not (Test-ADBAvailable)) {
            Write-Warning "ADB not available"
            return @()
        }

        $output = & adb devices 2>&1
        $devices = @()

        foreach ($line in $output) {
            if ($line -match '^([^\s]+)\s+device\s*$') {
                $devices += @{
                    Serial = $Matches[1]
                    Status = "device"
                    Mode = "ADB"
                }
            }
        }

        return $devices
    }
    catch {
        Write-Error "Failed to get ADB devices: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Gets list of Fastboot devices

.EXAMPLE
    $devices = Get-FastbootDevices
#>
function Get-FastbootDevices {
    [CmdletBinding()]
    param()

    try {
        if (-not (Test-FastbootAvailable)) {
            Write-Warning "Fastboot not available"
            return @()
        }

        $output = & fastboot devices 2>&1
        $devices = @()

        foreach ($line in $output) {
            if ($line -match '^([^\s]+)\s+fastboot\s*$') {
                $devices += @{
                    Serial = $Matches[1]
                    Status = "fastboot"
                    Mode = "Fastboot"
                }
            }
        }

        return $devices
    }
    catch {
        Write-Error "Failed to get Fastboot devices: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Gets device information via ADB

.PARAMETER Serial
    Device serial number (optional)

.EXAMPLE
    $info = Get-DeviceInfo
#>
function Get-DeviceInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Serial
    )

    try {
        $adbCmd = if ($Serial) { @("adb", "-s", $Serial) } else { @("adb") }

        $model = (& $adbCmd shell getprop ro.product.model 2>&1) -replace "`r|`n", ""
        $codename = (& $adbCmd shell getprop ro.product.device 2>&1) -replace "`r|`n", ""
        $androidVersion = (& $adbCmd shell getprop ro.build.version.release 2>&1) -replace "`r|`n", ""
        $buildNumber = (& $adbCmd shell getprop ro.build.display.id 2>&1) -replace "`r|`n", ""
        $serialNo = (& $adbCmd shell getprop ro.serialno 2>&1) -replace "`r|`n", ""

        return @{
            Model = $model
            Codename = $codename
            AndroidVersion = $androidVersion
            BuildNumber = $buildNumber
            SerialNumber = $serialNo
        }
    }
    catch {
        Write-Error "Failed to get device info: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Detects if device is Realme C63 (RMX3939)

.PARAMETER Serial
    Device serial number (optional)

.EXAMPLE
    $isRMX3939 = Test-DeviceRMX3939
#>
function Test-DeviceRMX3939 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Serial
    )

    try {
        $deviceInfo = Get-DeviceInfo -Serial $Serial

        if ($null -eq $deviceInfo) {
            return $false
        }

        # Check for RMX3939 model
        $isMatch = ($deviceInfo.Model -like "*C63*" -or 
                   $deviceInfo.Codename -eq "RMX3939" -or
                   $deviceInfo.Model -eq "RMX3939")

        return $isMatch
    }
    catch {
        Write-Error "Failed to detect device: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Checks bootloader status

.PARAMETER Serial
    Device serial number (optional)

.EXAMPLE
    $status = Get-BootloaderStatus
#>
function Get-BootloaderStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Serial
    )

    try {
        $adbCmd = if ($Serial) { @("adb", "-s", $Serial) } else { @("adb") }

        # Try to get bootloader status
        $unlocked = (& $adbCmd shell getprop ro.boot.flash.locked 2>&1) -replace "`r|`n", ""

        if ($unlocked -eq "0") {
            return "Unlocked"
        }
        elseif ($unlocked -eq "1") {
            return "Locked"
        }
        else {
            return "Unknown"
        }
    }
    catch {
        Write-Error "Failed to get bootloader status: $_"
        return "Unknown"
    }
}

<#
.SYNOPSIS
    Checks if device is rooted

.PARAMETER Serial
    Device serial number (optional)

.EXAMPLE
    $rooted = Test-DeviceRooted
#>
function Test-DeviceRooted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Serial
    )

    try {
        $adbCmd = if ($Serial) { @("adb", "-s", $Serial) } else { @("adb") }

        # Try to execute su command
        $result = & $adbCmd shell "su -c id" 2>&1

        # Check if result contains uid=0 (root)
        return $result -match "uid=0"
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Waits for device to be available

.PARAMETER Mode
    Device mode to wait for (ADB or Fastboot)

.PARAMETER TimeoutSeconds
    Timeout in seconds

.EXAMPLE
    Wait-ForDevice -Mode "ADB" -TimeoutSeconds 60
#>
function Wait-ForDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("ADB", "Fastboot")]
        [string]$Mode = "ADB",

        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 60
    )

    try {
        Write-Verbose "Waiting for device in $Mode mode..."

        $startTime = Get-Date
        $timeout = (Get-Date).AddSeconds($TimeoutSeconds)

        while ((Get-Date) -lt $timeout) {
            $devices = if ($Mode -eq "ADB") {
                Get-ADBDevices
            }
            else {
                Get-FastbootDevices
            }

            if ($devices.Count -gt 0) {
                Write-Verbose "Device detected in $Mode mode"
                return $true
            }

            Start-Sleep -Seconds 2
        }

        Write-Warning "Device not detected within timeout period"
        return $false
    }
    catch {
        Write-Error "Failed to wait for device: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Reboots device to specified mode

.PARAMETER Mode
    Target mode (bootloader, recovery, system)

.PARAMETER Serial
    Device serial number (optional)

.EXAMPLE
    Invoke-DeviceReboot -Mode "bootloader"
#>
function Invoke-DeviceReboot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("bootloader", "recovery", "system")]
        [string]$Mode = "system",

        [Parameter(Mandatory=$false)]
        [string]$Serial
    )

    try {
        $adbCmd = if ($Serial) { @("adb", "-s", $Serial) } else { @("adb") }

        Write-Verbose "Rebooting device to $Mode..."

        if ($Mode -eq "system") {
            & $adbCmd reboot 2>&1 | Out-Null
        }
        else {
            & $adbCmd reboot $Mode 2>&1 | Out-Null
        }

        return $LASTEXITCODE -eq 0
    }
    catch {
        Write-Error "Failed to reboot device: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Gets comprehensive device status

.PARAMETER Serial
    Device serial number (optional)

.EXAMPLE
    $status = Get-DeviceStatus
#>
function Get-DeviceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Serial
    )

    try {
        $adbDevices = Get-ADBDevices
        $fastbootDevices = Get-FastbootDevices

        $status = @{
            ADBDeviceCount = $adbDevices.Count
            FastbootDeviceCount = $fastbootDevices.Count
            DeviceConnected = ($adbDevices.Count -gt 0 -or $fastbootDevices.Count -gt 0)
            Mode = $null
            DeviceInfo = $null
            BootloaderStatus = "Unknown"
            IsRooted = $false
            IsRMX3939 = $false
        }

        if ($adbDevices.Count -gt 0) {
            $status.Mode = "ADB"
            $status.DeviceInfo = Get-DeviceInfo -Serial $Serial
            $status.BootloaderStatus = Get-BootloaderStatus -Serial $Serial
            $status.IsRooted = Test-DeviceRooted -Serial $Serial
            $status.IsRMX3939 = Test-DeviceRMX3939 -Serial $Serial
        }
        elseif ($fastbootDevices.Count -gt 0) {
            $status.Mode = "Fastboot"
        }

        return $status
    }
    catch {
        Write-Error "Failed to get device status: $_"
        return $null
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Test-ADBAvailable',
    'Test-FastbootAvailable',
    'Get-ADBDevices',
    'Get-FastbootDevices',
    'Get-DeviceInfo',
    'Test-DeviceRMX3939',
    'Get-BootloaderStatus',
    'Test-DeviceRooted',
    'Wait-ForDevice',
    'Invoke-DeviceReboot',
    'Get-DeviceStatus'
)
