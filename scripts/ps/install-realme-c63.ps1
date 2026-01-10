#Requires -Version 5.1
<#
.SYNOPSIS
    Vollautomatische Windows 11 PowerShell Installation für Realme C63 (RMX3939)

.DESCRIPTION
    Automatisiertes Installations-Skript für das Realme C63 (Modell RMX3939) mit:
    - Automatischer Download aller Tools (SPD Flash Tool, USB-Treiber, Firmware)
    - SHA256-Hash-Verifikation
    - USB-Treiber-Installation
    - Stock-Firmware Flash mit SPD Flash Tool
    - Fehlerbehandlung und detailliertem Logging

.PARAMETER ConfigPath
    Pfad zur Konfigurations-Datei (Standard: config/downloads.json)

.PARAMETER SkipDriverInstall
    Überspringt die Treiber-Installation

.PARAMETER FirmwareVersion
    Spezifische Firmware-Version (latest oder stable)

.PARAMETER ForceNoPrompt
    Experten-Modus ohne Rückfragen (Vorsicht!)

.PARAMETER TestMode
    Test-Modus - simuliert Downloads ohne echtes Flashen

.PARAMETER CacheDirectory
    Verzeichnis für Download-Cache (Standard: work/cache)

.EXAMPLE
    .\install-realme-c63.ps1
    .\install-realme-c63.ps1 -FirmwareVersion stable -SkipDriverInstall
    .\install-realme-c63.ps1 -TestMode

.NOTES
    Author: Realme C63 SPD Flash Tool Automation
    Version: 1.0
    Requires: Windows 11, PowerShell 5.1+, Administrator privileges
#>

[CmdletBinding()]
param(
    [string]$ConfigPath = "config/downloads.json",
    [switch]$SkipDriverInstall,
    [ValidateSet("latest", "stable")]
    [string]$FirmwareVersion = "latest",
    [switch]$ForceNoPrompt,
    [switch]$TestMode,
    [string]$CacheDirectory = "work/cache"
)

# ============================================================================
# INITIALIZATION
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Get script directory and setup paths
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $ScriptRoot) {
    $ScriptRoot = Get-Location
}

# Setup work directories
$WorkRoot = Join-Path $ScriptRoot "..\.." -Resolve
$CachePath = Join-Path $WorkRoot $CacheDirectory
$LogPath = Join-Path $WorkRoot "work\logs"
$ConfigFile = Join-Path $WorkRoot $ConfigPath

# Create directories
@($CachePath, $LogPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Import modules
$LibPath = Join-Path $ScriptRoot "lib"
. (Join-Path $LibPath "logger.ps1")
. (Join-Path $LibPath "download-helper.ps1")
. (Join-Path $LibPath "hash-verifier.ps1")
. (Join-Path (Split-Path $ScriptRoot) "spd-flash-automation.ps1")

# Initialize logger
$LogFile = Join-Path $LogPath "install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Initialize-Logger -LogPath $LogFile -CreateDirectory

# ============================================================================
# BANNER AND SYSTEM CHECK
# ============================================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                       ║" -ForegroundColor Cyan
    Write-Host "║         REALME C63 (RMX3939) - SPD FLASH TOOL INSTALLER              ║" -ForegroundColor Cyan
    Write-Host "║                    Windows 11 PowerShell Edition                      ║" -ForegroundColor Cyan
    Write-Host "║                                                                       ║" -ForegroundColor Cyan
    Write-Host "║                  Vollautomatische Installation                        ║" -ForegroundColor Cyan
    Write-Host "║                                                                       ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Installation gestartet" "INFO"
    Write-Log "Log-Datei: $LogFile" "INFO"
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-SystemRequirements {
    Write-LogSection "System-Anforderungen prüfen"
    
    $requirements = @{
        "Administrator-Rechte" = Test-AdminPrivileges
        "Windows 11" = [System.Environment]::OSVersion.Version.Build -ge 22000
        "PowerShell 5.1+" = $PSVersionTable.PSVersion.Major -ge 5
    }
    
    $allMet = $true
    foreach ($req in $requirements.GetEnumerator()) {
        if ($req.Value) {
            Write-Log "✓ $($req.Key)" "SUCCESS"
        }
        else {
            Write-Log "✗ $($req.Key) - FEHLT!" "ERROR"
            $allMet = $false
        }
    }
    
    return $allMet
}

# ============================================================================
# CONFIGURATION LOADING
# ============================================================================

function Get-Configuration {
    Write-LogSubSection "Konfiguration laden"
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Log "Konfigurationsdatei nicht gefunden: $ConfigFile" "ERROR"
        throw "Konfigurationsdatei fehlt"
    }
    
    try {
        $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        Write-Log "Konfiguration erfolgreich geladen" "SUCCESS"
        Write-Log "Firmware-Version: $FirmwareVersion" "INFO"
        return $config
    }
    catch {
        Write-LogError "Fehler beim Laden der Konfiguration" $_
        throw
    }
}

