<#
.SYNOPSIS
    Root-Manager-Modul für Magisk-Installation

.DESCRIPTION
    Vollautomatische Magisk-Installation mit boot.img-Patching

.NOTES
    Author: Xylop90
    Version: 2.0.0
#>

function Install-MagiskAPK {
    <#
    .SYNOPSIS
    Installiert Magisk APK auf dem Gerät
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApkPath
    )
    
    try {
        if (-not (Test-Path $ApkPath)) {
            Write-Log -Message "Magisk APK not found: $ApkPath" -Level "ERROR" -Category "Root"
            return $false
        }
        
        Show-StatusMessage -Message "Installiere Magisk APK auf Gerät..." -Status "Processing"
        
        $adbPath = Get-ADBPath
        $output = & $adbPath install -r $ApkPath 2>&1
        
        if ($output -match "Success") {
            Show-StatusMessage -Message "Magisk APK installiert" -Status "Success"
            Write-Log -Message "Magisk APK installed successfully" -Level "INFO" -Category "Root"
            return $true
        }
        else {
            Write-Log -Message "Magisk APK installation failed: $output" -Level "ERROR" -Category "Root"
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to install Magisk APK" -ErrorRecord $_ -Category "Root"
        return $false
    }
}

function Get-BootImage {
    <#
    .SYNOPSIS
    Extrahiert boot.img aus der Firmware oder vom Gerät
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$FirmwareDirectory
    )
    
    try {
        Show-StatusMessage -Message "Suche boot.img..." -Status "Processing"
        
        # Method 1: Check firmware directory
        if ($FirmwareDirectory -and (Test-Path $FirmwareDirectory)) {
            $bootImg = Get-ChildItem -Path $FirmwareDirectory -Recurse -Filter "boot.img" -File | Select-Object -First 1
            
            if ($bootImg) {
                Show-StatusMessage -Message "boot.img in Firmware gefunden" -Status "Success"
                Copy-Item -Path $bootImg.FullName -Destination $OutputPath -Force
                Write-Log -Message "boot.img extracted from firmware" -Level "INFO" -Category "Root"
                return $true
            }
        }
        
        # Method 2: Try to extract from device (requires root or special tools)
        Show-StatusMessage -Message "Versuche boot.img vom Gerät zu extrahieren..." -Status "Processing"
        
        $adbPath = Get-ADBPath
        
        # Find boot partition
        $partitions = & $adbPath shell "ls -la /dev/block/by-name/" 2>&1
        
        if ($partitions -match "boot") {
            # Try to dump boot partition (may not work without root)
            $dumpResult = & $adbPath shell "su -c 'dd if=/dev/block/by-name/boot of=/sdcard/boot.img'" 2>&1
            
            if ($dumpResult -notmatch "error" -and $dumpResult -notmatch "denied") {
                & $adbPath pull /sdcard/boot.img $OutputPath 2>&1 | Out-Null
                & $adbPath shell "rm /sdcard/boot.img" 2>&1 | Out-Null
                
                if (Test-Path $OutputPath) {
                    Show-StatusMessage -Message "boot.img vom Gerät extrahiert" -Status "Success"
                    Write-Log -Message "boot.img extracted from device" -Level "INFO" -Category "Root"
                    return $true
                }
            }
        }
        
        # Method 3: Manual selection
        Show-StatusMessage -Message "boot.img konnte nicht automatisch gefunden werden" -Status "Warning"
        
        Write-Host ""
        Write-ColoredOutput -Message "Bitte boot.img manuell bereitstellen:" -Type "Warning"
        Write-ColoredOutput -Message "1. Laden Sie die Firmware für Ihr Gerät herunter" -Type "Info"
        Write-ColoredOutput -Message "2. Extrahieren Sie boot.img aus der Firmware" -Type "Info"
        Write-ColoredOutput -Message "3. Platzieren Sie boot.img im work/firmware/ Verzeichnis" -Type "Info"
        Write-Host ""
        
        $manualPath = Read-Host "Pfad zur boot.img eingeben (oder Enter zum Überspringen)"
        
        if ($manualPath -and (Test-Path $manualPath)) {
            Copy-Item -Path $manualPath -Destination $OutputPath -Force
            Show-StatusMessage -Message "boot.img manuell bereitgestellt" -Status "Success"
            return $true
        }
        
        Write-Log -Message "boot.img not found" -Level "ERROR" -Category "Root"
        return $false
    }
    catch {
        Write-ErrorLog -Message "Failed to get boot image" -ErrorRecord $_ -Category "Root"
        return $false
    }
}

