#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Master Installer - Haupt-Orchestrierung für Realme C63 Installation
    
.DESCRIPTION
    Vollautomatisches Zero-Touch Installations-System für Realme C63 (RMX3939)
    - Automatische Verzeichnis- und Config-Erstellung
    - Tool-Download und Installation
    - Treiber-Installation
    - Firmware-Download
    - SPD Flash Automation
    - Logging und Dokumentation
    
.PARAMETER WorkingDirectory
    Arbeitsverzeichnis (Standard: Aktuelles Verzeichnis)
    
.PARAMETER ZeroTouch
    Zero-Touch Modus ohne Benutzer-Prompts
    
.PARAMETER SkipDrivers
    Überspringe Treiber-Installation
    
.PARAMETER SkipFirmware
    Überspringe Firmware-Download
    
.NOTES
    Author: Elektronikx-Center-Matte by Alexander Mathey
    Version: 1.0.0
    Date: 2026-01-10
#>

param(
    [string]$WorkingDirectory = $PSScriptRoot,
    [switch]$ZeroTouch,
    [switch]$SkipDrivers,
    [switch]$SkipFirmware
)

# ============================================================================
# INITIALISIERUNG
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Wechsle zu Root-Verzeichnis
if ($WorkingDirectory -like "*scripts*") {
    $WorkingDirectory = Split-Path (Split-Path $WorkingDirectory -Parent) -Parent
}
Set-Location $WorkingDirectory

# Importiere Module
. "$WorkingDirectory\scripts\lib\logger.ps1"
. "$WorkingDirectory\scripts\lib\downloader.ps1"
. "$WorkingDirectory\scripts\lib\registry-manager.ps1"
. "$WorkingDirectory\scripts\lib\ui-automation.ps1"

# Initialisiere Logger
Initialize-Logger -LogDirectory "$WorkingDirectory\logs" -Level "INFO"

# ============================================================================
# KONFIGURATION
# ============================================================================

$Script:Config = @{
    Version = "1.0.0"
    DeviceModel = "Realme C63"
    DeviceCodename = "RMX3939"
    WorkingDir = $WorkingDirectory
    Paths = @{
        Root = $WorkingDirectory
        Scripts = Join-Path $WorkingDirectory "scripts"
        Config = Join-Path $WorkingDirectory "config"
        Work = Join-Path $WorkingDirectory "work"
        Logs = Join-Path $WorkingDirectory "logs"
        Backup = Join-Path $WorkingDirectory "backup"
        Firmware = Join-Path $WorkingDirectory "firmware"
        Docs = Join-Path $WorkingDirectory "docs"
    }
    URLs = @{
        PlatformTools = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
        SPDDriver = "https://androidmtk.com/download-spreadtrum-driver"
        SPDFlashTool = "https://spdflashtool.com/download/latest"
        FirmwareDB = "https://realme-firmware-db.com/api/search"
    }
}

# ============================================================================
# BANNER
# ============================================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "║     REALME C63 (RMX3939) - VOLLAUTOMATISCHE INSTALLATION          ║" -ForegroundColor Cyan
    Write-Host "║                   Zero-Touch Windows 11 System                     ║" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "║           Version $($Script:Config.Version)                                      ║" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Copyright © 2026 Elektronikx-Center-Matte by Alexander Mathey" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# VERZEICHNISSTRUKTUR ERSTELLEN
# ============================================================================

function Initialize-DirectoryStructure {
    Write-LogSection "Verzeichnisstruktur wird erstellt"
    
    foreach ($path in $Script:Config.Paths.Values) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            Write-LogInfo "Erstellt: $path"
        }
        else {
            Write-LogDebug "Existiert bereits: $path"
        }
    }
    
    Write-LogInfo "Verzeichnisstruktur vollständig"
    return $true
}

# ============================================================================
# CONFIG-GENERIERUNG
# ============================================================================

