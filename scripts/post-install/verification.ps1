#Requires -Version 5.1
<#
.SYNOPSIS
    Verifizierung der Installation für Realme C63
    
.DESCRIPTION
    Prüft ob alle Komponenten erfolgreich installiert wurden
    
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

# Initialisiere Logger falls nicht bereits initialisiert
if (-not $Script:LogFile) {
    Initialize-Logger -LogDirectory "$WorkingDirectory\logs" -Level "INFO"
}

Write-LogSection "Installations-Verifizierung gestartet"

# ============================================================================
# VERIFIZIERUNGS-TESTS
# ============================================================================

function Test-ADBInstallation {
    <#
    .SYNOPSIS
    Prüft ADB Installation
    #>
    
    Write-LogInfo "Prüfe ADB Installation..."
    
    $adbPath = Join-Path $WorkingDirectory "work\platform-tools\adb.exe"
    
    if (Test-Path $adbPath) {
        try {
            $version = & $adbPath version 2>&1 | Select-Object -First 1
            Write-LogInfo "✅ ADB gefunden: $version"
            return $true
        }
        catch {
            Write-LogWarning "❌ ADB gefunden, aber nicht ausführbar"
            return $false
        }
    }
    else {
        Write-LogWarning "❌ ADB nicht gefunden"
        return $false
    }
}

function Test-DriversInstalled {
    <#
    .SYNOPSIS
    Prüft Treiber Installation
    #>
    
    Write-LogInfo "Prüfe Treiber Installation..."
    
    $drivers = Get-WindowsDriver -Online | Where-Object {
        $_.ProviderName -like "*Spreadtrum*" -or 
        $_.ProviderName -like "*Realme*" -or
        $_.ProviderName -like "*Unisoc*"
    }
    
    if ($drivers) {
        Write-LogInfo "✅ Treiber installiert: $($drivers.Count) gefunden"
        foreach ($driver in $drivers) {
            Write-LogDebug "  - $($driver.ProviderName): $($driver.ClassName)"
        }
        return $true
    }
    else {
        Write-LogWarning "❌ Keine Realme/SPD-Treiber gefunden"
        return $false
    }
}

function Test-FirmwareAvailable {
    <#
    .SYNOPSIS
    Prüft Firmware Verfügbarkeit
    #>
    
    Write-LogInfo "Prüfe Firmware Verfügbarkeit..."
    
    $firmwareDir = Join-Path $WorkingDirectory "firmware"
    $firmwareFiles = Get-ChildItem -Path $firmwareDir -Include @("*.pac", "*.zip", "*.tar") -Recurse -ErrorAction SilentlyContinue
    
    if ($firmwareFiles) {
        Write-LogInfo "✅ Firmware gefunden: $($firmwareFiles[0].Name)"
        Write-LogDebug "  Größe: $([math]::Round($firmwareFiles[0].Length / 1GB, 2)) GB"
        return $true
    }
    else {
        Write-LogWarning "❌ Keine Firmware-Dateien gefunden"
        return $false
    }
}

function Test-DeviceConnection {
    <#
    .SYNOPSIS
    Prüft Geräteverbindung
    #>
    
    Write-LogInfo "Prüfe Geräteverbindung..."
    
    $adbPath = Join-Path $WorkingDirectory "work\platform-tools\adb.exe"
    
    if (-not (Test-Path $adbPath)) {
        Write-LogWarning "❌ ADB nicht verfügbar"
        return $false
    }
    
    try {
        & $adbPath start-server 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        $devices = & $adbPath devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
        
        if ($devices) {
            Write-LogInfo "✅ Gerät verbunden"
            
            # Hole Geräteinfo
            $model = (& $adbPath shell getprop ro.product.model 2>&1).Trim()
            Write-LogInfo "  Model: $model"
            
            return $true
        }
        else {
            Write-LogWarning "⚠️  Kein Gerät verbunden"
            Write-LogInfo "  (Optional - Gerät muss nicht verbunden sein)"
            return $true  # Nicht kritisch
        }
    }
    catch {
        Write-LogWarning "❌ Fehler bei Geräte-Prüfung: $($_.Exception.Message)"
        return $false
    }
}