function Invoke-MagiskPatch {
    <#
    .SYNOPSIS
    Patched boot.img mit Magisk über ADB-Automatisierung
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BootImagePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    try {
        if (-not (Test-Path $BootImagePath)) {
            Write-Log -Message "Boot image not found: $BootImagePath" -Level "ERROR" -Category "Root"
            return $null
        }
        
        Show-StatusMessage -Message "Übertrage boot.img zum Gerät..." -Status "Processing"
        
        $adbPath = Get-ADBPath
        
        # Push boot.img to device
        & $adbPath push $BootImagePath /sdcard/Download/boot.img 2>&1 | Out-Null
        
        Show-StatusMessage -Message "boot.img übertragen" -Status "Success"
        
        # Launch Magisk to patch
        Show-StatusMessage -Message "Starte Magisk zum Patchen..." -Status "Processing"
        
        Write-Host ""
        Write-ColoredOutput -Message "MANUELLE AKTION ERFORDERLICH:" -Type "Warning"
        Write-ColoredOutput -Message "1. Öffnen Sie die Magisk App auf Ihrem Gerät" -Type "Info"
        Write-ColoredOutput -Message "2. Tippen Sie auf 'Installieren' neben Magisk" -Type "Info"
        Write-ColoredOutput -Message "3. Wählen Sie 'Datei auswählen und patchen'" -Type "Info"
        Write-ColoredOutput -Message "4. Wählen Sie die boot.img aus Download-Ordner" -Type "Info"
        Write-ColoredOutput -Message "5. Warten Sie bis Magisk das Patching abgeschlossen hat" -Type "Info"
        Write-ColoredOutput -Message "6. Die gepatchte Datei heißt 'magisk_patched_*.img'" -Type "Info"
        Write-Host ""
        
        $confirm = Show-Confirmation -Message "Haben Sie das Patching abgeschlossen?" -DefaultYes $false
        
        if (-not $confirm) {
            Write-Log -Message "Magisk patching cancelled by user" -Level "INFO" -Category "Root"
            return $null
        }
        
        # Pull patched boot.img
        Show-StatusMessage -Message "Hole gepatchte boot.img vom Gerät..." -Status "Processing"
        
        # List files to find patched image
        $files = & $adbPath shell "ls /sdcard/Download/magisk_patched*.img" 2>&1
        
        if ($files -and $files -notmatch "No such file") {
            $patchedFileName = Split-Path $files -Leaf
            $patchedPath = Join-Path $OutputDirectory $patchedFileName
            
            & $adbPath pull "/sdcard/Download/$patchedFileName" $patchedPath 2>&1 | Out-Null
            
            if (Test-Path $patchedPath) {
                Show-StatusMessage -Message "Gepatchte boot.img heruntergeladen" -Status "Success"
                Write-Log -Message "Magisk-patched boot.img: $patchedPath" -Level "INFO" -Category "Root"
                return $patchedPath
            }
        }
        
        Write-Log -Message "Could not find patched boot.img" -Level "ERROR" -Category "Root"
        return $null
    }
    catch {
        Write-ErrorLog -Message "Failed to patch boot image" -ErrorRecord $_ -Category "Root"
        return $null
    }
}

function Install-PatchedBoot {
    <#
    .SYNOPSIS
    Flasht die gepatchte boot.img via Fastboot
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatchedBootPath
    )
    
    try {
        if (-not (Test-Path $PatchedBootPath)) {
            Write-Log -Message "Patched boot image not found: $PatchedBootPath" -Level "ERROR" -Category "Root"
            return $false
        }
        
        Show-StatusMessage -Message "Starte Gerät in Bootloader-Modus..." -Status "Processing"
        
        $adbPath = Get-ADBPath
        & $adbPath reboot bootloader 2>&1 | Out-Null
        
        Start-Sleep -Seconds 10
        
        # Wait for fastboot
        $fastbootPath = Get-FastbootPath
        $timeout = 30
        $found = $false
        
        for ($i = 0; $i -lt $timeout; $i++) {
            $devices = & $fastbootPath devices 2>&1
            if ($devices -match "\s+fastboot") {
                $found = $true
                break
            }
            Start-Sleep -Seconds 1
        }
        
        if (-not $found) {
            Write-Log -Message "Device not found in fastboot mode" -Level "ERROR" -Category "Root"
            return $false
        }
        
        Show-StatusMessage -Message "Flashe gepatchte boot.img..." -Status "Processing"
        
        $flashOutput = & $fastbootPath flash boot $PatchedBootPath 2>&1
        
        Write-Log -Message "Flash output: $flashOutput" -Level "DEBUG" -Category "Root"
        
        if ($flashOutput -match "OKAY" -or $flashOutput -match "Finished") {
            Show-StatusMessage -Message "boot.img erfolgreich geflasht" -Status "Success"
            
            # Reboot
            Show-StatusMessage -Message "Starte Gerät neu..." -Status "Processing"
            & $fastbootPath reboot 2>&1 | Out-Null
            
            Write-Log -Message "Patched boot.img flashed successfully" -Level "INFO" -Category "Root"
            return $true
        }
        else {
            Write-Log -Message "Flash failed: $flashOutput" -Level "ERROR" -Category "Root"
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to flash patched boot" -ErrorRecord $_ -Category "Root"
        return $false
    }
}