# ============================================================================
# DOWNLOAD FUNCTIONS
# ============================================================================

function Get-SPDFlashTool {
    param([object]$Config)
    
    Write-LogSubSection "SPD Flash Tool herunterladen"
    
    $toolInfo = $Config.spd_flash_tool
    $zipFile = Join-Path $CachePath "spd-flash-tool.zip"
    $extractPath = Join-Path $CachePath "spd-flash-tool"
    
    # Check cache
    if (Test-Path $extractPath) {
        Write-Log "SPD Flash Tool bereits im Cache gefunden" "INFO"
        $toolExe = Get-SPDFlashToolPath -SearchPath $extractPath
        if ($toolExe) {
            return @{
                Success = $true
                Path = $toolExe
                ExtractPath = $extractPath
            }
        }
    }
    
    # Download
    if (-not $TestMode) {
        Write-Log "Download-URL: $($toolInfo.url)" "INFO"
        Write-Log "HINWEIS: Download-Link führt möglicherweise zu einer Seite mit Download-Button" "WARN"
        Write-Log "Bitte laden Sie SPD Flash Tool manuell herunter und platzieren Sie es in:" "WARN"
        Write-Log "  $zipFile" "WARN"
        
        # Try automatic download first
        if (-not (Test-Path $zipFile)) {
            $downloaded = Download-FileWithProgress -Url $toolInfo.url -Destination $zipFile -Description "SPD Flash Tool" -UseCache
            if (-not $downloaded) {
                Write-Log "Automatischer Download fehlgeschlagen" "WARN"
                Write-Host ""
                Write-Host "Bitte laden Sie SPD Flash Tool manuell herunter:" -ForegroundColor Yellow
                Write-Host "  1. Öffnen Sie: $($toolInfo.url)" -ForegroundColor White
                Write-Host "  2. Laden Sie die ZIP-Datei herunter" -ForegroundColor White
                Write-Host "  3. Speichern Sie die Datei als: $zipFile" -ForegroundColor White
                Write-Host ""
                Read-Host "Drücken Sie Enter, wenn der Download abgeschlossen ist"
                
                if (-not (Test-Path $zipFile)) {
                    Write-Log "SPD Flash Tool Datei nicht gefunden nach manuellem Download" "ERROR"
                    return @{ Success = $false }
                }
            }
        }
        
        # Verify hash
        if (-not [string]::IsNullOrWhiteSpace($toolInfo.sha256)) {
            if (-not (Test-FileHash -FilePath $zipFile -ExpectedHash $toolInfo.sha256)) {
                Write-Log "Hash-Verifikation fehlgeschlagen!" "ERROR"
                return @{ Success = $false }
            }
        }
        else {
            $hash = Get-FileSHA256Hash -FilePath $zipFile
            Write-Log "Berechneter Hash (bitte in config/downloads.json eintragen):" "WARN"
            Write-Log "  $hash" "WARN"
        }
        
        # Extract
        Write-Log "Entpacke SPD Flash Tool..." "INFO"
        if (-not (Expand-ArchiveWithProgress -ArchivePath $zipFile -DestinationPath $extractPath -Force)) {
            Write-Log "Fehler beim Entpacken" "ERROR"
            return @{ Success = $false }
        }
    }
    else {
        Write-Log "[TEST MODE] SPD Flash Tool Download übersprungen" "WARN"
        return @{ Success = $true; Path = "TEST_MODE" }
    }
    
    # Find executable
    $toolExe = Get-SPDFlashToolPath -SearchPath $extractPath
    if (-not $toolExe) {
        Write-Log "SPD Flash Tool Executable nicht gefunden" "ERROR"
        return @{ Success = $false }
    }
    
    return @{
        Success = $true
        Path = $toolExe
        ExtractPath = $extractPath
    }
}

