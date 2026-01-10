<#
.SYNOPSIS
    Device-Manager-Modul für Geräte-Erkennung und -Verwaltung

.DESCRIPTION
    Auto-Detection von Realme C63, Chipset-Erkennung, State-Analysis
    und Geräte-Kommunikation via ADB/Fastboot

.NOTES
    Author: Xylop90
    Version: 2.0.0
#>

$script:ExpectedModel = "RMX3939"
$script:ExpectedDevice = "Realme C63"
$script:ExpectedChipset = "Unisoc UMS512"

function Test-ADBInstalled {
    <#
    .SYNOPSIS
    Prüft ob ADB installiert ist
    #>
    [CmdletBinding()]
    param()
    
    $adbPath = Get-ADBPath
    return (Test-Path $adbPath)
}

function Get-ADBPath {
    <#
    .SYNOPSIS
    Gibt den Pfad zur ADB-Binary zurück
    #>
    [CmdletBinding()]
    param()
    
    # Check in work/tools directory first
    $workDir = Join-Path $PSScriptRoot "..\..\work\tools\adb"
    $adbExe = Join-Path $workDir "adb.exe"
    
    if (Test-Path $adbExe) {
        return $adbExe
    }
    
    # Check in PATH
    $adbInPath = Get-Command adb.exe -ErrorAction SilentlyContinue
    if ($adbInPath) {
        return $adbInPath.Source
    }
    
    return $null
}

function Get-FastbootPath {
    <#
    .SYNOPSIS
    Gibt den Pfad zur Fastboot-Binary zurück
    #>
    [CmdletBinding()]
    param()
    
    # Check in work/tools directory first
    $workDir = Join-Path $PSScriptRoot "..\..\work\tools\adb"
    $fastbootExe = Join-Path $workDir "fastboot.exe"
    
    if (Test-Path $fastbootExe) {
        return $fastbootExe
    }
    
    # Check in PATH
    $fastbootInPath = Get-Command fastboot.exe -ErrorAction SilentlyContinue
    if ($fastbootInPath) {
        return $fastbootInPath.Source
    }
    
    return $null
}

function Start-ADBServer {
    <#
    .SYNOPSIS
    Startet den ADB-Server
    #>
    [CmdletBinding()]
    param()
    
    try {
        $adbPath = Get-ADBPath
        
        if (-not $adbPath) {
            Write-Log -Message "ADB not found" -Level "ERROR" -Category "Device"
            return $false
        }
        
        Write-Log -Message "Starting ADB server..." -Level "INFO" -Category "Device"
        
        & $adbPath start-server 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        Write-Log -Message "ADB server started" -Level "INFO" -Category "Device"
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to start ADB server" -ErrorRecord $_ -Category "Device"
        return $false
    }
}

function Test-DeviceConnected {
    <#
    .SYNOPSIS
    Prüft ob ein Gerät via ADB verbunden ist
    #>
    [CmdletBinding()]
    param()
    
    try {
        $adbPath = Get-ADBPath
        
        if (-not $adbPath) {
            return $false
        }
        
        $devices = & $adbPath devices 2>&1 | Select-Object -Skip 1
        $connectedDevices = $devices | Where-Object { $_ -match "device$" -and $_ -notmatch "List of devices" }
        
        return ($null -ne $connectedDevices -and $connectedDevices.Count -gt 0)
    }
    catch {
        return $false
    }
}

function Get-ConnectedDevices {
    <#
    .SYNOPSIS
    Gibt eine Liste aller verbundenen Geräte zurück
    #>
    [CmdletBinding()]
    param()
    
    try {
        $adbPath = Get-ADBPath
        
        if (-not $adbPath) {
            Write-Log -Message "ADB not found" -Level "ERROR" -Category "Device"
            return @()
        }
        
        Start-ADBServer | Out-Null
        
        $output = & $adbPath devices 2>&1 | Select-Object -Skip 1
        $devices = @()
        
        foreach ($line in $output) {
            if ($line -match "^([^\s]+)\s+device$") {
                $devices += $Matches[1]
            }
        }
        
        Write-Log -Message "Found $($devices.Count) connected device(s)" -Level "INFO" -Category "Device"
        
        return $devices
    }
    catch {
        Write-ErrorLog -Message "Failed to get connected devices" -ErrorRecord $_ -Category "Device"
        return @()
    }
}

