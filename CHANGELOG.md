# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0] - 2026-01-10

### Hinzugefügt
- ✅ Ein-Klick-Installation über INSTALL.bat mit Self-Elevation
- ✅ Haupt-Orchestrator Install-RealmeC63.ps1
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
- ✅ .gitignore für Runtime-Dateien

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