function Get-USBDrivers {
    param([object]$Config)
    
    Write-LogSubSection "USB-Treiber herunterladen"
    
    if ($SkipDriverInstall) {
        Write-Log "Treiber-Installation übersprungen (Parameter -SkipDriverInstall)" "INFO"
        return @{ Success = $true; Skipped = $true }
    }
    
    $drivers = $Config.usb_drivers
    $downloadedDrivers = @()
    
    foreach ($driverKey in $drivers.PSObject.Properties.Name) {
        $driverInfo = $drivers.$driverKey
        Write-Log "Lade $($driverInfo.name)..." "INFO"
        
        $driverFile = Join-Path $CachePath "$driverKey.zip"
        
        if (-not $TestMode) {
            Write-Log "Download-URL: $($driverInfo.url)" "INFO"
            Write-Log "HINWEIS: $($driverInfo.note)" "WARN"
            
            # Try download
            if (-not (Test-Path $driverFile)) {
                $downloaded = Download-FileWithProgress -Url $driverInfo.url -Destination $driverFile -Description $driverInfo.name -UseCache
                if (-not $downloaded) {
                    Write-Log "Automatischer Download fehlgeschlagen für $($driverInfo.name)" "WARN"
                    Write-Host ""
                    Write-Host "Bitte laden Sie die Treiber manuell herunter:" -ForegroundColor Yellow
                    Write-Host "  1. Öffnen Sie: $($driverInfo.url)" -ForegroundColor White
                    Write-Host "  2. Laden Sie die Treiber herunter" -ForegroundColor White
                    Write-Host "  3. Speichern Sie als: $driverFile" -ForegroundColor White
                    Write-Host ""
                    $skip = Read-Host "Überspringen? (j/N)"
                    if ($skip -eq "j" -or $skip -eq "J") {
                        continue
                    }
                }
            }
            
            if (Test-Path $driverFile) {
                # Verify hash if available
                if (-not [string]::IsNullOrWhiteSpace($driverInfo.sha256)) {
                    Test-FileHash -FilePath $driverFile -ExpectedHash $driverInfo.sha256 -SkipIfEmpty | Out-Null
                }
                else {
                    $hash = Get-FileSHA256Hash -FilePath $driverFile
                    Write-Log "Hash: $hash" "WARN"
                }
                
                $downloadedDrivers += @{
                    Name = $driverInfo.name
                    Path = $driverFile
                    Key = $driverKey
                }
            }
        }
        else {
            Write-Log "[TEST MODE] Treiber-Download übersprungen" "WARN"
        }
    }
    
    return @{
        Success = $true
        Drivers = $downloadedDrivers
    }
}

