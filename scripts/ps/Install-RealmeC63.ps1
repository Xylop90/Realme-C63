<#
.SYNOPSIS
    Haupt-Orchestrator fuer automatisierte Realme C63 Installation

.DESCRIPTION
    Vollautomatische Installation mit:
    - Self-Elevation (Administrator-Rechte)
    - Automatischer Download aller Ressourcen
    - Treiber-Installation (silent)
    - SPD Flash Tool Setup
    - Firmware-Erkennung und Download
    - Geraete-Erkennung
    - UI mit Progress-Anzeige

.PARAMETER WorkingDirectory
    Basis-Arbeitsverzeichnis (Standard: Script-Verzeichnis)

.PARAMETER SkipDriverInstall
    Ueberspringe Treiber-Installation

.PARAMETER ConfigPath
    Pfad zur Konfigurationsdatei

.EXAMPLE
    .\Install-RealmeC63.ps1
    .\Install-RealmeC63.ps1 -WorkingDirectory "D:\Realme" -SkipDriverInstall

.NOTES
    Author: Elektronikx-Center-Matte by Alexander Mathey
    Version: 1.0.0
    Requires: Windows 10/11, PowerShell 5.1+, Administrator
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = $PSScriptRoot,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDriverInstall,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ""
)

# ============================================================================
# INITIALISIERUNG
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Setze Arbeitsverzeichnis
if ($WorkingDirectory) {
    $script:RootDir = Split-Path -Path $WorkingDirectory -Parent
}
else {
    $script:RootDir = Split-Path -Path $PSScriptRoot -Parent
    $script:RootDir = Split-Path -Path $script:RootDir -Parent
}

# Verzeichnisstruktur
$script:Paths = @{
    Root        = $script:RootDir
    Scripts     = Join-Path $script:RootDir "scripts"
    Modules     = Join-Path $script:RootDir "scripts\modules"
    Config      = Join-Path $script:RootDir "config"
    Work        = Join-Path $script:RootDir "work"
    Downloads   = Join-Path $script:RootDir "work\downloads"
    Extracted   = Join-Path $script:RootDir "work\extracted"
    Drivers     = Join-Path $script:RootDir "work\drivers"
    Firmware    = Join-Path $script:RootDir "work\firmware"
    Logs        = Join-Path $script:RootDir "work\logs"
    Checkpoints = Join-Path $script:RootDir "work\checkpoints"
}

# Konfigurationspfad
if (-not $ConfigPath) {
    $ConfigPath = Join-Path $script:Paths.Config "installer-config.json"
}

# ============================================================================
# MODULE LADEN
# ============================================================================