function Get-DeviceInfo {
    <#
    .SYNOPSIS
    Sammelt detaillierte Informationen über das verbundene Gerät
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$DeviceSerial
    )
    
    try {
        $adbPath = Get-ADBPath
        
        if (-not $adbPath) {
            Write-Log -Message "ADB not found" -Level "ERROR" -Category "Device"
            return $null
        }
        
        $adbCmd = if ($DeviceSerial) { @("-s", $DeviceSerial) } else { @() }
        
        Write-Log -Message "Retrieving device information..." -Level "INFO" -Category "Device"
        
        $info = @{
            Serial           = if ($DeviceSerial) { $DeviceSerial } else { "unknown" }
            Model            = (& $adbPath $adbCmd shell getprop ro.product.model 2>&1).Trim()
            Device           = (& $adbPath $adbCmd shell getprop ro.product.device 2>&1).Trim()
            Manufacturer     = (& $adbPath $adbCmd shell getprop ro.product.manufacturer 2>&1).Trim()
            Brand            = (& $adbPath $adbCmd shell getprop ro.product.brand 2>&1).Trim()
            AndroidVersion   = (& $adbPath $adbCmd shell getprop ro.build.version.release 2>&1).Trim()
            SDKVersion       = (& $adbPath $adbCmd shell getprop ro.build.version.sdk 2>&1).Trim()
            BuildNumber      = (& $adbPath $adbCmd shell getprop ro.build.display.id 2>&1).Trim()
            BuildDate        = (& $adbPath $adbCmd shell getprop ro.build.date 2>&1).Trim()
            Fingerprint      = (& $adbPath $adbCmd shell getprop ro.build.fingerprint 2>&1).Trim()
            Board            = (& $adbPath $adbCmd shell getprop ro.product.board 2>&1).Trim()
            Platform         = (& $adbPath $adbCmd shell getprop ro.board.platform 2>&1).Trim()
            CPUArchitecture  = (& $adbPath $adbCmd shell getprop ro.product.cpu.abi 2>&1).Trim()
            BootloaderLocked = "unknown"
        }
        
        # Try to detect bootloader state (only works in some cases)
        $bootloaderState = & $adbPath $adbCmd shell getprop ro.boot.verifiedbootstate 2>&1
        if ($bootloaderState) {
            $info.BootloaderLocked = $bootloaderState.Trim()
        }
        
        Write-Log -Message "Device info retrieved: $($info.Model)" -Level "INFO" -Category "Device" -Data $info
        
        return $info
    }
    catch {
        Write-ErrorLog -Message "Failed to retrieve device info" -ErrorRecord $_ -Category "Device"
        return $null
    }
}

function Test-DeviceCompatible {
    <#
    .SYNOPSIS
    Prüft ob das verbundene Gerät kompatibel ist (Realme C63 RMX3939)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$DeviceInfo
    )
    
    if (-not $DeviceInfo) {
        $DeviceInfo = Get-DeviceInfo
    }
    
    if (-not $DeviceInfo) {
        Write-Log -Message "Cannot verify device compatibility: No device info" -Level "WARNING" -Category "Device"
        return $false
    }
    
    $isCompatible = $false
    $reason = ""
    
    # Check model
    if ($DeviceInfo.Device -eq $script:ExpectedModel -or $DeviceInfo.Model -match "Realme.*C63") {
        $isCompatible = $true
        Write-Log -Message "Device is compatible: $($DeviceInfo.Model)" -Level "INFO" -Category "Device"
    }
    else {
        $reason = "Expected model: $script:ExpectedModel or Realme C63, found: $($DeviceInfo.Model)"
        Write-Log -Message "Device may not be compatible: $reason" -Level "WARNING" -Category "Device"
    }
    
    return $isCompatible
}

