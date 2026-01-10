<#
.SYNOPSIS
    TWRP/Custom Recovery Manager for Realme C63 (RMX3939)

.DESCRIPTION
    Manages TWRP and custom recovery installation for RMX3939.
    Handles recovery detection, download, installation, and verification.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

#Requires -Version 5.1

# Import required modules
Import-Module "$PSScriptRoot\Logger.psm1" -Force
Import-Module "$PSScriptRoot\UI-Helper.psm1" -Force
Import-Module "$PSScriptRoot\Download-Manager.psm1" -Force
Import-Module "$PSScriptRoot\Device-Manager.psm1" -Force
Import-Module "$PSScriptRoot\Hash-Verifier.psm1" -Force

<#
.SYNOPSIS
    Installs TWRP recovery on RMX3939
#>
function Install-TWRPRecovery {
    [CmdletBinding()]
    param(
        [string]$RecoveryPath,
        [switch]$Temporary
    )
    
    try {
        Write-Log "Starting TWRP installation..." "INFO"
        Show-Message "Installing TWRP Recovery..." "INFO"
        
        # Check device connection
        if (-not (Test-DeviceConnected)) {
            throw "Device not connected. Please connect RMX3939 in fastboot mode."
        }
        
        # Check bootloader status
        if (-not (Test-BootloaderUnlocked)) {
            throw "Bootloader must be unlocked before installing TWRP!"
        }
        
        # Get TWRP image
        if (-not $RecoveryPath) {
            $RecoveryPath = Get-TWRPImage
            if (-not $RecoveryPath) {
                throw "Failed to obtain TWRP image"
            }
        }
        
        # Verify file exists
        if (-not (Test-Path $RecoveryPath)) {
            throw "TWRP image not found: $RecoveryPath"
        }
        
        Write-Log "TWRP image: $RecoveryPath" "INFO"
        
        # Flash recovery
        Write-Log "Flashing TWRP to recovery partition..." "INFO"
        Show-ProgressBar -Percent 30 -Status "Flashing TWRP..."
        
        if ($Temporary) {
            # Boot TWRP temporarily
            $result = & fastboot boot $RecoveryPath 2>&1
            Start-Sleep -Seconds 2
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to boot TWRP: $result"
            }
            
            Write-Log "TWRP booted temporarily" "OK"
            Show-Message "TWRP booted successfully (temporary)!" "OK"
        }
        else {
            # Flash TWRP permanently
            $result = & fastboot flash recovery $RecoveryPath 2>&1
            Start-Sleep -Seconds 2
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to flash TWRP: $result"
            }
            
            Write-Log "TWRP flashed to recovery partition" "OK"
            Show-Message "TWRP installed successfully!" "OK"
            
            # Reboot to recovery
            Show-ProgressBar -Percent 80 -Status "Rebooting to recovery..."
            & fastboot reboot recovery 2>&1 | Out-Null
        }
        
        Show-ProgressBar -Percent 100 -Status "Complete"
        
        return @{
            Success = $true
            Path = $RecoveryPath
            Mode = if ($Temporary) { "Temporary" } else { "Permanent" }
        }
    }
    catch {
        Write-Log "TWRP installation failed: $_" "ERROR"
        Show-Message "TWRP installation failed: $_" "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

<#
.SYNOPSIS
    Gets TWRP image for RMX3939
#>
function Get-TWRPImage {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "work\downloads\twrp-rmx3939.img"
    )
    
    try {
        Write-Log "Searching for TWRP image for RMX3939..." "INFO"
        
        # Check if already downloaded
        if (Test-Path $OutputPath) {
            $choice = Show-ConfirmDialog "TWRP image already exists. Use existing file?"
            if ($choice) {
                Write-Log "Using existing TWRP image" "INFO"
                return $OutputPath
            }
        }
        
        # TWRP sources for RMX3939 (unofficial builds)
        $sources = @(
            @{
                Name = "XDA Forums"
                Url = "https://xdaforums.com/search/?q=twrp+rmx3939"
                Type = "Manual"
            },
            @{
                Name = "TWRP.me Official"
                Url = "https://twrp.me/Devices/"
                Type = "Manual"
            }
        )
        
        Show-Message "⚠️  WARNING: No official TWRP for RMX3939 found" "WARN"
        Show-Message "Unofficial TWRP builds may be available on XDA" "INFO"
        
        # Show sources
        Write-Host "`nTWRP Sources for RMX3939:" -ForegroundColor Cyan
        foreach ($source in $sources) {
            Write-Host "  • $($source.Name): $($source.Url)" -ForegroundColor Gray
        }
        
        # Manual path input
        Write-Host "`nPlease download TWRP manually and provide the path:" -ForegroundColor Yellow
        $manualPath = Read-Host "Enter path to TWRP image (or press Enter to skip)"
        
        if ($manualPath -and (Test-Path $manualPath)) {
            # Copy to work directory
            $null = New-Item -ItemType Directory -Path (Split-Path $OutputPath) -Force
            Copy-Item $manualPath $OutputPath -Force
            Write-Log "TWRP image copied to $OutputPath" "OK"
            return $OutputPath
        }
        
        Write-Log "No TWRP image provided" "WARN"
        return $null
    }
    catch {
        Write-Log "Failed to get TWRP image: $_" "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Tests if TWRP is installed
#>
function Test-TWRPInstalled {
    [CmdletBinding()]
    param()
    
    try {
        # Check if device is in recovery mode
        $adbDevices = & adb devices 2>&1 | Select-String "recovery"
        
        if ($adbDevices) {
            Write-Log "Device is in recovery mode (possibly TWRP)" "INFO"
            
            # Try to detect TWRP
            $twrpCheck = & adb shell "getprop ro.twrp.version" 2>&1
            
            if ($twrpCheck -and $twrpCheck -notmatch "error") {
                Write-Log "TWRP detected: $twrpCheck" "OK"
                return $true
            }
        }
        
        Write-Log "TWRP not detected" "INFO"
        return $false
    }
    catch {
        Write-Log "TWRP detection failed: $_" "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Searches for custom recovery builds online
#>
function Search-CustomRecovery {
    [CmdletBinding()]
    param(
        [string]$DeviceModel = "RMX3939"
    )
    
    try {
        Write-Log "Searching for custom recovery for $DeviceModel..." "INFO"
        
        $recoveryOptions = @(
            @{
                Name = "TWRP"
                OfficialUrl = "https://twrp.me/Devices/"
                XDAUrl = "https://xdaforums.com/search/?q=twrp+$DeviceModel"
                Status = "Check XDA Forums"
            },
            @{
                Name = "OrangeFox Recovery"
                OfficialUrl = "https://orangefox.download/device/$DeviceModel"
                XDAUrl = "https://xdaforums.com/search/?q=orangefox+$DeviceModel"
                Status = "Check XDA Forums"
            },
            @{
                Name = "PitchBlack Recovery (PBRP)"
                OfficialUrl = "https://pitchblackrecovery.com/$DeviceModel"
                XDAUrl = "https://xdaforums.com/search/?q=pbrp+$DeviceModel"
                Status = "Check XDA Forums"
            }
        )
        
        Write-Host "`nCustom Recovery Options for $DeviceModel`:" -ForegroundColor Cyan
        Write-Host "============================================" -ForegroundColor Cyan
        
        foreach ($recovery in $recoveryOptions) {
            Write-Host "`n$($recovery.Name):" -ForegroundColor Yellow
            Write-Host "  Official: $($recovery.OfficialUrl)" -ForegroundColor Gray
            Write-Host "  XDA Forums: $($recovery.XDAUrl)" -ForegroundColor Gray
            Write-Host "  Status: $($recovery.Status)" -ForegroundColor Magenta
        }
        
        Write-Host "`n⚠️  Note: Always verify recovery images from trusted sources!" -ForegroundColor Red
        
        return $recoveryOptions
    }
    catch {
        Write-Log "Recovery search failed: $_" "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Backs up current recovery partition
#>
function Backup-RecoveryPartition {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "work\backups\recovery-backup.img"
    )
    
    try {
        Write-Log "Backing up recovery partition..." "INFO"
        Show-Message "Creating recovery backup..." "INFO"
        
        # Ensure device is connected
        if (-not (Test-DeviceConnected)) {
            throw "Device not connected"
        }
        
        # Create backup directory
        $backupDir = Split-Path $OutputPath
        $null = New-Item -ItemType Directory -Path $backupDir -Force
        
        # Pull recovery partition via ADB
        Show-ProgressBar -Percent 50 -Status "Reading recovery partition..."
        
        $result = & adb shell "su -c 'dd if=/dev/block/by-name/recovery of=/sdcard/recovery.img'" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Pull backup to PC
            & adb pull /sdcard/recovery.img $OutputPath 2>&1 | Out-Null
            
            # Clean up
            & adb shell "rm /sdcard/recovery.img" 2>&1 | Out-Null
            
            Write-Log "Recovery backup saved to $OutputPath" "OK"
            Show-Message "Recovery backed up successfully!" "OK"
            Show-ProgressBar -Percent 100 -Status "Complete"
            
            return @{ Success = $true; Path = $OutputPath }
        }
        else {
            throw "Failed to backup recovery: $result"
        }
    }
    catch {
        Write-Log "Recovery backup failed: $_" "ERROR"
        Show-Message "Recovery backup failed: $_" "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

<#
.SYNOPSIS
    Displays recovery information and status
#>
function Show-RecoveryInfo {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          TWRP / Custom Recovery Information                   ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        
        Write-Host "`nDevice Model: " -NoNewline -ForegroundColor Yellow
        Write-Host "Realme C63 (RMX3939)" -ForegroundColor White
        
        Write-Host "`nRecovery Status:" -ForegroundColor Yellow
        $twrpInstalled = Test-TWRPInstalled
        if ($twrpInstalled) {
            Write-Host "  ✓ TWRP Detected" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ TWRP Not Detected" -ForegroundColor Red
        }
        
        Write-Host "`nAvailable Recovery Options:" -ForegroundColor Yellow
        Write-Host "  • TWRP (Team Win Recovery Project)" -ForegroundColor Gray
        Write-Host "  • OrangeFox Recovery" -ForegroundColor Gray
        Write-Host "  • PitchBlack Recovery (PBRP)" -ForegroundColor Gray
        
        Write-Host "`nOfficial TWRP Status:" -ForegroundColor Yellow
        Write-Host "  ⚠️  No official TWRP build for RMX3939" -ForegroundColor Red
        Write-Host "  ℹ️  Check XDA Forums for unofficial builds" -ForegroundColor Cyan
        
        Write-Host "`nUseful Links:" -ForegroundColor Yellow
        Write-Host "  TWRP.me: https://twrp.me/" -ForegroundColor Gray
        Write-Host "  XDA Forums: https://xdaforums.com/search/?q=twrp+rmx3939" -ForegroundColor Gray
        Write-Host "  OrangeFox: https://orangefox.download/" -ForegroundColor Gray
        
        Write-Host "`n"
    }
    catch {
        Write-Log "Failed to show recovery info: $_" "ERROR"
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Install-TWRPRecovery',
    'Get-TWRPImage',
    'Test-TWRPInstalled',
    'Search-CustomRecovery',
    'Backup-RecoveryPartition',
    'Show-RecoveryInfo'
)