function Get-Firmware {
    param([object]$Config)
    
    Write-LogSubSection "Firmware herunterladen"
    
    $firmwareInfo = $Config.firmware.$FirmwareVersion
    
    if (-not $firmwareInfo) {
        Write-Log "Firmware-Version '$FirmwareVersion' nicht in Konfiguration gefunden" "ERROR"
        return @{ Success = $false }
    }
    
    Write-Log "Version: $($firmwareInfo.version)" "INFO"
    Write-Log "Build: $($firmwareInfo.build_date)" "INFO"
    
    $firmwareFile = Join-Path $CachePath "$($firmwareInfo.version).pac"
    
    if (Test-Path $firmwareFile) {
        Write-Log "Firmware bereits im Cache: $firmwareFile" "SUCCESS"
        return @{
            Success = $true
            Path = $firmwareFile
            Version = $firmwareInfo.version
        }
    }
    
    if (-not $TestMode) {
        Write-Log "Download-URL: $($firmwareInfo.url)" "INFO"
        Write-Log "WICHTIG: $($firmwareInfo.note)" "WARN"
        
        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║                    FIRMWARE DOWNLOAD ERFORDERLICH                     ║" -ForegroundColor Yellow
        Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Die Firmware muss manuell heruntergeladen werden:" -ForegroundColor White
        Write-Host ""
        Write-Host "Quellen (wählen Sie eine):" -ForegroundColor Cyan
        $sources = $Config.firmware.sources
        for ($i = 0; $i -lt $sources.Count; $i++) {
            Write-Host "  $($i + 1). $($sources[$i])" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Schritte:" -ForegroundColor Cyan
        Write-Host "  1. Öffnen Sie eine der obigen URLs" -ForegroundColor White
        Write-Host "  2. Laden Sie die Firmware für RMX3939 herunter" -ForegroundColor White
        Write-Host "  3. Speichern Sie die .PAC-Datei als:" -ForegroundColor White
        Write-Host "     $firmwareFile" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Hinweise:" -ForegroundColor Yellow
        Write-Host "  • Manche Seiten erfordern Login/Account" -ForegroundColor Yellow
        Write-Host "  • Download kann mehrere GB groß sein" -ForegroundColor Yellow
        Write-Host "  • Achten Sie auf Modellnummer: RMX3939" -ForegroundColor Yellow
        Write-Host ""
        
        Read-Host "Drücken Sie Enter, wenn der Download abgeschlossen ist"
        
        if (-not (Test-Path $firmwareFile)) {
            Write-Log "Firmware-Datei nicht gefunden: $firmwareFile" "ERROR"
            return @{ Success = $false }
        }
        
        # Verify hash if available
        if (-not [string]::IsNullOrWhiteSpace($firmwareInfo.sha256)) {
            if (-not (Test-FileHash -FilePath $firmwareFile -ExpectedHash $firmwareInfo.sha256)) {
                Write-Log "Firmware Hash-Verifikation fehlgeschlagen!" "ERROR"
                $continue = Read-Host "Trotzdem fortfahren? (j/N)"
                if ($continue -ne "j" -and $continue -ne "J") {
                    return @{ Success = $false }
                }
            }
        }
        else {
            $hash = Get-FileSHA256Hash -FilePath $firmwareFile
            Write-Log "Berechneter Firmware-Hash:" "WARN"
            Write-Log "  $hash" "WARN"
        }
    }
    else {
        Write-Log "[TEST MODE] Firmware-Download übersprungen" "WARN"
        return @{ Success = $true; Path = "TEST_MODE" }
    }
    
    return @{
        Success = $true
        Path = $firmwareFile
        Version = $firmwareInfo.version
    }
}

# ============================================================================
# DRIVER INSTALLATION
# ============================================================================

function Install-Drivers {
    param([array]$Drivers)
    
    Write-LogSubSection "Treiber installieren"
    
    if ($SkipDriverInstall) {
        Write-Log "Treiber-Installation übersprungen" "INFO"
        return $true
    }
    
    if ($TestMode) {
        Write-Log "[TEST MODE] Treiber-Installation übersprungen" "WARN"
        return $true
    }
    
    if ($Drivers.Count -eq 0) {
        Write-Log "Keine Treiber zum Installieren" "WARN"
        return $true
    }
    
    foreach ($driver in $Drivers) {
        Write-Log "Installiere: $($driver.Name)" "INFO"
        
        # Extract driver
        $extractPath = Join-Path $CachePath "drivers\$($driver.Key)"
        if (-not (Expand-ArchiveWithProgress -ArchivePath $driver.Path -DestinationPath $extractPath -Force)) {
            Write-Log "Fehler beim Entpacken von $($driver.Name)" "WARN"
            continue
        }
        
        # Find and install .inf files
        $infFiles = Get-ChildItem -Path $extractPath -Filter "*.inf" -Recurse
        
        if ($infFiles) {
            foreach ($inf in $infFiles) {
                Write-Log "Installiere Treiber: $($inf.Name)" "INFO"
                try {
                    $output = pnputil.exe /add-driver "$($inf.FullName)" /install 2>&1
                    Write-Log "Treiber installiert: $($inf.Name)" "SUCCESS"
                }
                catch {
                    Write-Log "Fehler bei Installation von $($inf.Name): $_" "WARN"
                }
            }
        }
        else {
            Write-Log "Keine .inf-Dateien gefunden in $($driver.Name)" "WARN"
            Write-Log "Möglicherweise muss die Installation manuell durchgeführt werden" "WARN"
        }
    }
    
    # Check if SPD drivers are installed
    if (Test-SPDDriversInstalled) {
        Write-Log "SPD-Treiber erfolgreich installiert" "SUCCESS"
    }
    else {
        Write-Log "SPD-Treiber möglicherweise nicht korrekt installiert" "WARN"
        Write-Log "Bitte überprüfen Sie den Geräte-Manager" "WARN"
    }
    
    return $true
}

# ============================================================================
# FLASH PROCESS
# ============================================================================

function Start-FlashProcess {
    param(
        [string]$ToolPath,
        [string]$FirmwarePath
    )
    
    Write-LogSection "Flash-Prozess starten"
    
    if ($TestMode) {
        Write-Log "[TEST MODE] Flash-Prozess übersprungen" "WARN"
        Show-SPDFlashInstructions -FirmwarePath $FirmwarePath
        Write-Log "[TEST MODE] Simulation abgeschlossen" "INFO"
        return $true
    }
    
    # Display pre-flash warnings
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                           ⚠️  WARNUNG ⚠️                               ║" -ForegroundColor Red
    Write-Host "║                                                                       ║" -ForegroundColor Red
    Write-Host "║  Das Flashen der Stock-Firmware wird:                                ║" -ForegroundColor Red
    Write-Host "║  • ALLE DATEN auf dem Gerät LÖSCHEN                                  ║" -ForegroundColor Red
    Write-Host "║  • Das Gerät auf Werkseinstellungen zurücksetzen                     ║" -ForegroundColor Red
    Write-Host "║  • Mehrere Minuten dauern                                            ║" -ForegroundColor Red
    Write-Host "║                                                                       ║" -ForegroundColor Red
    Write-Host "║  Stellen Sie sicher:                                                 ║" -ForegroundColor Red
    Write-Host "║  ✓ Backup aller wichtigen Daten erstellt                            ║" -ForegroundColor Red
    Write-Host "║  ✓ Akku mindestens 50% geladen                                      ║" -ForegroundColor Red
    Write-Host "║  ✓ Originales/hochwertiges USB-Kabel vorhanden                      ║" -ForegroundColor Red
    Write-Host "║  ✓ Stabile Stromversorgung                                          ║" -ForegroundColor Red
    Write-Host "║                                                                       ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    
    if (-not $ForceNoPrompt) {
        $confirm = Read-Host "Möchten Sie fortfahren? Tippen Sie 'JA' zum Bestätigen"
        if ($confirm -ne "JA") {
            Write-Log "Flash-Prozess vom Benutzer abgebrochen" "INFO"
            return $false
        }
    }
    
    # Start SPD Flash Tool
    Write-Log "Starte SPD Flash Tool..." "INFO"
    $process = Start-SPDFlashTool -ToolPath $ToolPath -FirmwarePath $FirmwarePath
    
    if (-not $process) {
        Write-Log "Konnte SPD Flash Tool nicht starten" "ERROR"
        return $false
    }
    
    # Show instructions
    Show-SPDFlashInstructions -FirmwarePath $FirmwarePath
    
    # Wait for user confirmation
    Write-Host ""
    if (-not (Confirm-UserAction "Haben Sie die Firmware im SPD Flash Tool geladen?")) {
        Write-Log "Prozess abgebrochen" "INFO"
        return $false
    }
    
    Write-Log "Warte auf SPD-Gerät..." "INFO"
    if (Wait-ForSPDDevice -TimeoutSeconds 120) {
        Write-Log "Gerät erkannt! Sie können jetzt 'Start' im SPD Flash Tool klicken" "SUCCESS"
    }
    else {
        Write-Log "Gerät nicht erkannt - bitte manuell fortfahren" "WARN"
    }
    
    Write-Host ""
    Write-Host "Flash-Prozess läuft..." -ForegroundColor Cyan
    Write-Host "Bitte warten Sie, bis 'PASSED' im SPD Flash Tool angezeigt wird" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Confirm-UserAction "Wurde 'PASSED' oder 'Download Success' angezeigt?")) {
        Write-Log "Flash möglicherweise fehlgeschlagen" "ERROR"
        return $false
    }
    
    Write-Log "Flash-Prozess erfolgreich abgeschlossen!" "SUCCESS"
    return $true
}