function Get-DeviceState {
    <#
    .SYNOPSIS
    Analysiert den aktuellen Zustand des Geräts (Stock/Unlocked/Rooted)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$DeviceInfo
    )
    
    if (-not $DeviceInfo) {
        $DeviceInfo = Get-DeviceInfo
    }
    
    if (-not $DeviceInfo) {
        return $null
    }
    
    $adbPath = Get-ADBPath
    
    $state = @{
        IsRooted         = $false
        HasMagisk        = $false
        HasTWRP          = $false
        BootloaderLocked = $true
        IsStock          = $true
    }
    
    try {
        # Check for root
        $suCheck = & $adbPath shell "su -c 'id'" 2>&1
        if ($suCheck -match "uid=0") {
            $state.IsRooted = $true
            $state.IsStock = $false
        }
        
        # Check for Magisk
        $magiskCheck = & $adbPath shell "pm list packages" 2>&1 | Select-String "com.topjohnwu.magisk"
        if ($magiskCheck) {
            $state.HasMagisk = $true
            $state.IsStock = $false
        }
        
        # Check bootloader state from fingerprint
        if ($DeviceInfo.Fingerprint -notmatch "release-keys") {
            $state.BootloaderLocked = $false
            $state.IsStock = $false
        }
        
        # Check for TWRP (can only be checked in recovery mode)
        # This is limited when in normal mode
        
        Write-Log -Message "Device state analyzed" -Level "INFO" -Category "Device" -Data $state
        
        return $state
    }
    catch {
        Write-ErrorLog -Message "Failed to analyze device state" -ErrorRecord $_ -Category "Device"
        return $state
    }
}

function Wait-ForDevice {
    <#
    .SYNOPSIS
    Wartet bis ein Gerät verbunden ist
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 60,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("device", "recovery", "bootloader", "sideload")]
        [string]$Mode = "device"
    )
    
    try {
        $adbPath = Get-ADBPath
        
        if (-not $adbPath) {
            Write-Log -Message "ADB not found" -Level "ERROR" -Category "Device"
            return $false
        }
        
        Write-Log -Message "Waiting for device in $Mode mode (timeout: ${TimeoutSeconds}s)..." -Level "INFO" -Category "Device"
        
        $elapsed = 0
        $checkInterval = 2
        
        while ($elapsed -lt $TimeoutSeconds) {
            $devices = & $adbPath devices 2>&1 | Select-Object -Skip 1
            
            $found = $false
            foreach ($line in $devices) {
                if ($line -match $Mode) {
                    $found = $true
                    break
                }
            }
            
            if ($found) {
                Write-Log -Message "Device found in $Mode mode" -Level "INFO" -Category "Device"
                return $true
            }
            
            Write-Host "." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Seconds $checkInterval
            $elapsed += $checkInterval
        }
        
        Write-Host ""
        Write-Log -Message "Device not found: timeout" -Level "WARNING" -Category "Device"
        return $false
    }
    catch {
        Write-ErrorLog -Message "Error waiting for device" -ErrorRecord $_ -Category "Device"
        return $false
    }
}

function Invoke-DeviceReboot {
    <#
    .SYNOPSIS
    Startet das Gerät neu
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("system", "recovery", "bootloader", "fastboot")]
        [string]$Mode = "system"
    )
    
    try {
        $adbPath = Get-ADBPath
        
        if (-not $adbPath) {
            Write-Log -Message "ADB not found" -Level "ERROR" -Category "Device"
            return $false
        }
        
        Write-Log -Message "Rebooting device to $Mode..." -Level "INFO" -Category "Device"
        
        switch ($Mode) {
            "system" { & $adbPath reboot 2>&1 | Out-Null }
            "recovery" { & $adbPath reboot recovery 2>&1 | Out-Null }
            "bootloader" { & $adbPath reboot bootloader 2>&1 | Out-Null }
            "fastboot" { & $adbPath reboot bootloader 2>&1 | Out-Null }
        }
        
        Start-Sleep -Seconds 2
        Write-Log -Message "Reboot command sent" -Level "INFO" -Category "Device"
        
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to reboot device" -ErrorRecord $_ -Category "Device"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ADBInstalled',
    'Get-ADBPath',
    'Get-FastbootPath',
    'Start-ADBServer',
    'Test-DeviceConnected',
    'Get-ConnectedDevices',
    'Get-DeviceInfo',
    'Test-DeviceCompatible',
    'Get-DeviceState',
    'Wait-ForDevice',
    'Invoke-DeviceReboot'
)
