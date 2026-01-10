#Requires -Version 5.1
<#
.SYNOPSIS
    Vollautomatische Windows 11 Installation für Realme C63 (RMX3939) mit Unisoc/Spreadtrum Chipset
    
.DESCRIPTION
    Dieses Skript automatisiert die Installation aller erforderlichen Tools, Treiber und Firmware
    für das Realme C63 (RMX3939) mit Unisoc/Spreadtrum-Chipset. Es lädt SPD Flash Tool, USB-Treiber
    herunter, verifiziert Downloads mit SHA256-Hashes und führt Sie durch den GUI-basierten
    Flash-Prozess mit dem SPD Flash Tool.
    
.PARAMETER ConfigPath
    Pfad zur JSON-Konfigurationsdatei mit Download-URLs und Hashes
    Standard: ../../config/downloads.json (relativ zum Skript)
    
.PARAMETER SkipDriverInstall
    Überspringt die Installation der USB-Treiber (nützlich wenn bereits installiert)
    
.PARAMETER ForceNoPrompt
    Überspringt alle Sicherheitsabfragen und Bestätigungen (für vollautomatischen Betrieb)
    
.EXAMPLE
    .\install-realme-c63.ps1
    Führt die vollständige Installation mit Standardeinstellungen aus
    
.EXAMPLE
    .\install-realme-c63.ps1 -SkipDriverInstall -ForceNoPrompt
    Installation ohne Treiberinstallation und ohne Benutzerinteraktion
    
.EXAMPLE
    .\install-realme-c63.ps1 -ConfigPath "C:\custom\config.json"
    Installation mit benutzerdefinierter Konfigurationsdatei
    
.NOTES
    Autor: Realme C63 Installation Team
    Erstellt: 2026-01-10
    Version: 1.0.0
    Voraussetzungen: Windows 11, Administrator-Rechte
    
    WICHTIG: Realme C63 (RMX3939) verwendet Unisoc/Spreadtrum-Chipset,
    NICHT Qualcomm MTK Fastboot!
#>

param(
    [string]$ConfigPath = "",
    [switch]$SkipDriverInstall,
    [switch]$ForceNoPrompt
)

# ============================================================================
# GLOBALE VARIABLEN UND KONFIGURATION
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Script:ScriptVersion = "1.0.0"

# Farbcodes für Konsolenausgabe
$Colors = @{
    Info    = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Prompt  = "Magenta"
    Header  = "White"
}

# Skript-Verzeichnis ermitteln
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Standard-Konfigurationspfad
if ([string]::IsNullOrEmpty($ConfigPath)) {
    $ConfigPath = Join-Path $RepoRoot "config\downloads.json"
}

# Arbeitsverzeichnis
$WorkDir = Join-Path $env:TEMP "Realme-C63-Installation"

# Verzeichnisstruktur
$Paths = @{
    Work           = $WorkDir
    Downloads      = Join-Path $WorkDir "downloads"
    SPDFlashTool   = Join-Path $WorkDir "spd-flash-tool"
    SPDDrivers     = Join-Path $WorkDir "spd-drivers"
    RealmeDrivers  = Join-Path $WorkDir "realme-drivers"
    ADBTools       = Join-Path $WorkDir "adb-tools"
    Firmware       = Join-Path $WorkDir "firmware"
    Logs           = Join-Path $WorkDir "logs"
}

# Log-Datei
$LogFile = Join-Path $Paths.Logs "install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Konfigurationsdaten (werden aus JSON geladen)
$Config = $null

# Download-Retry-Einstellungen
$MaxRetries = 3
$RetryDelaySeconds = 5

# ============================================================================
# UTILITY-FUNKTIONEN
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
    Schreibt Nachrichten in Konsole und Log-Datei mit Zeitstempel und Farbcodierung
    #>
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorType = $Colors[$Level]
    
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Host $LogMessage -ForegroundColor $ColorType
    
    # Log-Verzeichnis erstellen falls nicht vorhanden
    if (-not (Test-Path $Paths.Logs)) {
        New-Item -Path $Paths.Logs -ItemType Directory -Force | Out-Null
    }
    
    # In Log-Datei schreiben
    try {
        Add-Content -Path $LogFile -Value $LogMessage -Force -ErrorAction SilentlyContinue
    }
    catch {
        # Fehler beim Loggen ignorieren
    }
}