function Test-RootStatus {
    <#
    .SYNOPSIS
    Überprüft ob das Gerät gerootet ist
    #>
    [CmdletBinding()]
    param()
    
    try {
        Show-StatusMessage -Message "Prüfe Root-Status..." -Status "Processing"
        
        $adbPath = Get-ADBPath
        
        # Wait for device to boot
        Show-StatusMessage -Message "Warte auf Geräte-Start..." -Status "Processing"
        & $adbPath wait-for-device 2>&1 | Out-Null
        Start-Sleep -Seconds 20
        
        # Test root access
        $suTest = & $adbPath shell "su -c 'id'" 2>&1
        
        if ($suTest -match "uid=0") {
            Show-StatusMessage -Message "Root-Zugriff bestätigt!" -Status "Success"
            Write-Log -Message "Root access verified" -Level "INFO" -Category "Root"
            return $true
        }
        
        # Check Magisk app
        $magiskCheck = & $adbPath shell "pm list packages" 2>&1 | Select-String "com.topjohnwu.magisk"
        
        if ($magiskCheck) {
            Show-StatusMessage -Message "Magisk App gefunden, Root möglicherweise aktiv" -Status "Success"
            Write-Log -Message "Magisk app found" -Level "INFO" -Category "Root"
            return $true
        }
        
        Show-StatusMessage -Message "Kein Root-Zugriff erkannt" -Status "Warning"
        Write-Log -Message "Root access not detected" -Level "WARNING" -Category "Root"
        return $false
    }
    catch {
        Write-ErrorLog -Message "Failed to test root status" -ErrorRecord $_ -Category "Root"
        return $false
    }
}

function Start-RootProcess {
    <#
    .SYNOPSIS
    Hauptfunktion für den gesamten Root-Prozess
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkDirectory
    )
    
    try {
        Show-StepBanner -Step "ROOT-INSTALLATION (MAGISK)" -Description "Vollautomatische Magisk-Installation"
        
        $toolsDir = Join-Path $WorkDirectory "tools"
        $firmwareDir = Join-Path $WorkDirectory "firmware"
        $magiskDir = Join-Path $toolsDir "magisk"
        
        # Step 1: Get Magisk APK
        $magiskApk = Get-ChildItem -Path $magiskDir -Filter "Magisk-*.apk" -File | Select-Object -First 1
        
        if (-not $magiskApk) {
            Show-ErrorBox -Title "Magisk nicht gefunden" `
                -Message "Magisk APK konnte nicht gefunden werden" `
                -Details @("Bitte installieren Sie zuerst alle Tools")
            return $false
        }
        
        # Step 2: Install Magisk APK
        $success = Install-MagiskAPK -ApkPath $magiskApk.FullName
        if (-not $success) { return $false }
        
        # Step 3: Get boot.img
        $bootImgPath = Join-Path $firmwareDir "boot.img"
        $success = Get-BootImage -OutputPath $bootImgPath -FirmwareDirectory $firmwareDir
        if (-not $success) { return $false }
        
        # Step 4: Patch boot.img with Magisk
        $patchedBootPath = Invoke-MagiskPatch -BootImagePath $bootImgPath -OutputDirectory $firmwareDir
        if (-not $patchedBootPath) { return $false }
        
        # Step 5: Flash patched boot.img
        $success = Install-PatchedBoot -PatchedBootPath $patchedBootPath
        if (-not $success) { return $false }
        
        # Step 6: Verify root
        $isRooted = Test-RootStatus
        
        if ($isRooted) {
            Show-StatusMessage -Message "Root-Installation erfolgreich abgeschlossen!" -Status "Complete"
            Write-Log -Message "Root process completed successfully" -Level "INFO" -Category "Root"
            return $true
        }
        else {
            Show-ErrorBox -Title "Root-Verifikation fehlgeschlagen" `
                -Message "Root-Zugriff konnte nicht verifiziert werden" `
                -Details @(
                "Das Gerät wurde möglicherweise nicht korrekt gerootet",
                "Öffnen Sie die Magisk App und prüfen Sie den Status",
                "Ein Neustart des Geräts kann helfen"
            )
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "Root process failed" -ErrorRecord $_ -Category "Root"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Install-MagiskAPK',
    'Get-BootImage',
    'Invoke-MagiskPatch',
    'Install-PatchedBoot',
    'Test-RootStatus',
    'Start-RootProcess'
)
