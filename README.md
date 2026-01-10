# Xtreme XA-vI ®
**Performance-Optimierte Custom ROM für Realme C63 (RMX3939)**

---

## 📖 Quick Navigation

| Guide | Beschreibung | Status |
|-------|--------------|--------|
| [🔐 Bootloader Unlock](docs/BOOTLOADER_UNLOCK.md) | Bootloader entsperren (7-15 Tage Wartezeit) | ✅ Komplett |
| [🛠️ TWRP Installation](docs/TWRP_INSTALLATION.md) | Custom Recovery installieren | ✅ Komplett |
| [🔑 Rooting Guide](docs/ROOTING_GUIDE.md) | Root mit Magisk (inkl. SafetyNet) | ✅ Komplett |
| [📥 ROM Installation](docs/INSTALLATION.md) | Xtreme XA-vI ROM installieren | ✅ Verfügbar |
| [📝 Changelog](docs/CHANGELOG.md) | Versionshistorie & Updates | ✅ Verfügbar |
| [🛠️ Development](docs/DEVELOPMENT.md) | Entwickler-Dokumentation | ✅ Verfügbar |

## 🆕 NEU: Automatische Stock-Firmware Installation

Vollautomatisches PowerShell-Skript für Windows 11 zum Flashen der offiziellen Stock-Firmware auf dem **Realme C63 (RMX3939)** mit **Unisoc/Spreadtrum-Chipset**!

```powershell
# Einfach ausführen:
.\scripts\ps\install-realme-c63.ps1
```