# ============================================================================
# POST-FLASH
# ============================================================================

function Show-PostFlashInfo {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                                       ║" -ForegroundColor Green
    Write-Host "║                    ✓  INSTALLATION ABGESCHLOSSEN                      ║" -ForegroundColor Green
    Write-Host "║                                                                       ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nächste Schritte:" -ForegroundColor Cyan
    Write-Host "  1. Das Gerät startet automatisch neu" -ForegroundColor White
    Write-Host "  2. Erster Boot kann 5-10 Minuten dauern" -ForegroundColor White
    Write-Host "  3. Folgen Sie dem Setup-Assistenten auf dem Gerät" -ForegroundColor White
    Write-Host "  4. Stellen Sie Ihre Daten aus dem Backup wieder her" -ForegroundColor White
    Write-Host ""
    Write-Host "Bei Problemen:" -ForegroundColor Cyan
    Write-Host "  • Siehe: docs/TROUBLESHOOTING.md" -ForegroundColor White
    Write-Host "  • Log-Datei: $LogFile" -ForegroundColor White
    Write-Host ""
    Write-Log "Installation erfolgreich abgeschlossen" "SUCCESS"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    try {
        # Show banner
        Show-Banner
        
        # Check system requirements
        if (-not (Test-SystemRequirements)) {
            Write-Log "System-Anforderungen nicht erfüllt" "ERROR"
            Write-Host ""
            Write-Host "Bitte stellen Sie sicher:" -ForegroundColor Yellow
            Write-Host "  • PowerShell als Administrator ausführen" -ForegroundColor White
            Write-Host "  • Windows 11 ist installiert" -ForegroundColor White
            Write-Host "  • PowerShell 5.1 oder höher" -ForegroundColor White
            Write-Host ""
            exit 1
        }
        
        # Load configuration
        $config = Get-Configuration
        
        # Show device info
        Write-LogSection "Geräteinformationen"
        $deviceInfo = $config.device_info
        Write-Log "Modell: $($deviceInfo.model) - $($deviceInfo.name)" "INFO"
        Write-Log "Chipset: $($deviceInfo.chipset)" "INFO"
        Write-Log "Flash-Methode: $($deviceInfo.flash_method)" "INFO"
        
        # Download phase
        Write-LogSection "Download-Phase"
        
        $spdTool = Get-SPDFlashTool -Config $config
        if (-not $spdTool.Success) {
            throw "SPD Flash Tool konnte nicht heruntergeladen werden"
        }
        
        $drivers = Get-USBDrivers -Config $config
        if (-not $drivers.Success) {
            throw "Treiber konnten nicht heruntergeladen werden"
        }
        
        $firmware = Get-Firmware -Config $config
        if (-not $firmware.Success) {
            throw "Firmware konnte nicht heruntergeladen werden"
        }
        
        # Installation phase
        Write-LogSection "Installations-Phase"
        
        if (-not (Install-Drivers -Drivers $drivers.Drivers)) {
            Write-Log "Treiber-Installation mit Problemen - fortfahren trotzdem" "WARN"
        }
        
        # Flash phase
        if (-not (Start-FlashProcess -ToolPath $spdTool.Path -FirmwarePath $firmware.Path)) {
            throw "Flash-Prozess fehlgeschlagen"
        }
        
        # Post-flash
        Show-PostFlashInfo
        
    }
    catch {
        Write-LogError "Fataler Fehler" $_
        Write-Host ""
        Write-Host "Installation fehlgeschlagen!" -ForegroundColor Red
        Write-Host "Weitere Informationen im Log: $LogFile" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

# Run main function
Main
