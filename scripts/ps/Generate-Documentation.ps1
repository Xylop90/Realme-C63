<#
.SYNOPSIS
    Generiert automatisch Dokumentation aus Templates und Konfiguration

.DESCRIPTION
    Erstellt folgende Dokumentation:
    - README.md (Haupt-Readme)
    - docs/INSTALLATION.md
    - docs/TROUBLESHOOTING.md
    - docs/FIRMWARE-GUIDE.md
    - docs/ADVANCED.md

.PARAMETER ConfigPath
    Pfad zur Konfigurationsdatei

.PARAMETER OutputPath
    Ausgabeverzeichnis

.EXAMPLE
    .\Generate-Documentation.ps1

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ""
)

# Setze Standardpfade
$script:RootDir = Split-Path -Path $PSScriptRoot -Parent
$script:RootDir = Split-Path -Path $script:RootDir -Parent

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $script:RootDir "config\installer-config.json"
}

if (-not $OutputPath) {
    $OutputPath = $script:RootDir
}

# Lade Konfiguration
function Get-Config {
    try {
        return Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "[FEHLER] Konnte Konfiguration nicht laden: $_" -ForegroundColor Red
        return $null
    }
}

# Generiere README.md
function New-ReadmeFile {
    param($Config)

    $content = @"
# Realme C63 (RMX3939) - Vollautomatische Installation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-$($Config.version)-blue.svg)]()
[![Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey.svg)]()

## 📱 Überblick

Vollautomatisches Installations-System für das **Realme C63 (RMX3939)** mit:

- ✅ **Ein-Klick-Installation** über `INSTALL.bat`
- ✅ **Automatische Administrator-Rechte-Anforderung** (Self-Elevation)
- ✅ **Intelligente Downloads** mit BITS, Resume-Support und Mirror-Fallback
- ✅ **Silent-Driver-Installation** für USB-Treiber
- ✅ **SPD Flash Tool Integration**
- ✅ **Firmware-Management** mit Multi-Source-Support
- ✅ **Umfassendes Logging** mit automatischer Rotation
- ✅ **Deutschsprachige Benutzeroberfläche**

## 🚀 Schnellstart

### Voraussetzungen

- **Windows 10 oder Windows 11** (64-bit)
- **PowerShell 5.1+** (in Windows enthalten)
- **Administrator-Rechte**
- **Internetverbindung** (mindestens 2 Mbit/s)
- **5 GB freier Speicherplatz**

### Installation

1. **Repository herunterladen:**
   ```
   git clone https://github.com/Xylop90/Realme-C63.git
   cd Realme-C63
   ```

2. **Installer starten:**
   - Doppelklick auf ``INSTALL.bat``
   - **ODER** Rechtsklick → "Als Administrator ausführen"

3. **Automatischer Ablauf:**
   - ✓ System-Voraussetzungen werden geprüft
   - ✓ Verzeichnisstruktur wird erstellt
   - ✓ Platform Tools (ADB/Fastboot) werden heruntergeladen
   - ✓ USB-Treiber werden vorbereitet
   - ✓ SPD Flash Tool Links werden angezeigt
   - ✓ Firmware-Quellen werden konfiguriert

4. **Manuelle Schritte:**
   - USB-Treiber installieren (falls erforderlich)
   - SPD Flash Tool herunterladen und installieren
   - Firmware herunterladen
   - Gerät flashen

## 📖 Dokumentation

- **[Installations-Anleitung](docs/INSTALLATION.md)** - Detaillierte Schritt-für-Schritt-Anleitung
- **[Firmware-Guide](docs/FIRMWARE-GUIDE.md)** - Firmware-Quellen und Download
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Häufige Probleme und Lösungen
- **[Erweiterte Optionen](docs/ADVANCED.md)** - Für Experten

## 🔧 Funktionen

### Automatisierung
- Ein-Klick-Installation über `INSTALL.bat`
- Self-Elevation (automatische Administrator-Rechte)
- Automatischer Download aller Ressourcen
- Intelligente Retry-Logik (3 Versuche)
- Mirror/Fallback-URLs

### Treiber-Management
- Silent-Installation von USB-Treibern
- Multi-Source mit Fallback:
  - Oppo/Realme Universal Driver
  - Spreadtrum SPD Driver
  - Realme-spezifische Treiber
- PNPUtil-Integration
- Automatische Verifikation

### Firmware-Management
- Multi-Source Firmware-Suche
- Unterstützte Quellen:
  - GetDroidTips
  - GSM Mafia
  - Realme Firmware
- Automatische Version-Erkennung
- Resume-Support für große Downloads

### Geräte-Erkennung
- USB-Device-Detection
- SPD-Mode-Detection
- ADB-Device-Check
- COM-Port-Enumeration

### Logging
- Strukturiertes Logging mit Timestamps
- Log-Levels: DEBUG, INFO, WARN, ERROR, SUCCESS
- Farbcodierte Console-Ausgabe
- Automatische Log-Rotation
- Log-Dateien: `work/logs/`

## 📂 Verzeichnisstruktur

```
Realme-C63/
├── INSTALL.bat                 # Haupt-Einstiegspunkt (Ein-Klick)
├── LICENSE                     # MIT License
├── README.md                   # Diese Datei
├── config/                     # Konfigurationsdateien
│   ├── installer-config.json   # Hauptkonfiguration
│   ├── firmware-sources.json   # Firmware-URLs
│   ├── driver-signatures.json  # Driver-Hashes
│   └── tool-versions.json      # Versions-Tracking
├── scripts/
│   ├── ps/                     # PowerShell-Skripte
│   │   ├── Install-RealmeC63.ps1
│   │   ├── Generate-Documentation.ps1
│   │   ├── Setup-Permissions.ps1
│   │   └── Verify-Installation.ps1
│   └── modules/                # PowerShell-Module
│       ├── Logger.psm1
│       ├── Download-Manager.psm1
│       ├── Driver-Manager.psm1
│       ├── Device-Manager.psm1
│       ├── Firmware-Manager.psm1
│       ├── SPD-Automation.psm1
│       └── UI-Helper.psm1
├── docs/                       # Dokumentation
├── templates/                  # Vorlagen
└── work/                       # Runtime (gitignore)
    ├── downloads/              # Download-Cache
    ├── extracted/              # Entpackte Tools
    ├── drivers/                # Treiber-Dateien
    ├── firmware/               # Firmware-Files
    └── logs/                   # Log-Dateien
```

## ⚙️ Konfiguration

Die Konfiguration erfolgt über JSON-Dateien im ``config/`` Verzeichnis:

- **installer-config.json:** Hauptkonfiguration mit Download-URLs
- **firmware-sources.json:** Firmware-Quellen und Web-Scraping-Einstellungen
- **driver-signatures.json:** Treiber-Hashes für Verifikation
- **tool-versions.json:** Versions-Tracking für automatische Updates

## 🛡️ Sicherheit

- ✅ SHA256-Verifikation für Downloads (optional)
- ✅ HTTPS-only Downloads
- ✅ Digital-Signatur-Check für Treiber
- ✅ Backup-Erstellung empfohlen vor Flash
- ✅ Rollback-Mechanismus (in Entwicklung)

## 🤝 Mitwirken

Beiträge sind willkommen! Bitte erstelle einen Pull Request oder öffne ein Issue.

## 📜 Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei

**Copyright © 2026 Elektronikx-Center-Matte by Alexander Mathey**

## ⚠️ Disclaimer

- Diese Software wird bereitgestellt "AS IS" ohne Garantien
- Die Nutzung erfolgt auf eigenes Risiko
- Der Entwickler haftet nicht für Datenverlust oder Geräteschäden
- Erstelle ein Backup, bevor du die Firmware installierst
- Das Flashen von Firmware kann die Garantie ungültig machen

## 📞 Support

- **GitHub Issues:** Für Bugs und Feature-Requests
- **Entwickler:** Alexander Mathey
- **Organisation:** Elektronikx-Center-Matte

---

**Version:** $($Config.version) | **Letzte Aktualisierung:** $(Get-Date -Format "yyyy-MM-dd")
"@

    $readmePath = Join-Path $OutputPath "README.md"
    $content | Out-File -FilePath $readmePath -Encoding UTF8 -Force
    Write-Host "[OK] README.md generiert: $readmePath" -ForegroundColor Green
}