function Initialize-Configuration {
    Write-LogSection "Konfiguration wird generiert"
    
    $downloadsConfig = @{
        version = "1.0"
        generated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        tools = @{
            platformTools = @{
                name = "Android Platform Tools"
                url = $Script:Config.URLs.PlatformTools
                filename = "platform-tools.zip"
                hash = ""
            }
            spdDriver = @{
                name = "SPD/Unisoc USB Driver"
                url = $Script:Config.URLs.SPDDriver
                filename = "spd-driver.zip"
                hash = ""
            }
            spdFlashTool = @{
                name = "SPD Flash Tool"
                url = $Script:Config.URLs.SPDFlashTool
                filename = "spd-flash-tool.zip"
                hash = ""
            }
        }
        firmware = @{
            sources = @(
                "https://realme-updates.com/",
                "https://realmefirmware.com/",
                "https://www.getdroidtips.com/"
            )
        }
    }
    
    $configPath = Join-Path $Script:Config.Paths.Config "downloads.json"
    $downloadsConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
    Write-LogInfo "Config generiert: $configPath"
    
    # Device Mappings
    $deviceMappings = @{
        version = "1.0"
        devices = @{
            RMX3939 = @{
                name = "Realme C63"
                usbVid = "0x2207"
                usbPid = @("0x0006", "0x0010")
                chipset = "Unisoc T612"
                firmwarePattern = "*RMX3939*"
            }
        }
    }
    
    $mappingsPath = Join-Path $Script:Config.Paths.Config "device-mappings.json"
    $deviceMappings | ConvertTo-Json -Depth 10 | Out-File -FilePath $mappingsPath -Encoding UTF8
    Write-LogInfo "Device-Mappings generiert: $mappingsPath"
    
    return $true
}

# ============================================================================
# SYSTEMVORBEREITUNG
# ============================================================================

function Initialize-SystemPreparation {
    Write-LogSection "System wird vorbereitet"
    
    # Windows Developer Mode aktivieren
    Write-LogInfo "Aktiviere Windows Developer Mode..."
    Enable-DeveloperMode | Out-Null
    
    # Test-Signing aktivieren (temporär)
    Write-LogInfo "Aktiviere Test-Signing für Treiber-Installation..."
    Enable-TestSigning | Out-Null
    
    # Windows Defender Ausnahmen
    Write-LogInfo "Füge Windows Defender Ausnahmen hinzu..."
    Add-WindowsDefenderExclusion -Path $Script:Config.Paths.Work
    Add-WindowsDefenderExclusion -Path $Script:Config.Paths.Firmware
    
    # Realme USB Registry
    Write-LogInfo "Bereite USB-Registry vor..."
    Set-RealmUSBRegistry
    
    Write-LogInfo "Systemvorbereitung abgeschlossen"
    Write-LogWarning "HINWEIS: Neustart kann erforderlich sein für Test-Signing"
    
    return $true
}

# ============================================================================
# TOOL-DOWNLOAD
# ============================================================================

function Install-RequiredTools {
    Write-LogSection "Erforderliche Tools werden geladen"
    
    $workDir = $Script:Config.Paths.Work
    
    # Android Platform Tools
    Write-LogInfo "Lade Android Platform Tools..."
    $adbZip = Join-Path $workDir "platform-tools.zip"
    $adbDir = Join-Path $workDir "platform-tools"
    
    if (-not (Test-Path "$adbDir\adb.exe")) {
        if (Invoke-DownloadWithRetry -Url $Script:Config.URLs.PlatformTools -Destination $adbZip) {
            Expand-ArchiveWithProgress -ArchivePath $adbZip -DestinationPath $workDir -Force
            Write-LogInfo "Platform Tools installiert: $adbDir"
            
            # Firewall-Regeln hinzufügen
            Add-FirewallRule -Name "ADB Server" -Program "$adbDir\adb.exe"
        }
    }
    else {
        Write-LogInfo "Platform Tools bereits vorhanden"
    }
    
    # 7-Zip CLI für Entpacken
    Get-Download7Zip -TargetPath $workDir | Out-Null
    
    Write-LogInfo "Tool-Installation abgeschlossen"
    return $true
}

# ============================================================================
# GERÄTE-ERKENNUNG
# ============================================================================