→ **[Zur Installationsanleitung springen](#-installation)**

---

## 📱 Projektinfo

**ROM Name:** Xtreme XA-vI ®  
**Gerät:** Realme C63  
**Entwickler:** Alexander Mathey - Elektronikx-Center-Matte  
**Copyright:** © Elektronikx-Center-Matte by Alexander Mathey  
**Status:** In Entwicklung 🔧

---

## ✨ Features

- ⚡ Performance-Optimiert für Realme C63
- 🎯 Reduzierte Bloatware
- 🔒 Enhanced Security & Privacy
- 🚀 Schnellere Boot-Zeit
- 📱 Optimierte RAM-Nutzung
- 🎨 Customizable UI Elements
- 🔋 Verbesserte Battery Life

---

## 📋 Voraussetzungen

- **Gerät:** Realme C63 (RMX3939)
- **Android Version:** Android 12 / Realme UI 3.0+
- **TWRP Recovery:** v3.x+ ([TWRP Installations-Guide](docs/TWRP_INSTALLATION.md))
- **ADB & Fastboot** auf dem PC installiert
- **USB-Debugging** aktiviert
- **Bootloader entsperrt** (Siehe Guide unten)
- **Optional:** Root-Zugriff mit Magisk ([Rooting Guide](docs/ROOTING_GUIDE.md))

---

## 🔓 Bootloader Unlock & Root

Bevor du die ROM installieren kannst, musst du deinen Bootloader entsperren und optional dein Gerät rooten:

### Schritt-für-Schritt Guides:

1. 🔐 **[Bootloader Unlock Guide →](docs/BOOTLOADER_UNLOCK.md)**
   - Komplette Anleitung für Realme C63 (RMX3939)
   - Realme-spezifischer Freischaltungsprozess
   - Detaillierte Fehlerbehebung
   - Wartezeit: 7-15 Tage für offizielle Genehmigung

2. 🛠️ **[TWRP Installation →](docs/TWRP_INSTALLATION.md)**
   - Custom Recovery Installation
   - Backup & Restore Funktionen
   - Notwendig für ROM-Installation

3. 🔑 **[Rooting mit Magisk →](docs/ROOTING_GUIDE.md)**
   - Vollständiger Root-Zugriff
   - Magisk Module Support
   - SafetyNet Fix & Banking Apps
   - Sicherheitskonfiguration

⚠️ **WICHTIGE WARNUNGEN:**
- Bootloader-Entsperrung **löscht alle Daten**!
- Garantie wird **ungültig**
- Erstelle vorher ein **Backup**
- Prozess kann **7-15 Tage** dauern (Realme Genehmigung)

---

## 📥 Installation

### Stock-Firmware Installation (Realme C63 RMX3939)

Das Realme C63 (RMX3939) verwendet einen **Unisoc/Spreadtrum-Chipset** und benötigt das **SPD Flash Tool** für die Stock-Firmware-Installation.

#### 🚀 Automatische Installation (Windows 11)

Wir bieten ein vollautomatisches PowerShell-Skript:

```powershell
# PowerShell als Administrator öffnen
cd scripts/ps
.\install-realme-c63.ps1
```

**Features:**
- ✅ Automatischer Download von SPD Flash Tool, Treibern & Firmware
- ✅ SHA256-Hash-Verifikation
- ✅ Treiber-Installation
- ✅ Schritt-für-Schritt-Anweisungen für SPD Flash Tool
- ✅ Detailliertes Logging
- ✅ Cache-System für Downloads

**Parameter:**
```powershell
# Stabile Firmware-Version verwenden
.\install-realme-c63.ps1 -FirmwareVersion stable

# Treiber-Installation überspringen
.\install-realme-c63.ps1 -SkipDriverInstall

# Test-Modus (ohne echtes Flashen)
.\install-realme-c63.ps1 -TestMode
```

#### 📋 Voraussetzungen
- **Windows 11** (oder Windows 10)
- **PowerShell 5.1+**
- **Administrator-Rechte**
- **USB-Kabel** (original oder hochwertig)
- **Akku ≥ 50%** (besser: vollständig geladen)
- **Internetverbindung** (für Downloads, ca. 2-4 GB)

#### ⚠️ WICHTIGE HINWEISE
- ❌ **ALLE DATEN WERDEN GELÖSCHT!** Backup erstellen!
- ✅ Bootloader-Unlock **NICHT** erforderlich
- ⏱️ Dauer: ca. 30-60 Minuten
- 🔌 USB-Kabel während Flash **NICHT** trennen!

#### 📖 Dokumentation
- 📘 **[Fehlerbehebung →](docs/TROUBLESHOOTING.md)** - Lösungen für häufige Probleme
- ❓ **[FAQ →](docs/FAQ.md)** - Häufig gestellte Fragen
- ⚙️ **[Konfiguration →](config/downloads.json)** - Download-Links anpassen

### Custom ROM Installation

Für detaillierte Installations-Anweisungen für Custom ROMs:

👉 **[Zur Installations-Anleitung →](docs/INSTALLATION.md)**

---

## 📝 Changelog

Alle Versionen und Änderungen:

👉 **[Zum Changelog →](docs/CHANGELOG.md)**

---

## 🛠️ Für Entwickler

Wenn du zur Entwicklung beitragen möchtest:

👉 **[Zur Entwickler-Dokumentation →](docs/DEVELOPMENT.md)**

---

## 🤝 Support & Kontakt

- **GitHub Issues:** Für Bugs und Feature-Requests
- **Entwickler:** Alexander Mathey
- **Elektronikx-Center-Matte:** [Link eintragen]

### 📚 Dokumentation & Guides
- [Bootloader Unlock Guide](docs/BOOTLOADER_UNLOCK.md) - Realme C63 (RMX3939)
- [TWRP Installation Guide](docs/TWRP_INSTALLATION.md)
- [Rooting mit Magisk Guide](docs/ROOTING_GUIDE.md)
- [ROM Installation](docs/INSTALLATION.md)
- [Entwickler-Dokumentation](docs/DEVELOPMENT.md)
- [Changelog](docs/CHANGELOG.md)

### 🌐 Community Resources
- **XDA Developers:** [Realme C63 Forum](https://forum.xda-developers.com/)
- **Realme Community:** [https://c.realme.com/](https://c.realme.com/)
- **Reddit:** r/Realme

---

## 📜 Lizenz

Dieses Projekt ist lizenziert unter [Lizenz eintragen]

**Copyright © Elektronikx-Center-Matte by Alexander Mathey**

---

## ⚖️ Disclaimer

- Diese ROM wird bereitgestellt "AS IS" ohne Garantien
- Die Nutzung erfolgt auf eigenes Risiko
- Der Entwickler haftet nicht für Datenverlust oder Geräteschäden
- Erstelle ein Backup, bevor du die ROM installierst

---

**Letzte Aktualisierung:** 2026-01-10  
**Version:** 1.0 (Beta)