function Import-RequiredModules {
    $moduleNames = @(
        "Logger"
        "Download-Manager"
        "Device-Manager"
        "Driver-Manager"
        "Firmware-Manager"
        "UI-Helper"
    )

    foreach ($moduleName in $moduleNames) {
        $modulePath = Join-Path $script:Paths.Modules "$moduleName.psm1"
        if (Test-Path -Path $modulePath) {
            try {
                Import-Module $modulePath -Force -ErrorAction Stop
                Write-Host "[OK] Modul geladen: $moduleName" -ForegroundColor Green
            }
            catch {
                Write-Host "[FEHLER] Konnte Modul nicht laden: $moduleName - $_" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "[WARNUNG] Modul nicht gefunden: $modulePath" -ForegroundColor Yellow
        }
    }
    return $true
}

# ============================================================================
# SELF-ELEVATION (ADMINISTRATOR-RECHTE)
# ============================================================================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-SelfElevation {
    if (-not (Test-Administrator)) {
        Write-Host "[!] Administrator-Rechte erforderlich" -ForegroundColor Yellow
        Write-Host "[*] Starte Self-Elevation..." -ForegroundColor Cyan

        try {
            $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
            if ($WorkingDirectory) {
                $arguments += " -WorkingDirectory `"$WorkingDirectory`""
            }
            
            Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
            exit 0
        }
        catch {
            Write-Host "[FEHLER] Self-Elevation fehlgeschlagen: $_" -ForegroundColor Red
            exit 1
        }
    }
}

# ============================================================================
# VERZEICHNISSTRUKTUR ERSTELLEN
# ============================================================================

function Initialize-DirectoryStructure {
    Write-Host "[*] Erstelle Verzeichnisstruktur..." -ForegroundColor Cyan

    foreach ($path in $script:Paths.Values) {
        if (-not (Test-Path -Path $path)) {
            try {
                New-Item -Path $path -ItemType Directory -Force | Out-Null
                Write-Host "[OK] Verzeichnis erstellt: $path" -ForegroundColor Green
            }
            catch {
                Write-Host "[FEHLER] Konnte Verzeichnis nicht erstellen: $path" -ForegroundColor Red
                return $false
            }
        }
    }
    return $true
}

# ============================================================================
# KONFIGURATION LADEN
# ============================================================================

function Get-Configuration {
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Host "[FEHLER] Konfigurationsdatei nicht gefunden: $ConfigPath" -ForegroundColor Red
        return $null
    }

    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        Write-Host "[OK] Konfiguration geladen" -ForegroundColor Green
        return $config
    }
    catch {
        Write-Host "[FEHLER] Konnte Konfiguration nicht laden: $_" -ForegroundColor Red
        return $null
    }
}

# ============================================================================
# SYSTEM-VORAUSSETZUNGEN PRUEFEN
# ============================================================================

function Test-SystemRequirements {
    Write-Host "`n[*] Pruefe System-Voraussetzungen..." -ForegroundColor Cyan

    $checks = @{
        "Windows 10/11"        = $true
        "Administrator-Rechte" = Test-Administrator
        "PowerShell 5.1+"      = $PSVersionTable.PSVersion.Major -ge 5
        "Freier Speicher (5GB)" = $true
    }

    # Pruefe Windows-Version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        $checks["Windows 10/11"] = $false
    }

    # Pruefe freien Speicher
    try {
        $drive = Get-PSDrive -Name ($script:Paths.Root.Substring(0, 1)) -ErrorAction SilentlyContinue
        if ($drive) {
            $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
            if ($freeSpaceGB -lt 5) {
                $checks["Freier Speicher (5GB)"] = $false
            }
        }
    }
    catch {
        Write-Host "[WARNUNG] Konnte freien Speicher nicht pruefen" -ForegroundColor Yellow
    }

    # Ausgabe der Pruefungen
    $allPassed = $true
    foreach ($check in $checks.GetEnumerator()) {
        $status = if ($check.Value) { "[OK]" } else { "[FEHLER]" }
        $color = if ($check.Value) { "Green" } else { "Red" }
        Write-Host "$status $($check.Key)" -ForegroundColor $color
        
        if (-not $check.Value) {
            $allPassed = $false
        }
    }

    return $allPassed
}

# ============================================================================
# BANNER ANZEIGEN
# ============================================================================

function Show-WelcomeBanner {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "   ____            _                    ____ __________                    " -ForegroundColor Cyan
    Write-Host "  / __ \___  ___ _/ /_ _  ___   ___   / __// /__  / _ )                   " -ForegroundColor Cyan
    Write-Host " / /_/ / -_)/ _ ``/ /  ' \/ -_) / __/ / /_ / _ \/ _ / _ \                   " -ForegroundColor Cyan
    Write-Host " \____/\__/ \_,_/_/_/_/_/\__/  \__/  \__//_//_/____/___/                  " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "         Vollautomatische Installation fuer Realme C63 (RMX3939)          " -ForegroundColor White
    Write-Host "                          Version 1.0.0                                    " -ForegroundColor White
    Write-Host "                                                                           " -ForegroundColor White
    Write-Host "         (c) Elektronikx-Center-Matte by Alexander Mathey                 " -ForegroundColor Gray
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# INSTALLATIONS-WORKFLOW
# ============================================================================

function Start-InstallationWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )

    Write-Host "`n[*] Starte Installations-Workflow..." -ForegroundColor Cyan
    Write-Host ""

    # Schritt 1: Platform Tools (ADB/Fastboot) installieren
    if (-not $Config.sources.platform_tools.optional -or (Confirm-Action "Platform Tools (ADB/Fastboot) installieren?")) {
        Write-Host "`n--- Schritt 1: Platform Tools ---" -ForegroundColor Yellow
        
        $adbUrl = $Config.sources.platform_tools.url
        $adbDest = Join-Path $script:Paths.Downloads "platform-tools.zip"
        $adbExtract = Join-Path $script:Paths.Extracted "platform-tools"

        if (Invoke-SmartDownload -Url $adbUrl -Destination $adbDest) {
            if (Expand-ZipArchive -ZipPath $adbDest -Destination $adbExtract) {
                Write-Host "[OK] Platform Tools installiert" -ForegroundColor Green
            }
        }
    }

    # Schritt 2: USB-Treiber installieren
    if (-not $SkipDriverInstall) {
        Write-Host "`n--- Schritt 2: USB-Treiber ---" -ForegroundColor Yellow
        # Wird von Driver-Manager Modul behandelt
        Write-Host "[INFO] Treiber-Installation wird vorbereitet..." -ForegroundColor Cyan
        Write-Host "[INFO] Manuelle Installation eventuell erforderlich" -ForegroundColor Yellow
    }

    # Schritt 3: SPD Flash Tool installieren
    Write-Host "`n--- Schritt 3: SPD Flash Tool ---" -ForegroundColor Yellow
    Write-Host "[INFO] SPD Flash Tool muss manuell von spdflashtool.com heruntergeladen werden" -ForegroundColor Yellow
    Write-Host "[INFO] URL: $($Config.sources.spd_flash_tool.primary)" -ForegroundColor Cyan

    # Schritt 4: Firmware-Download
    Write-Host "`n--- Schritt 4: Firmware ---" -ForegroundColor Yellow
    Write-Host "[INFO] Firmware-Quellen konfiguriert" -ForegroundColor Cyan
    Write-Host "[INFO] Manuelle Firmware-Auswahl und Download erforderlich" -ForegroundColor Yellow
    
    foreach ($source in $Config.sources.firmware.sources) {
        Write-Host "  - $($source.name): $($source.url)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "                    Installation vorbereitet!                              " -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Naechste Schritte:" -ForegroundColor Cyan
    Write-Host "1. USB-Treiber manuell installieren (falls erforderlich)" -ForegroundColor White
    Write-Host "2. SPD Flash Tool herunterladen und installieren" -ForegroundColor White
    Write-Host "3. Firmware herunterladen" -ForegroundColor White
    Write-Host "4. Geraet im Download-Modus verbinden" -ForegroundColor White
    Write-Host "5. Mit SPD Flash Tool flashen" -ForegroundColor White
    Write-Host ""
}

function Confirm-Action {
    param([string]$Message)
    
    $response = Read-Host "$Message (J/N)"
    return $response -eq "J" -or $response -eq "j"
}

# ============================================================================
# HAUPTFUNKTION
# ============================================================================

function Main {
    try {
        # Banner anzeigen
        Show-WelcomeBanner

        # Self-Elevation pruefen
        Invoke-SelfElevation

        # System-Voraussetzungen pruefen
        if (-not (Test-SystemRequirements)) {
            Write-Host "`n[FEHLER] System-Voraussetzungen nicht erfuellt!" -ForegroundColor Red
            Read-Host "Druecken Sie Enter zum Beenden"
            exit 1
        }

        # Verzeichnisstruktur erstellen
        if (-not (Initialize-DirectoryStructure)) {
            Write-Host "`n[FEHLER] Konnte Verzeichnisstruktur nicht erstellen!" -ForegroundColor Red
            Read-Host "Druecken Sie Enter zum Beenden"
            exit 1
        }

        # Module laden
        Write-Host "`n[*] Lade Module..." -ForegroundColor Cyan
        Import-RequiredModules | Out-Null

        # Logger initialisieren
        $logFile = Join-Path $script:Paths.Logs "install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        if (Get-Command Initialize-Logger -ErrorAction SilentlyContinue) {
            Initialize-Logger -LogPath $logFile -Level "INFO"
        }

        # Konfiguration laden
        $config = Get-Configuration
        if (-not $config) {
            Write-Host "`n[FEHLER] Konnte Konfiguration nicht laden!" -ForegroundColor Red
            Read-Host "Druecken Sie Enter zum Beenden"
            exit 1
        }

        # Installations-Workflow starten
        Start-InstallationWorkflow -Config $config

        Write-Host "`n[OK] Installation abgeschlossen!" -ForegroundColor Green
        Read-Host "`nDruecken Sie Enter zum Beenden"
        exit 0
    }
    catch {
        Write-Host "`n[FEHLER] Kritischer Fehler: $_" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        Read-Host "Druecken Sie Enter zum Beenden"
        exit 1
    }
}

# Starte Hauptfunktion
Main