function Test-DeviceConnection {
    Write-LogSection "Gerät wird gesucht"
    
    $adbExe = Join-Path $Script:Config.Paths.Work "platform-tools\adb.exe"
    
    if (-not (Test-Path $adbExe)) {
        Write-LogWarning "ADB nicht verfügbar"
        return $false
    }
    
    # Starte ADB Server
    & $adbExe start-server 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    
    # Prüfe Geräte
    $devices = & $adbExe devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
    
    if ($devices) {
        Write-LogInfo "Gerät gefunden!"
        
        # Hole Geräteinformationen
        $model = & $adbExe shell getprop ro.product.model 2>&1
        $version = & $adbExe shell getprop ro.build.version.release 2>&1
        
        Write-LogInfo "Model: $model"
        Write-LogInfo "Android: $version"
        
        return $true
    }
    else {
        Write-LogWarning "Kein Gerät gefunden"
        Write-LogInfo "Bitte verbinden Sie das Gerät und aktivieren Sie USB-Debugging"
        return $false
    }
}

# ============================================================================
# HAUPTABLAUF
# ============================================================================

function Start-Installation {
    try {
        Show-Banner
        
        Write-LogSection "Installation gestartet"
        Write-LogInfo "Arbeitsverzeichnis: $($Script:Config.WorkingDir)"
        Write-LogInfo "Modus: $(if ($ZeroTouch) { 'Zero-Touch' } else { 'Interaktiv' })"
        
        # Phase 1: Verzeichnisstruktur
        if (-not (Initialize-DirectoryStructure)) {
            throw "Fehler beim Erstellen der Verzeichnisstruktur"
        }
        
        # Phase 2: Konfiguration
        if (-not (Initialize-Configuration)) {
            throw "Fehler beim Generieren der Konfiguration"
        }
        
        # Phase 3: Systemvorbereitung
        if (-not (Initialize-SystemPreparation)) {
            Write-LogWarning "Systemvorbereitung mit Warnungen abgeschlossen"
        }
        
        # Phase 4: Tools installieren
        if (-not (Install-RequiredTools)) {
            throw "Fehler beim Installieren der Tools"
        }
        
        # Phase 5: Treiber installieren
        if (-not $SkipDrivers) {
            Write-LogSection "Treiber-Installation wird gestartet"
            $driverScript = Join-Path $Script:Config.Paths.Scripts "drivers\auto-driver-installer.ps1"
            if (Test-Path $driverScript) {
                & $driverScript -WorkingDirectory $Script:Config.WorkingDir
            }
            else {
                Write-LogWarning "Treiber-Installations-Script nicht gefunden"
            }
        }
        
        # Phase 6: Geräte-Erkennung
        Test-DeviceConnection | Out-Null
        
        # Phase 7: Firmware-Download
        if (-not $SkipFirmware) {
            Write-LogSection "Firmware-Download wird gestartet"
            $firmwareScript = Join-Path $Script:Config.Paths.Scripts "flash\firmware-downloader.ps1"
            if (Test-Path $firmwareScript) {
                & $firmwareScript -WorkingDirectory $Script:Config.WorkingDir
            }
            else {
                Write-LogWarning "Firmware-Download-Script nicht gefunden"
            }
        }
        
        # Phase 8: SPD Flash Automation
        Write-LogSection "SPD Flash Automation wird vorbereitet"
        $flashScript = Join-Path $Script:Config.Paths.Scripts "flash\spd-flash-automation.ps1"
        if (Test-Path $flashScript) {
            & $flashScript -WorkingDirectory $Script:Config.WorkingDir
        }
        else {
            Write-LogWarning "SPD Flash Automation-Script nicht gefunden"
        }
        
        # Phase 9: Abschluss
        Write-LogSection "Installation abgeschlossen"
        
        # Generiere Report
        $reportPath = Join-Path $Script:Config.Paths.Docs "INSTALLATION-REPORT.md"
        $summary = @{
            "Status" = "Erfolgreich"
            "Datum" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Version" = $Script:Config.Version
            "Gerät" = $Script:Config.DeviceModel
        }
        Export-LogSummary -OutputPath $reportPath -Summary $summary
        
        Write-LogInfo "Report erstellt: $reportPath"
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                   INSTALLATION ERFOLGREICH!                        ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
        return 0
    }
    catch {
        Write-LogError "Kritischer Fehler: $($_.Exception.Message)"
        Write-LogError $_.ScriptStackTrace
        
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║                   INSTALLATION FEHLGESCHLAGEN!                     ║" -ForegroundColor Red
        Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ""
        
        return 1
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

exit (Start-Installation)