function Test-ConfigurationFiles {
    <#
    .SYNOPSIS
    Prüft Konfigurationsdateien
    #>
    
    Write-LogInfo "Prüfe Konfigurationsdateien..."
    
    $configDir = Join-Path $WorkingDirectory "config"
    $requiredConfigs = @(
        "downloads.json",
        "device-mappings.json"
    )
    
    $allFound = $true
    foreach ($config in $requiredConfigs) {
        $path = Join-Path $configDir $config
        if (Test-Path $path) {
            Write-LogInfo "✅ $config gefunden"
        }
        else {
            Write-LogWarning "❌ $config fehlt"
            $allFound = $false
        }
    }
    
    return $allFound
}

function Test-DirectoryStructure {
    <#
    .SYNOPSIS
    Prüft Verzeichnisstruktur
    #>
    
    Write-LogInfo "Prüfe Verzeichnisstruktur..."
    
    $requiredDirs = @(
        "config",
        "work",
        "logs",
        "backup",
        "firmware",
        "docs",
        "scripts"
    )
    
    $allFound = $true
    foreach ($dir in $requiredDirs) {
        $path = Join-Path $WorkingDirectory $dir
        if (Test-Path $path) {
            Write-LogDebug "✅ $dir existiert"
        }
        else {
            Write-LogWarning "❌ $dir fehlt"
            $allFound = $false
        }
    }
    
    return $allFound
}

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

function Show-VerificationSummary {
    <#
    .SYNOPSIS
    Zeigt Verifizierungs-Zusammenfassung
    #>
    param([hashtable]$Results)
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              INSTALLATIONS-VERIFIZIERUNG ABGESCHLOSSEN             ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Ergebnisse:" -ForegroundColor White
    Write-Host ""
    
    $passCount = 0
    $totalCount = $Results.Count
    
    foreach ($key in $Results.Keys) {
        $icon = if ($Results[$key]) { "✅" } else { "❌" }
        $color = if ($Results[$key]) { "Green" } else { "Red" }
        
        Write-Host "  $icon $key" -ForegroundColor $color
        
        if ($Results[$key]) {
            $passCount++
        }
    }
    
    Write-Host ""
    Write-Host "Gesamt: $passCount/$totalCount Tests bestanden" -ForegroundColor $(if ($passCount -eq $totalCount) { "Green" } else { "Yellow" })
    Write-Host ""
    
    if ($passCount -eq $totalCount) {
        Write-Host "🎉 Installation vollständig verifiziert!" -ForegroundColor Green
    }
    elseif ($passCount -ge ($totalCount * 0.7)) {
        Write-Host "⚠️  Installation größtenteils erfolgreich" -ForegroundColor Yellow
        Write-Host "   Einige optionale Komponenten fehlen" -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ Installation unvollständig" -ForegroundColor Red
        Write-Host "   Bitte prüfen Sie die Logs" -ForegroundColor Red
    }
    
    Write-Host ""
}

# ============================================================================
# HAUPTAUSFÜHRUNG
# ============================================================================

function Start-Verification {
    try {
        Write-LogInfo "Arbeitsverzeichnis: $WorkingDirectory"
        Write-Host ""
        
        # Führe Tests durch
        $results = @{
            "Verzeichnisstruktur" = Test-DirectoryStructure
            "Konfigurationsdateien" = Test-ConfigurationFiles
            "ADB Installation" = Test-ADBInstallation
            "Treiber Installation" = Test-DriversInstalled
            "Firmware Verfügbarkeit" = Test-FirmwareAvailable
            "Geräteverbindung" = Test-DeviceConnection
        }
        
        # Zeige Zusammenfassung
        Show-VerificationSummary -Results $results
        
        # Bestimme Erfolg
        $passCount = ($results.Values | Where-Object { $_ -eq $true }).Count
        $totalCount = $results.Count
        
        # Mindestens 70% müssen bestehen
        $success = $passCount -ge ($totalCount * 0.7)
        
        return $success
    }
    catch {
        Write-LogError "Fehler bei Verifizierung: $($_.Exception.Message)"
        Write-LogError $_.ScriptStackTrace
        return $false
    }
}

# Führe Verifizierung aus
$result = Start-Verification
exit $(if ($result) { 0 } else { 1 })