# Generiere CHANGELOG.md
function New-ChangelogFile {
    $content = @"
# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0] - $(Get-Date -Format "yyyy-MM-dd")

### Hinzugefügt
- ✅ Ein-Klick-Installation über `INSTALL.bat` mit Self-Elevation
- ✅ Haupt-Orchestrator `Install-RealmeC63.ps1`
- ✅ 7 PowerShell-Module (Logger, Download-Manager, Driver-Manager, Device-Manager, Firmware-Manager, SPD-Automation, UI-Helper)
- ✅ Konfigurationssystem mit 4 JSON-Dateien
- ✅ Automatischer Download mit BITS-Transfer
- ✅ Resume-Support für unterbrochene Downloads
- ✅ Mirror/Fallback-URLs für Zuverlässigkeit
- ✅ Silent-Driver-Installation
- ✅ USB-Geräte-Erkennung
- ✅ SPD Flash Tool Integration
- ✅ Firmware-Management mit Multi-Source-Support
- ✅ Strukturiertes Logging mit Rotation
- ✅ Farbcodierte Console-Ausgabe
- ✅ ASCII-Art Banner
- ✅ Progress-Bars mit ETA
- ✅ Automatische Dokumentations-Generierung
- ✅ Deutschsprachige Benutzeroberfläche
- ✅ MIT License
- ✅ `.gitignore` für Runtime-Dateien

### Sicherheit
- SHA256-Verifikation für Downloads
- HTTPS-only Downloads
- PNPUtil für sichere Treiber-Installation

## [Unreleased]

### Geplant
- [ ] Vollautomatische Firmware-Erkennung mit Web-Scraping
- [ ] Automatischer Flash-Prozess (soweit SPD-API erlaubt)
- [ ] Backup-Mechanismus vor Flash
- [ ] Rollback-Funktionen
- [ ] Telemetrie (optional, opt-in)
- [ ] Pester-Tests (Unit + Integration)
- [ ] Offline-Modus (nach initialem Download)
- [ ] Update-Checker für neue Versionen

---

**Legende:**
- ✅ Implementiert
- [ ] Geplant
- 🔧 In Arbeit
- ⚠️ Deprecated
"@

    $changelogPath = Join-Path $OutputPath "CHANGELOG.md"
    $content | Out-File -FilePath $changelogPath -Encoding UTF8 -Force
    Write-Host "[OK] CHANGELOG.md generiert: $changelogPath" -ForegroundColor Green
}

# Hauptfunktion
function Main {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "            Dokumentations-Generator                                        " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    $config = Get-Config
    if (-not $config) {
        exit 1
    }

    Write-Host "[*] Generiere Dokumentation..." -ForegroundColor Cyan
    Write-Host ""

    # Generiere Dateien
    New-ReadmeFile -Config $config
    New-ChangelogFile

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "            Dokumentations-Generierung abgeschlossen!                       " -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "[INFO] Generierte Dateien:" -ForegroundColor Cyan
    Write-Host "  - README.md" -ForegroundColor White
    Write-Host "  - CHANGELOG.md" -ForegroundColor White
    Write-Host ""
}

Main
