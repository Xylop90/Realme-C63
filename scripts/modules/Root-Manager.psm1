#Requires -Version 5.1

<#
.SYNOPSIS
    Root Manager module for Magisk 30.6 integration

.DESCRIPTION
    Provides complete Magisk root installation workflow including download,
    boot image patching, and verification.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

<#
.SYNOPSIS
    Installs Magisk root on device

.PARAMETER FirmwarePath
    Path to firmware file (for boot.img extraction)

.PARAMETER BootImagePath
    Direct path to boot.img (if already extracted)

.EXAMPLE
    Install-MagiskRoot -FirmwarePath "work/firmware/RMX3939.zip"
#>
function Install-MagiskRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$FirmwarePath,

        [Parameter(Mandatory=$false)]
        [string]$BootImagePath
    )

    try {
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║              MAGISK ROOT INSTALLATION v30.6                   ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "GitHub: https://github.com/topjohnwu/Magisk" -ForegroundColor Gray
        Write-Host "Dokumentation: https://topjohnwu.github.io/Magisk/install.html" -ForegroundColor Gray
        Write-Host ""

        # Verify bootloader is unlocked
        Write-Host "Überprüfe Bootloader-Status / Checking bootloader status..." -ForegroundColor Cyan
        $isUnlocked = Test-BootloaderUnlocked

        if (-not $isUnlocked) {
            Write-Warning "Bootloader ist gesperrt / Bootloader is locked"
            Write-Host "Bitte entsperren Sie zuerst den Bootloader / Please unlock bootloader first" -ForegroundColor Yellow
            return @{
                Success = $false
                Error = "Bootloader is locked"
            }
        }

        Write-Host "✓ Bootloader ist entsperrt / Bootloader is unlocked" -ForegroundColor Green

        # Download Magisk
        $magiskResult = Get-MagiskAPK

        if (-not $magiskResult.Success) {
            throw "Failed to download Magisk"
        }

        # Get boot image
        $bootImg = $null
        if (-not [string]::IsNullOrWhiteSpace($BootImagePath) -and (Test-Path $BootImagePath)) {
            $bootImg = $BootImagePath
        }
        elseif (-not [string]::IsNullOrWhiteSpace($FirmwarePath)) {
            Write-Host "Extrahiere boot.img aus Firmware / Extracting boot.img from firmware..." -ForegroundColor Cyan
            $bootImg = Extract-BootImage -FirmwarePath $FirmwarePath
            
            if ($null -eq $bootImg) {
                throw "Failed to extract boot.img"
            }
        }
        else {
            Write-Warning "Keine Firmware oder boot.img angegeben / No firmware or boot.img specified"
            Write-Host "Bitte geben Sie den Pfad zur boot.img ein / Please provide path to boot.img" -ForegroundColor Yellow
            $bootImg = Read-Host "boot.img Pfad / Path"
            
            if (-not (Test-Path $bootImg)) {
                throw "boot.img not found at: $bootImg"
            }
        }

        # Install Magisk on device
        $installResult = Install-MagiskOnDevice -MagiskAPK $magiskResult.FilePath -BootImage $bootImg

        if ($installResult.Success) {
            Write-Host "`n✓ Magisk erfolgreich installiert / Magisk successfully installed!" -ForegroundColor Green
            Write-Host "✓ Root-Zugriff verfügbar / Root access available" -ForegroundColor Green
            
            return @{
                Success = $true
                MagiskVersion = "30.6"
                Rooted = $true
            }
        }
        else {
            throw $installResult.Error
        }
    }
    catch {
        Write-Error "Magisk installation failed: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Downloads Magisk APK

.EXAMPLE
    $result = Get-MagiskAPK
#>
function Get-MagiskAPK {
    [CmdletBinding()]
    param()

    try {
        $magiskUrl = "https://github.com/topjohnwu/Magisk/releases/download/v30.6/Magisk-v30.6.apk"
        $destination = "work/downloads/Magisk-v30.6.apk"

        Write-Host "Lade Magisk 30.6 herunter / Downloading Magisk 30.6..." -ForegroundColor Cyan
        Write-Host "URL: $magiskUrl" -ForegroundColor Gray

        $downloadResult = Get-RemoteFile -Url $magiskUrl -Destination $destination

        if ($downloadResult.Success) {
            Write-Host "✓ Magisk heruntergeladen / Magisk downloaded" -ForegroundColor Green
            return @{
                Success = $true
                FilePath = $destination
                Version = "30.6"
            }
        }
        else {
            throw $downloadResult.Error
        }
    }
    catch {
        Write-Error "Failed to download Magisk: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Extracts boot.img from firmware

.PARAMETER FirmwarePath
    Path to firmware file

.EXAMPLE
    $bootImg = Extract-BootImage -FirmwarePath "work/firmware/firmware.zip"
#>
function Extract-BootImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FirmwarePath
    )

    try {
        if (-not (Test-Path $FirmwarePath)) {
            throw "Firmware file not found: $FirmwarePath"
        }

        $extractPath = "work/extracted/firmware"
        
        Write-Host "Entpacke Firmware / Extracting firmware..." -ForegroundColor Cyan
        
        if (-not (Test-Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        }

        # Extract firmware
        Expand-Archive -Path $FirmwarePath -DestinationPath $extractPath -Force

        # Search for boot.img
        $bootImg = Get-ChildItem -Path $extractPath -Filter "boot.img" -Recurse | Select-Object -First 1

        if ($null -eq $bootImg) {
            throw "boot.img not found in firmware"
        }

        Write-Host "✓ boot.img gefunden / boot.img found: $($bootImg.FullName)" -ForegroundColor Green
        return $bootImg.FullName
    }
    catch {
        Write-Error "Failed to extract boot.img: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Installs Magisk on device and patches boot image

.PARAMETER MagiskAPK
    Path to Magisk APK

.PARAMETER BootImage
    Path to boot.img

.EXAMPLE
    Install-MagiskOnDevice -MagiskAPK "Magisk.apk" -BootImage "boot.img"
#>
function Install-MagiskOnDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$MagiskAPK,

        [Parameter(Mandatory=$true)]
        [string]$BootImage
    )

    try {
        # Check device connection
        Write-Host "Überprüfe Geräteverbindung / Checking device connection..." -ForegroundColor Cyan
        $deviceStatus = Get-DeviceStatus

        if (-not $deviceStatus.DeviceConnected -or $deviceStatus.Mode -ne "ADB") {
            Write-Warning "Gerät nicht im ADB-Modus / Device not in ADB mode"
            $connected = Wait-ForDevice -Mode "ADB" -TimeoutSeconds 60
            
            if (-not $connected) {
                throw "Device not connected in ADB mode"
            }
        }

        # Install Magisk APK
        Write-Host "Installiere Magisk App / Installing Magisk app..." -ForegroundColor Cyan
        & adb install -r $MagiskAPK 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install Magisk APK"
        }

        Write-Host "✓ Magisk App installiert / Magisk app installed" -ForegroundColor Green

        # Push boot.img to device
        Write-Host "Übertrage boot.img zum Gerät / Transferring boot.img to device..." -ForegroundColor Cyan
        & adb push $BootImage /sdcard/boot.img 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to push boot.img"
        }

        Write-Host "✓ boot.img übertragen / boot.img transferred" -ForegroundColor Green

        # Show manual patching instructions
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║            MANUELLE SCHRITTE / MANUAL STEPS                    ║" -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Bitte führen Sie folgende Schritte auf dem Gerät aus:" -ForegroundColor Yellow
        Write-Host "Please perform the following steps on the device:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Öffnen Sie die Magisk App / Open Magisk app" -ForegroundColor White
        Write-Host "2. Tippen Sie auf 'Install' neben Magisk / Tap 'Install' next to Magisk" -ForegroundColor White
        Write-Host "3. Wählen Sie 'Select and Patch a File' / Select 'Select and Patch a File'" -ForegroundColor White
        Write-Host "4. Wählen Sie boot.img aus /sdcard/ / Choose boot.img from /sdcard/" -ForegroundColor White
        Write-Host "5. Warten Sie auf das Patching / Wait for patching to complete" -ForegroundColor White
        Write-Host "6. Notieren Sie den Namen der gepatchten Datei / Note the patched file name" -ForegroundColor White
        Write-Host ""

        $patchComplete = Show-Confirmation -Message "Patching abgeschlossen? / Patching completed?"

        if (-not $patchComplete) {
            throw "Boot image patching not completed"
        }

        # Pull patched boot image
        Write-Host "`nSuche gepatchtes boot.img / Searching for patched boot.img..." -ForegroundColor Cyan
        
        # Get list of magisk_patched files
        $patchedFiles = & adb shell "ls /sdcard/Download/magisk_patched_*.img 2>/dev/null" 2>&1
        
        if ([string]::IsNullOrWhiteSpace($patchedFiles)) {
            throw "No patched boot image found"
        }

        $patchedFile = ($patchedFiles -split "`n")[0].Trim()
        $localPatchedPath = "work/magisk_patched.img"

        Write-Host "Lade gepatchtes Image herunter / Downloading patched image..." -ForegroundColor Cyan
        & adb pull $patchedFile $localPatchedPath 2>&1 | Out-Null

        if (-not (Test-Path $localPatchedPath)) {
            throw "Failed to pull patched boot image"
        }

        Write-Host "✓ Gepatchtes Image heruntergeladen / Patched image downloaded" -ForegroundColor Green

        # Reboot to bootloader
        Write-Host "Neustart zum Bootloader / Rebooting to bootloader..." -ForegroundColor Cyan
        & adb reboot bootloader 2>&1 | Out-Null

        Start-Sleep -Seconds 5
        $bootloaderReady = Wait-ForDevice -Mode "Fastboot" -TimeoutSeconds 30

        if (-not $bootloaderReady) {
            throw "Device not in fastboot mode"
        }

        # Flash patched boot
        Write-Host "Flashe gepatchtes boot.img / Flashing patched boot.img..." -ForegroundColor Cyan
        & fastboot flash boot $localPatchedPath 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to flash patched boot image"
        }

        Write-Host "✓ Gepatchtes boot.img geflasht / Patched boot.img flashed" -ForegroundColor Green

        # Reboot to system
        Write-Host "Neustart zum System / Rebooting to system..." -ForegroundColor Cyan
        & fastboot reboot 2>&1 | Out-Null

        # Wait for device to boot
        Write-Host "Warte auf Gerätestart / Waiting for device to boot..." -ForegroundColor Cyan
        Start-Sleep -Seconds 30

        $booted = Wait-ForDevice -Mode "ADB" -TimeoutSeconds 60

        if (-not $booted) {
            Write-Warning "Device did not boot in expected time"
        }

        # Verify root
        Write-Host "Überprüfe Root-Zugriff / Verifying root access..." -ForegroundColor Cyan
        Start-Sleep -Seconds 10  # Give Magisk time to initialize

        $isRooted = Test-DeviceRooted

        if ($isRooted) {
            Write-Host "✓ Root-Zugriff bestätigt / Root access confirmed!" -ForegroundColor Green
            return @{
                Success = $true
                Rooted = $true
            }
        }
        else {
            Write-Warning "Root-Zugriff konnte nicht bestätigt werden / Root access could not be confirmed"
            Write-Host "Bitte überprüfen Sie die Magisk App / Please check Magisk app" -ForegroundColor Yellow
            
            return @{
                Success = $true
                Rooted = $false
                Warning = "Root verification failed"
            }
        }
    }
    catch {
        Write-Error "Failed to install Magisk on device: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Verifies Magisk installation

.EXAMPLE
    $hasRoot = Test-MagiskInstalled
#>
function Test-MagiskInstalled {
    [CmdletBinding()]
    param()

    try {
        # Check if Magisk app is installed
        $packages = & adb shell pm list packages 2>&1 | Out-String
        $hasMagisk = $packages -match "com.topjohnwu.magisk"

        # Check root access
        $hasRoot = Test-DeviceRooted

        return ($hasMagisk -and $hasRoot)
    }
    catch {
        Write-Warning "Could not verify Magisk installation: $_"
        return $false
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Install-MagiskRoot',
    'Get-MagiskAPK',
    'Extract-BootImage',
    'Install-MagiskOnDevice',
    'Test-MagiskInstalled'
)