function Write-Header {
    <#
    .SYNOPSIS
    Zeigt einen formatierten Header an
    #>
    param([string]$Text)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host "  $Text" -ForegroundColor $Colors.Header
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host ""
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
    Überprüft, ob das Skript mit Administrator-Rechten ausgeführt wird
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WindowsVersion {
    <#
    .SYNOPSIS
    Überprüft, ob Windows 11 verwendet wird
    #>
    $osVersion = [System.Environment]::OSVersion.Version
    # Windows 11 hat Build-Nummer >= 22000
    return ($osVersion.Major -eq 10 -and $osVersion.Build -ge 22000)
}

function Read-Config {
    <#
    .SYNOPSIS
    Lädt die Konfigurationsdatei
    #>
    param([string]$Path)
    
    Write-Log "Lade Konfiguration von: $Path" "Info"
    
    if (-not (Test-Path $Path)) {
        Write-Log "Konfigurationsdatei nicht gefunden: $Path" "Error"
        throw "Konfigurationsdatei nicht gefunden"
    }
    
    try {
        $configContent = Get-Content -Path $Path -Raw -Encoding UTF8
        $config = $configContent | ConvertFrom-Json
        Write-Log "Konfiguration erfolgreich geladen" "Success"
        return $config
    }
    catch {
        Write-Log "Fehler beim Laden der Konfiguration: $_" "Error"
        throw
    }
}

function Confirm-Action {
    <#
    .SYNOPSIS
    Fragt den Benutzer nach Bestätigung (außer bei -ForceNoPrompt)
    #>
    param(
        [string]$Message,
        [string]$WarningMessage = ""
    )
    
    if ($ForceNoPrompt) {
        Write-Log "Automatische Bestätigung: $Message" "Info"
        return $true
    }
    
    Write-Host ""
    if ($WarningMessage) {
        Write-Host "⚠️  $WarningMessage" -ForegroundColor $Colors.Warning
        Write-Host ""
    }
    Write-Host "$Message" -ForegroundColor $Colors.Prompt
    
    do {
        $response = Read-Host "Fortfahren? (J/N)"
        if ($response -match '^[JjYy]') {
            return $true
        }
        elseif ($response -match '^[Nn]') {
            Write-Log "Aktion abgebrochen durch Benutzer" "Info"
            return $false
        }
        Write-Host "Bitte 'J' für Ja oder 'N' für Nein eingeben" -ForegroundColor $Colors.Warning
    } while ($true)
}

function Download-File {
    <#
    .SYNOPSIS
    Lädt eine Datei herunter mit Fortschrittsanzeige und Retry-Logik
    #>
    param(
        [string]$URL,
        [string]$Destination,
        [string]$Description = "Datei",
        [int]$MaxRetries = $Script:MaxRetries
    )
    
    $attempt = 0
    $success = $false
    
    while (-not $success -and $attempt -lt $MaxRetries) {
        $attempt++
        
        try {
            if ($attempt -gt 1) {
                Write-Log "Download-Versuch $attempt von $MaxRetries..." "Warning"
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            
            Write-Log "Lade herunter: $Description" "Info"
            Write-Log "URL: $URL" "Info"
            Write-Log "Ziel: $Destination" "Info"
            
            # Verzeichnis erstellen falls nicht vorhanden
            $destDir = Split-Path -Parent $Destination
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            
            # Download mit Fortschrittsanzeige
            $ProgressPreference = "Continue"
            Invoke-WebRequest -Uri $URL -OutFile $Destination -UseBasicParsing -TimeoutSec 300
            $ProgressPreference = "SilentlyContinue"
            
            if (Test-Path $Destination) {
                $fileSize = (Get-Item $Destination).Length / 1MB
                Write-Log "$Description erfolgreich heruntergeladen (${fileSize:N2} MB)" "Success"
                $success = $true
                return $true
            }
        }
        catch {
            Write-Log "Download-Fehler bei Versuch $attempt : $_" "Error"
            if ($attempt -ge $MaxRetries) {
                Write-Log "Download nach $MaxRetries Versuchen fehlgeschlagen" "Error"
                return $false
            }
        }
    }
    
    return $success
}

function Check-Hash {
    <#
    .SYNOPSIS
    Überprüft SHA256-Hash einer Datei
    #>
    param(
        [string]$FilePath,
        [string]$ExpectedHash,
        [string]$Description = "Datei"
    )
    
    if ([string]::IsNullOrEmpty($ExpectedHash) -or $ExpectedHash -eq "PLACEHOLDER") {
        Write-Log "Keine Hash-Überprüfung verfügbar für: $Description" "Warning"
        return $true
    }
    
    Write-Log "Überprüfe SHA256-Hash für: $Description" "Info"
    
    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        $actualHash = $hash.Hash
        
        if ($actualHash -eq $ExpectedHash.ToUpper()) {
            Write-Log "Hash-Überprüfung erfolgreich ✓" "Success"
            return $true
        }
        else {
            Write-Log "Hash-Überprüfung fehlgeschlagen!" "Error"
            Write-Log "Erwartet: $ExpectedHash" "Error"
            Write-Log "Erhalten: $actualHash" "Error"
            return $false
        }
    }
    catch {
        Write-Log "Fehler bei Hash-Überprüfung: $_" "Error"
        return $false
    }
}

function New-DirectoryStructure {
    <#
    .SYNOPSIS
    Erstellt die erforderliche Verzeichnisstruktur
    #>
    Write-Log "Erstelle Arbeitsverzeichnisse..." "Info"
    
    foreach ($path in $Paths.Values) {
        if (-not (Test-Path $path)) {
            try {
                New-Item -Path $path -ItemType Directory -Force | Out-Null
                Write-Log "Erstellt: $path" "Success"
            }
            catch {
                Write-Log "Fehler beim Erstellen von $path : $_" "Error"
                throw
            }
        }
    }
}

function Expand-ZipFile {
    <#
    .SYNOPSIS
    Entpackt eine ZIP-Datei
    #>
    param(
        [string]$ZipFile,
        [string]$Destination,
        [string]$Description = "Archiv"
    )
    
    Write-Log "Entpacke: $Description" "Info"
    
    try {
        if (-not (Test-Path $ZipFile)) {
            Write-Log "ZIP-Datei nicht gefunden: $ZipFile" "Error"
            return $false
        }
        
        # Zielverzeichnis erstellen
        if (-not (Test-Path $Destination)) {
            New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        }
        
        # Entpacken
        Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force
        Write-Log "$Description erfolgreich entpackt" "Success"
        return $true
    }
    catch {
        Write-Log "Fehler beim Entpacken von $Description : $_" "Error"
        return $false
    }
}

# ============================================================================
# TREIBER-INSTALLATION
# ============================================================================

function Install-SPDDrivers {
    <#
    .SYNOPSIS
    Lädt herunter und installiert SPD/Unisoc USB-Treiber
    #>
    Write-Header "SPD USB-Treiber Installation"
    
    if ($SkipDriverInstall) {
        Write-Log "Treiberinstallation übersprungen (--SkipDriverInstall)" "Info"
        return $true
    }
    
    # Download-URL aus Config
    $driverUrl = $Config.drivers.spd_usb.url
    $driverHash = $Config.drivers.spd_usb.sha256
    
    if ([string]::IsNullOrEmpty($driverUrl)) {
        Write-Log "Keine SPD-Treiber URL in Konfiguration" "Error"
        return $false
    }
    
    # Download
    $zipFile = Join-Path $Paths.Downloads "spd-drivers.zip"
    if (-not (Download-File -URL $driverUrl -Destination $zipFile -Description "SPD USB-Treiber")) {
        Write-Log "SPD-Treiber Download fehlgeschlagen" "Error"
        return $false
    }
    
    # Hash überprüfen
    if (-not (Check-Hash -FilePath $zipFile -ExpectedHash $driverHash -Description "SPD USB-Treiber")) {
        Write-Log "Hash-Überprüfung fehlgeschlagen - möglicherweise beschädigte Datei" "Warning"
        if (-not (Confirm-Action "Trotzdem fortfahren?")) {
            return $false
        }
    }
    
    # Entpacken
    if (-not (Expand-ZipFile -ZipFile $zipFile -Destination $Paths.SPDDrivers -Description "SPD USB-Treiber")) {
        return $false
    }
    
    # Treiber installieren
    Write-Log "Installiere SPD USB-Treiber..." "Info"
    
    try {
        # Suche nach .inf Dateien
        $infFiles = Get-ChildItem -Path $Paths.SPDDrivers -Filter "*.inf" -Recurse
        
        if ($infFiles) {
            foreach ($infFile in $infFiles) {
                Write-Log "Installiere: $($infFile.Name)" "Info"
                $result = pnputil.exe /add-driver "$($infFile.FullName)" /install 2>&1
                Write-Log "Treiber installiert: $($infFile.Name)" "Success"
            }
            return $true
        }
        else {
            Write-Log "Keine .inf Treiberdateien gefunden" "Warning"
            Write-Log "Möglicherweise manuelle Installation erforderlich" "Warning"
            Write-Log "Treiber-Verzeichnis: $($Paths.SPDDrivers)" "Info"
            
            # Setup.exe suchen und ausführen
            $setupFiles = Get-ChildItem -Path $Paths.SPDDrivers -Filter "setup*.exe" -Recurse
            if ($setupFiles) {
                $setupFile = $setupFiles[0].FullName
                Write-Log "Setup-Programm gefunden: $setupFile" "Info"
                
                if (Confirm-Action "Setup-Programm für SPD-Treiber ausführen?") {
                    Start-Process -FilePath $setupFile -Wait
                    Write-Log "Treiber-Setup abgeschlossen" "Success"
                    return $true
                }
            }
            
            return $false
        }
    }
    catch {
        Write-Log "Fehler bei Treiberinstallation: $_" "Error"
        return $false
    }
}

function Install-RealmeDrivers {
    <#
    .SYNOPSIS
    Lädt herunter und installiert Realme Universal USB-Treiber
    #>
    Write-Header "Realme Universal USB-Treiber Installation"
    
    if ($SkipDriverInstall) {
        Write-Log "Treiberinstallation übersprungen (--SkipDriverInstall)" "Info"
        return $true
    }
    
    # Download-URL aus Config
    $driverUrl = $Config.drivers.realme_universal.url
    $driverHash = $Config.drivers.realme_universal.sha256
    
    if ([string]::IsNullOrEmpty($driverUrl)) {
        Write-Log "Keine Realme-Treiber URL in Konfiguration" "Error"
        return $false
    }
    
    # Download
    $zipFile = Join-Path $Paths.Downloads "realme-drivers.zip"
    if (-not (Download-File -URL $driverUrl -Destination $zipFile -Description "Realme Universal USB-Treiber")) {
        Write-Log "Realme-Treiber Download fehlgeschlagen" "Error"
        return $false
    }
    
    # Hash überprüfen
    if (-not (Check-Hash -FilePath $zipFile -ExpectedHash $driverHash -Description "Realme Universal USB-Treiber")) {
        Write-Log "Hash-Überprüfung fehlgeschlagen" "Warning"
        if (-not (Confirm-Action "Trotzdem fortfahren?")) {
            return $false
        }
    }
    
    # Entpacken
    if (-not (Expand-ZipFile -ZipFile $zipFile -Destination $Paths.RealmeDrivers -Description "Realme USB-Treiber")) {
        return $false
    }
    
    # Treiber installieren
    Write-Log "Installiere Realme USB-Treiber..." "Info"
    
    try {
        # Suche nach .inf oder .exe Dateien
        $infFiles = Get-ChildItem -Path $Paths.RealmeDrivers -Filter "*.inf" -Recurse
        
        if ($infFiles) {
            foreach ($infFile in $infFiles) {
                Write-Log "Installiere: $($infFile.Name)" "Info"
                $result = pnputil.exe /add-driver "$($infFile.FullName)" /install 2>&1
                Write-Log "Treiber installiert: $($infFile.Name)" "Success"
            }
            return $true
        }
        else {
            # Setup.exe suchen
            $setupFiles = Get-ChildItem -Path $Paths.RealmeDrivers -Filter "*.exe" -Recurse
            if ($setupFiles) {
                $setupFile = $setupFiles[0].FullName
                Write-Log "Setup-Programm gefunden: $setupFile" "Info"
                
                if (Confirm-Action "Setup-Programm für Realme-Treiber ausführen?") {
                    Start-Process -FilePath $setupFile -Wait
                    Write-Log "Treiber-Setup abgeschlossen" "Success"
                    return $true
                }
            }
            
            Write-Log "Keine Treiberdateien gefunden" "Warning"
            return $false
        }
    }
    catch {
        Write-Log "Fehler bei Treiberinstallation: $_" "Error"
        return $false
    }
}

function Test-DriverInstallation {
    <#
    .SYNOPSIS
    Überprüft ob die Treiber korrekt installiert sind
    #>
    Write-Log "Überprüfe Treiberinstallation..." "Info"
    
    try {
        # Liste installierte Treiber auf
        $drivers = pnputil.exe /enum-drivers
        
        # Suche nach SPD/Spreadtrum/Unisoc Treibern
        $spdFound = $drivers -match "(SPD|Spreadtrum|Unisoc)"
        $realmeFound = $drivers -match "Realme"
        
        if ($spdFound) {
            Write-Log "SPD/Unisoc Treiber gefunden ✓" "Success"
        }
        else {
            Write-Log "SPD/Unisoc Treiber nicht gefunden" "Warning"
        }
        
        if ($realmeFound) {
            Write-Log "Realme Treiber gefunden ✓" "Success"
        }
        else {
            Write-Log "Realme Treiber nicht gefunden" "Warning"
        }
        
        return ($spdFound -or $realmeFound)
    }
    catch {
        Write-Log "Fehler bei Treiberüberprüfung: $_" "Warning"
        return $false
    }
}

# ============================================================================
# SPD FLASH TOOL SETUP
# ============================================================================

function Setup-SPDFlashTool {
    <#
    .SYNOPSIS
    Lädt herunter und richtet SPD Flash Tool ein
    #>
    Write-Header "SPD Flash Tool Setup"
    
    # Download-URL aus Config
    $toolUrl = $Config.tools.spd_flash_tool.url
    $toolHash = $Config.tools.spd_flash_tool.sha256
    
    if ([string]::IsNullOrEmpty($toolUrl)) {
        Write-Log "Keine SPD Flash Tool URL in Konfiguration" "Error"
        return $false
    }
    
    # Download
    $zipFile = Join-Path $Paths.Downloads "spd-flash-tool.zip"
    if (-not (Download-File -URL $toolUrl -Destination $zipFile -Description "SPD Flash Tool")) {
        Write-Log "SPD Flash Tool Download fehlgeschlagen" "Error"
        return $false
    }
    
    # Hash überprüfen
    if (-not (Check-Hash -FilePath $zipFile -ExpectedHash $toolHash -Description "SPD Flash Tool")) {
        Write-Log "Hash-Überprüfung fehlgeschlagen" "Warning"
        if (-not (Confirm-Action "Trotzdem fortfahren?")) {
            return $false
        }
    }
    
    # Entpacken
    if (-not (Expand-ZipFile -ZipFile $zipFile -Destination $Paths.SPDFlashTool -Description "SPD Flash Tool")) {
        return $false
    }
    
    Write-Log "SPD Flash Tool erfolgreich eingerichtet" "Success"
    Write-Log "Installationsverzeichnis: $($Paths.SPDFlashTool)" "Info"
    
    return $true
}

function Install-ADBTools {
    <#
    .SYNOPSIS
    Lädt ADB Platform Tools herunter (optional für Debugging)
    #>
    Write-Header "ADB Tools Installation (Optional)"
    
    $adbUrl = $Config.tools.adb_platform_tools.url
    
    if ([string]::IsNullOrEmpty($adbUrl)) {
        Write-Log "Keine ADB Tools URL in Konfiguration" "Warning"
        return $true
    }
    
    if (-not (Confirm-Action "ADB Platform Tools für Debugging installieren?")) {
        Write-Log "ADB Installation übersprungen" "Info"
        return $true
    }
    
    # Download
    $zipFile = Join-Path $Paths.Downloads "platform-tools.zip"
    if (-not (Download-File -URL $adbUrl -Destination $zipFile -Description "ADB Platform Tools")) {
        Write-Log "ADB Tools Download fehlgeschlagen (nicht kritisch)" "Warning"
        return $true
    }
    
    # Entpacken
    if (Expand-ZipFile -ZipFile $zipFile -Destination $Paths.ADBTools -Description "ADB Platform Tools") {
        Write-Log "ADB Tools erfolgreich installiert" "Success"
        Write-Log "Pfad: $($Paths.ADBTools)" "Info"
    }
    
    return $true
}

# ============================================================================
# FIRMWARE-VERWALTUNG
# ============================================================================

function Show-FirmwareGuide {
    <#
    .SYNOPSIS
    Zeigt Anleitung zum Firmware-Download an
    #>
    Write-Header "Firmware Download Anleitung"
    
    Write-Host ""
    Write-Host "WICHTIG: Firmware muss manuell heruntergeladen werden!" -ForegroundColor $Colors.Warning
    Write-Host ""
    Write-Host "Firmware-Quellen für Realme C63 (RMX3939):" -ForegroundColor $Colors.Info
    Write-Host ""
    
    $sources = $Config.firmware.sources
    $index = 1
    foreach ($source in $sources) {
        Write-Host "  $index. $($source.name)" -ForegroundColor White
        Write-Host "     URL: $($source.url)" -ForegroundColor Cyan
        Write-Host "     Info: $($source.note)" -ForegroundColor Gray
        Write-Host ""
        $index++
    }
    
    Write-Host "So finden Sie die richtige Firmware:" -ForegroundColor $Colors.Header
    Write-Host "  1. Überprüfen Sie Ihre Modellnummer mit: *#899#" -ForegroundColor White
    Write-Host "  2. Stellen Sie sicher, dass es RMX3939 ist" -ForegroundColor White
    Write-Host "  3. Laden Sie die neueste verfügbare Firmware herunter" -ForegroundColor White
    Write-Host "  4. Speichern Sie die .PAC oder .ZIP Datei in:" -ForegroundColor White
    Write-Host "     $($Paths.Firmware)" -ForegroundColor Cyan
    Write-Host "  5. Führen Sie dieses Skript erneut aus" -ForegroundColor White
    Write-Host ""
    Write-Host "Weitere Details finden Sie in: docs/FIRMWARE-GUIDE.md" -ForegroundColor $Colors.Info
    Write-Host ""
}

function Find-FirmwareFile {
    <#
    .SYNOPSIS
    Sucht nach Firmware-Dateien im Firmware-Verzeichnis
    #>
    Write-Log "Suche nach Firmware-Dateien..." "Info"
    
    $firmwareFiles = @()
    $firmwareFiles += Get-ChildItem -Path $Paths.Firmware -Filter "*.pac" -ErrorAction SilentlyContinue
    $firmwareFiles += Get-ChildItem -Path $Paths.Firmware -Filter "*.zip" -ErrorAction SilentlyContinue
    
    if ($firmwareFiles.Count -eq 0) {
        Write-Log "Keine Firmware-Dateien gefunden in: $($Paths.Firmware)" "Warning"
        return $null
    }
    
    if ($firmwareFiles.Count -eq 1) {
        Write-Log "Firmware gefunden: $($firmwareFiles[0].Name)" "Success"
        return $firmwareFiles[0]
    }
    
    # Mehrere Dateien gefunden - Benutzer wählen lassen
    Write-Host ""
    Write-Host "Mehrere Firmware-Dateien gefunden:" -ForegroundColor $Colors.Prompt
    for ($i = 0; $i -lt $firmwareFiles.Count; $i++) {
        $file = $firmwareFiles[$i]
        $size = "{0:N2} MB" -f ($file.Length / 1MB)
        Write-Host "  $($i + 1). $($file.Name) ($size)" -ForegroundColor White
    }
    Write-Host ""
    
    do {
        [int]$selection = Read-Host "Wählen Sie die Firmware (1-$($firmwareFiles.Count))"
        if ($selection -ge 1 -and $selection -le $firmwareFiles.Count) {
            return $firmwareFiles[$selection - 1]
        }
        Write-Host "Ungültige Auswahl" -ForegroundColor $Colors.Warning
    } while ($true)
}

function Verify-Firmware {
    <#
    .SYNOPSIS
    Überprüft Firmware-Datei
    #>
    param([System.IO.FileInfo]$FirmwareFile)
    
    Write-Log "Überprüfe Firmware-Datei: $($FirmwareFile.Name)" "Info"
    
    # Größenprüfung (Firmware sollte mindestens 500 MB sein)
    $minSize = 500 * 1MB
    if ($FirmwareFile.Length -lt $minSize) {
        Write-Log "WARNUNG: Firmware-Datei erscheint zu klein ($(($FirmwareFile.Length / 1MB).ToString('N2')) MB)" "Warning"
        if (-not (Confirm-Action "Trotzdem fortfahren?")) {
            return $false
        }
    }
    
    # Versuche Hash zu finden (falls Benutzer .md5 oder .sha256 Datei bereitgestellt hat)
    $hashFile = "$($FirmwareFile.FullName).sha256"
    if (Test-Path $hashFile) {
        $expectedHash = (Get-Content $hashFile).Trim()
        Write-Log "Hash-Datei gefunden, führe Überprüfung durch..." "Info"
        
        if (-not (Check-Hash -FilePath $FirmwareFile.FullName -ExpectedHash $expectedHash -Description "Firmware")) {
            Write-Log "Firmware Hash-Überprüfung fehlgeschlagen!" "Error"
            return $false
        }
    }
    else {
        Write-Log "Keine Hash-Datei gefunden - Überprüfung übersprungen" "Warning"
        Write-Log "Tipp: Erstellen Sie eine .sha256 Datei neben der Firmware für automatische Überprüfung" "Info"
    }
    
    Write-Log "Firmware-Überprüfung abgeschlossen" "Success"
    return $true
}

# ============================================================================
# FLASHING-PROZESS
# ============================================================================

function Show-FlashingGuide {
    <#
    .SYNOPSIS
    Zeigt detaillierte Schritt-für-Schritt-Anleitung für den Flash-Prozess
    #>
    param([System.IO.FileInfo]$FirmwareFile)
    
    Write-Header "SPD Flash Tool - Flash-Anleitung"
    
    Write-Host ""
    Write-Host "Das SPD Flash Tool ist GUI-basiert. Folgen Sie diesen Schritten:" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host ""
    
    Write-Host "SCHRITT 1: SPD Flash Tool starten" -ForegroundColor $Colors.Header
    Write-Host "  • Das Tool wird automatisch geöffnet" -ForegroundColor White
    Write-Host "  • Warten Sie, bis die Oberfläche vollständig geladen ist" -ForegroundColor White
    Write-Host ""
    
    Write-Host "SCHRITT 2: Firmware-Datei laden" -ForegroundColor $Colors.Header
    Write-Host "  • Klicken Sie auf 'Load Packet' oder 'PAC öffnen'" -ForegroundColor White
    Write-Host "  • Navigieren Sie zu:" -ForegroundColor White
    Write-Host "    $($FirmwareFile.FullName)" -ForegroundColor Cyan
    Write-Host "  • Wählen Sie die .PAC Datei aus" -ForegroundColor White
    Write-Host "  • Warten Sie, bis die Datei geladen ist" -ForegroundColor White
    Write-Host ""
    
    Write-Host "SCHRITT 3: Gerät in Download-Modus versetzen" -ForegroundColor $Colors.Header
    Write-Host "  • Schalten Sie Ihr Realme C63 KOMPLETT aus" -ForegroundColor Yellow
    Write-Host "  • Halten Sie die Volume DOWN (Leiser) Taste gedrückt" -ForegroundColor Yellow
    Write-Host "  • Verbinden Sie das USB-Kabel mit dem PC" -ForegroundColor Yellow
    Write-Host "  • Halten Sie Volume DOWN weiter gedrückt (ca. 5 Sekunden)" -ForegroundColor Yellow
    Write-Host "  • Das Gerät sollte nun im Download-Modus sein" -ForegroundColor White
    Write-Host "  • SPD Flash Tool sollte das Gerät erkennen" -ForegroundColor White
    Write-Host ""
    
    Write-Host "SCHRITT 4: Flash-Prozess starten" -ForegroundColor $Colors.Header
    Write-Host "  • Überprüfen Sie, dass das Gerät erkannt wurde" -ForegroundColor White
    Write-Host "  • Klicken Sie auf 'Start' oder 'Download' Button" -ForegroundColor White
    Write-Host "  • NICHT das USB-Kabel entfernen während des Flashens!" -ForegroundColor Red
    Write-Host "  • Warten Sie auf die Meldung 'Passed' oder 'Download Success'" -ForegroundColor White
    Write-Host "  • Dies kann 5-15 Minuten dauern" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "SCHRITT 5: Gerät neu starten" -ForegroundColor $Colors.Header
    Write-Host "  • Nach erfolgreichem Flash: USB-Kabel entfernen" -ForegroundColor White
    Write-Host "  • Halten Sie Power-Taste für 10 Sekunden gedrückt" -ForegroundColor White
    Write-Host "  • Gerät sollte neu starten" -ForegroundColor White
    Write-Host "  • Erster Boot kann 5-10 Minuten dauern - NICHT unterbrechen!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host ""
    Write-Host "Bei Problemen siehe: docs/TROUBLESHOOTING.md" -ForegroundColor $Colors.Info
    Write-Host ""
}

function Start-SPDFlashTool {
    <#
    .SYNOPSIS
    Startet das SPD Flash Tool
    #>
    Write-Log "Starte SPD Flash Tool..." "Info"
    
    # Suche nach SPD Flash Tool Executable
    $exeFiles = Get-ChildItem -Path $Paths.SPDFlashTool -Filter "*.exe" -Recurse
    
    if (-not $exeFiles) {
        Write-Log "SPD Flash Tool Executable nicht gefunden" "Error"
        Write-Log "Verzeichnis: $($Paths.SPDFlashTool)" "Info"
        return $false
    }
    
    # Bevorzuge ResearchDownload.exe oder SPD_Upgrade_Tool.exe
    $toolExe = $exeFiles | Where-Object { 
        $_.Name -like "*Research*" -or 
        $_.Name -like "*SPD*" -or 
        $_.Name -like "*Upgrade*" 
    } | Select-Object -First 1
    
    if (-not $toolExe) {
        $toolExe = $exeFiles[0]
    }
    
    Write-Log "Verwende: $($toolExe.Name)" "Info"
    
    try {
        Start-Process -FilePath $toolExe.FullName -WorkingDirectory $toolExe.Directory
        Write-Log "SPD Flash Tool wurde gestartet" "Success"
        return $true
    }
    catch {
        Write-Log "Fehler beim Starten des SPD Flash Tools: $_" "Error"
        return $false
    }
}

# ============================================================================
# SICHERHEITSWARNUNGEN
# ============================================================================

function Show-ImportantWarnings {
    <#
    .SYNOPSIS
    Zeigt wichtige Warnungen an
    #>
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                    WICHTIGE WARNUNGEN                        ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  DATENVERLUST:" -ForegroundColor Yellow
    Write-Host "    Das Flashen der Firmware löscht ALLE Daten auf Ihrem Gerät!" -ForegroundColor White
    Write-Host "    Erstellen Sie VORHER ein vollständiges Backup!" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  GARANTIEVERLUST:" -ForegroundColor Yellow
    Write-Host "    Das Flashen kann die Herstellergarantie ungültig machen!" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  WIDEVINE DRM:" -ForegroundColor Yellow
    Write-Host "    Nach dem Flashen funktioniert HD-Streaming (Netflix, etc.)" -ForegroundColor White
    Write-Host "    möglicherweise nur in SD-Qualität (Widevine L3)!" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  RISIKO:" -ForegroundColor Yellow
    Write-Host "    Falsches Vorgehen kann Ihr Gerät unbrauchbar machen (Brick)!" -ForegroundColor White
    Write-Host "    Folgen Sie der Anleitung genau!" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  STROM & VERBINDUNG:" -ForegroundColor Yellow
    Write-Host "    Stellen Sie sicher, dass:" -ForegroundColor White
    Write-Host "    • Akku mindestens 70% geladen ist" -ForegroundColor White
    Write-Host "    • USB-Kabel stabil verbunden ist" -ForegroundColor White
    Write-Host "    • PC nicht in den Standby geht" -ForegroundColor White
    Write-Host ""
}

function Confirm-Backup {
    <#
    .SYNOPSIS
    Bestätigung dass Backup erstellt wurde
    #>
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Warning
    Write-Host "                      BACKUP-BESTÄTIGUNG" -ForegroundColor $Colors.Warning
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Warning
    Write-Host ""
    Write-Host "Haben Sie ein vollständiges Backup Ihrer Daten erstellt?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Das sollte beinhalten:" -ForegroundColor White
    Write-Host "  • Fotos und Videos" -ForegroundColor Gray
    Write-Host "  • Kontakte und Nachrichten" -ForegroundColor Gray
    Write-Host "  • Apps und App-Daten" -ForegroundColor Gray
    Write-Host "  • Dokumente und Downloads" -ForegroundColor Gray
    Write-Host ""
    
    if ($ForceNoPrompt) {
        Write-Log "Backup-Bestätigung übersprungen (ForceNoPrompt)" "Warning"
        return $true
    }
    
    do {
        $response = Read-Host "Backup erstellt? (JA/nein)"
        if ($response -match '^(JA|YES)$') {
            Write-Log "Backup bestätigt" "Info"
            return $true
        }
        elseif ($response -match '^[Nn]') {
            Write-Host ""
            Write-Host "Bitte erstellen Sie ZUERST ein Backup!" -ForegroundColor Red
            Write-Host "Drücken Sie Strg+C zum Abbrechen" -ForegroundColor Yellow
            Write-Host ""
            Start-Sleep -Seconds 2
        }
        else {
            Write-Host "Bitte geben Sie 'JA' ein, um zu bestätigen" -ForegroundColor Yellow
        }
    } while ($true)
}

# ============================================================================
# HAUPTFUNKTION
# ============================================================================

function Show-Banner {
    <#
    .SYNOPSIS
    Zeigt Startbanner an
    #>
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║        REALME C63 (RMX3939) - INSTALLATION TOOL              ║" -ForegroundColor Cyan
    Write-Host "║          Vollautomatische Windows 11 Installation            ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║               Unisoc/Spreadtrum Chipset                      ║" -ForegroundColor Cyan
    Write-Host "║                  Version $Script:ScriptVersion                           ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Main {
    <#
    .SYNOPSIS
    Haupteinstiegspunkt des Skripts
    #>
    try {
        # Banner anzeigen
        Show-Banner
        
        Write-Log "Installation gestartet" "Info"
        Write-Log "Version: $Script:ScriptVersion" "Info"
        Write-Log "Arbeitsverzeichnis: $WorkDir" "Info"
        Write-Log "Log-Datei: $LogFile" "Info"
        
        # Administrator-Rechte prüfen
        if (-not (Test-AdminPrivileges)) {
            Write-Log "FEHLER: Dieses Skript benötigt Administrator-Rechte!" "Error"
            Write-Host ""
            Write-Host "Bitte führen Sie PowerShell als Administrator aus:" -ForegroundColor Yellow
            Write-Host "  1. Rechtsklick auf PowerShell" -ForegroundColor White
            Write-Host "  2. 'Als Administrator ausführen' wählen" -ForegroundColor White
            Write-Host "  3. Dieses Skript erneut starten" -ForegroundColor White
            Write-Host ""
            Read-Host "Drücken Sie Enter zum Beenden"
            exit 1
        }
        
        Write-Log "Administrator-Rechte verifiziert ✓" "Success"
        
        # Windows-Version prüfen
        if (-not (Test-WindowsVersion)) {
            Write-Log "WARNUNG: Windows 11 wird empfohlen" "Warning"
            Write-Log "Ihr System: Windows $([System.Environment]::OSVersion.Version)" "Info"
            
            if (-not (Confirm-Action "Trotzdem fortfahren?")) {
                exit 1
            }
        }
        else {
            Write-Log "Windows 11 erkannt ✓" "Success"
        }
        
        # Konfiguration laden
        Write-Header "Konfiguration laden"
        $Script:Config = Read-Config -Path $ConfigPath
        
        # Verzeichnisse erstellen
        Write-Header "Arbeitsverzeichnisse einrichten"
        New-DirectoryStructure
        
        # Wichtige Warnungen anzeigen
        Show-ImportantWarnings
        
        if (-not (Confirm-Action "Haben Sie die Warnungen gelesen und verstanden?")) {
            Write-Log "Installation abgebrochen" "Info"
            exit 0
        }
        
        # Backup-Bestätigung
        if (-not (Confirm-Backup)) {
            exit 0
        }
        
        # SPD USB-Treiber installieren
        if (-not (Install-SPDDrivers)) {
            Write-Log "SPD-Treiber Installation fehlgeschlagen" "Warning"
            if (-not (Confirm-Action "Ohne SPD-Treiber fortfahren? (Nicht empfohlen)")) {
                exit 1
            }
        }
        
        # Realme USB-Treiber installieren
        if (-not (Install-RealmeDrivers)) {
            Write-Log "Realme-Treiber Installation fehlgeschlagen" "Warning"
            if (-not (Confirm-Action "Ohne Realme-Treiber fortfahren?")) {
                exit 1
            }
        }
        
        # Treiberinstallation überprüfen
        if (-not $SkipDriverInstall) {
            Test-DriverInstallation | Out-Null
        }
        
        # SPD Flash Tool einrichten
        if (-not (Setup-SPDFlashTool)) {
            Write-Log "SPD Flash Tool Setup fehlgeschlagen" "Error"
            exit 1
        }
        
        # ADB Tools installieren (optional)
        Install-ADBTools | Out-Null
        
        # Firmware suchen
        Write-Header "Firmware-Überprüfung"
        $firmwareFile = Find-FirmwareFile
        
        if (-not $firmwareFile) {
            Show-FirmwareGuide
            
            Write-Host ""
            Write-Host "Bitte laden Sie die Firmware herunter und legen Sie sie ab in:" -ForegroundColor Yellow
            Write-Host "$($Paths.Firmware)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Führen Sie dann dieses Skript erneut aus." -ForegroundColor Yellow
            Write-Host ""
            
            # Firmware-Ordner öffnen
            if (Confirm-Action "Firmware-Ordner jetzt öffnen?") {
                Start-Process explorer.exe -ArgumentList $Paths.Firmware
            }
            
            Read-Host "Drücken Sie Enter zum Beenden"
            exit 0
        }
        
        # Firmware verifizieren
        if (-not (Verify-Firmware -FirmwareFile $firmwareFile)) {
            Write-Log "Firmware-Überprüfung fehlgeschlagen" "Error"
            exit 1
        }
        
        # Flash-Anleitung anzeigen
        Show-FlashingGuide -FirmwareFile $firmwareFile
        
        if (-not (Confirm-Action "Bereit zum Flashen? SPD Flash Tool wird jetzt gestartet...")) {
            Write-Log "Flash-Prozess abgebrochen" "Info"
            exit 0
        }
        
        # SPD Flash Tool starten
        if (-not (Start-SPDFlashTool)) {
            Write-Log "SPD Flash Tool konnte nicht gestartet werden" "Error"
            Write-Log "Bitte starten Sie das Tool manuell aus: $($Paths.SPDFlashTool)" "Info"
        }
        
        # Abschlussmeldung
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                    INSTALLATION VORBEREITET                  ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Das SPD Flash Tool wurde gestartet." -ForegroundColor White
        Write-Host "Folgen Sie der oben gezeigten Anleitung für den Flash-Prozess." -ForegroundColor White
        Write-Host ""
        Write-Host "Wichtige Dateien:" -ForegroundColor Cyan
        Write-Host "  • Firmware: $($firmwareFile.FullName)" -ForegroundColor Gray
        Write-Host "  • SPD Tool: $($Paths.SPDFlashTool)" -ForegroundColor Gray
        Write-Host "  • Log-Datei: $LogFile" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Bei Problemen siehe:" -ForegroundColor Yellow
        Write-Host "  • docs/TROUBLESHOOTING.md" -ForegroundColor White
        Write-Host "  • docs/FIRMWARE-GUIDE.md" -ForegroundColor White
        Write-Host ""
        Write-Host "Viel Erfolg!" -ForegroundColor Green
        Write-Host ""
        
        Write-Log "Installation erfolgreich vorbereitet" "Success"
        
        Read-Host "Drücken Sie Enter zum Beenden"
        exit 0
    }
    catch {
        Write-Log "FATALER FEHLER: $_" "Error"
        Write-Log $_.ScriptStackTrace "Error"
        Write-Host ""
        Write-Host "Ein kritischer Fehler ist aufgetreten!" -ForegroundColor Red
        Write-Host "Details finden Sie in der Log-Datei:" -ForegroundColor Yellow
        Write-Host "$LogFile" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Drücken Sie Enter zum Beenden"
        exit 1
    }
}

# ============================================================================
# SKRIPT AUSFÜHREN
# ============================================================================

Main
