# Realme C63 (RMX3939) - Installation & Flash Tools

**Vollautomatische Windows 11 PowerShell Installation für Realme C63**

[![Windows 11](https://img.shields.io/badge/Windows-11-0078D6?style=flat&logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=flat&logo=powershell)](https://docs.microsoft.com/powershell/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📱 Geräteinformationen

**Gerät:** Realme C63  
**Modell:** RMX3939  
**Chipset:** Unisoc/Spreadtrum (NICHT Qualcomm/MTK!)  
**Flash-Tool:** SPD Flash Tool (Research Download)  
**Status:** Produktionsreif ✅  

---

## ✨ Features des Installations-Skripts

### Vollautomatische Installation
- 🔄 **Automatischer Download** aller benötigten Tools und Treiber
- 🔒 **SHA256-Hash-Verifikation** für alle Downloads
- 📦 **Automatische Installation** von SPD USB-Treibern
- 📦 **Realme Universal USB-Treiber** Installation
- 🎨 **Farbcodierte Konsolenausgabe** für bessere Übersicht
- 📝 **Umfassendes Logging** mit Zeitstempel
- ⚠️ **Sicherheitsabfragen** vor kritischen Aktionen
- 📖 **Detaillierte Schritt-für-Schritt-Anleitung** für SPD Flash Tool

### Unterstützte Tools
- **SPD Flash Tool** (R27.24.2301) - Haupt-Flash-Tool
- **Android Platform Tools** (ADB) - Optional für Debugging
- **SPD/Unisoc USB-Treiber** - Für Download-Modus
- **Realme Universal USB-Treiber** - Für ADB-Verbindung

### Intelligente Fehlerbehandlung
- ✅ Automatische Retry-Logik bei Downloads
- ✅ Hash-Überprüfung mit Warnungen
- ✅ Umfassende Fehlerprotokollierung
- ✅ Benutzerfreundliche Fehlermeldungen

---

## 📋 Systemanforderungen

### PC-Anforderungen
- **Betriebssystem:** Windows 11 (oder Windows 10 Build 19041+)
- **RAM:** 4 GB minimum, 8 GB empfohlen
- **Speicherplatz:** 10 GB freier Speicher
- **Administrator-Rechte:** Erforderlich
- **USB:** USB 2.0 oder höher Port
- **Internet:** Stabile Verbindung für Downloads (5-10 GB)

### Geräteanforderungen
- **Gerät:** Realme C63 (RMX3939)
- **Akku:** Mindestens 70% geladen
- **USB-Debugging:** Aktiviert (für ADB, optional)
- **OEM-Unlock:** Aktiviert in Entwickleroptionen
- **USB-Kabel:** Original oder hochwertig (Datenübertragung)
- **Backup:** DRINGEND empfohlen - alle Daten werden gelöscht!

---

## 📁 Repository-Struktur

```
Realme-C63/
├── scripts/
│   ├── ps/
│   │   └── install-realme-c63.ps1    # Haupt-Installations-Skript
│   ├── install-windows.ps1            # Legacy Windows Installer
│   ├── install-windows.bat            # Batch-Wrapper
│   └── install-termux.sh              # Termux Android Installation
├── config/
│   └── downloads.json                 # Download-URLs und Hashes
├── docs/
│   ├── TROUBLESHOOTING.md             # Problemlösungen
│   ├── FIRMWARE-GUIDE.md              # Firmware Download Guide
│   ├── INSTALLATION.md                # Detaillierte Installation
│   ├── BOOTLOADER_UNLOCK.md           # Bootloader Entsperren
│   ├── DEVELOPMENT.md                 # Entwickler-Dokumentation
│   └── CHANGELOG.md                   # Versions-Historie
├── README.md                          # Diese Datei
└── LICENSE                            # MIT Lizenz
```

---

## 🚀 Schnellstart

### Option 1: Automatische Installation (Empfohlen)

**Voraussetzung:** Windows 11, Administrator-Rechte

```powershell
# 1. Repository klonen oder ZIP herunterladen
git clone https://github.com/Xylop90/Realme-C63.git
cd Realme-C63

# 2. PowerShell als Administrator öffnen
# Rechtsklick auf PowerShell → "Als Administrator ausführen"

# 3. Installations-Skript ausführen
.\scripts\ps\install-realme-c63.ps1
```

Das Skript führt automatisch aus:
1. ✅ System-Überprüfung (Windows 11, Admin-Rechte)
2. ✅ Download aller benötigten Tools und Treiber
3. ✅ Hash-Verifikation der Downloads
4. ✅ Installation der USB-Treiber (SPD + Realme)
5. ✅ Einrichtung des SPD Flash Tools
6. ✅ Firmware-Überprüfung (falls vorhanden)
7. ✅ Start des SPD Flash Tools mit Anleitung

### Option 2: Mit Parametern

```powershell
# Ohne Treiber-Installation (falls bereits installiert)
.\scripts\ps\install-realme-c63.ps1 -SkipDriverInstall

# Ohne Benutzer-Prompts (vollautomatisch)
.\scripts\ps\install-realme-c63.ps1 -ForceNoPrompt

# Benutzerdefinierte Konfig
.\scripts\ps\install-realme-c63.ps1 -ConfigPath "C:\custom\config.json"

# Kombination
.\scripts\ps\install-realme-c63.ps1 -SkipDriverInstall -ForceNoPrompt
```

---

## 📥 Firmware herunterladen

### Wichtig: Firmware wird NICHT automatisch heruntergeladen!

Sie müssen die Firmware manuell herunterladen:

### 1. Modell-Überprüfung
```
Auf dem Gerät wählen: *#899#
Überprüfen Sie: Model Number = RMX3939
```

### 2. Firmware-Quellen (empfohlen)

| Quelle | URL | Qualität |
|--------|-----|----------|
| **GetDroidTips** | [Link](https://www.getdroidtips.com/realme-c63-firmware/) | ⭐⭐⭐⭐⭐ |
| **GSMMAFIA** | [Link](https://gsmmafia.com/realme-c63-rmx3939-flash-file/) | ⭐⭐⭐⭐⭐ |
| **RealmeFirmware** | [Link](https://realmefirmware.com/realme-c63-4g-firmware/) | ⭐⭐⭐⭐ |
| **ROMProvider** | [Link](https://romprovider.com/realme-c63-rmx3939-flash-file-stock-rom/) | ⭐⭐⭐ |

### 3. Download und Ablage

```
1. Laden Sie Firmware für RMX3939 herunter (1-3 GB)
2. Speichern Sie in: %TEMP%\Realme-C63-Installation\firmware\
3. Format: .PAC oder .ZIP (falls ZIP: .PAC Datei extrahieren)
```

**Detaillierte Anleitung:** Siehe [FIRMWARE-GUIDE.md](docs/FIRMWARE-GUIDE.md)

---

## 🔧 Installation Schritt-für-Schritt

### Phase 1: Vorbereitung

1. **Backup erstellen**
   ```
   ⚠️ KRITISCH: Flash-Prozess löscht ALLE Daten!
   
   Sichern Sie:
   - Fotos und Videos
   - Kontakte und Nachrichten
   - Apps und App-Daten
   - Dokumente und Downloads
   ```

2. **USB-Debugging aktivieren** (optional, für ADB)
   ```
   Einstellungen → Über das Telefon
   → 7x auf "Build-Nummer" tippen
   → Zurück → Entwickleroptionen
   → USB-Debugging aktivieren
   ```

3. **Gerät laden**
   ```
   Akku auf mindestens 70% laden
   Während Flash-Prozess: Netzteil ANGESCHLOSSEN lassen!
   ```

### Phase 2: Automatische Installation ausführen

```powershell
# PowerShell als Administrator
cd C:\path\to\Realme-C63
.\scripts\ps\install-realme-c63.ps1
```

Das Skript wird:
- System überprüfen ✅
- Warnungen anzeigen ⚠️
- Backup-Bestätigung anfordern
- Tools und Treiber herunterladen und installieren
- Firmware-Überprüfung durchführen
- SPD Flash Tool starten und Anleitung anzeigen

### Phase 3: SPD Flash Tool verwenden

**WICHTIG:** SPD Flash Tool ist GUI-basiert - folgen Sie der Anleitung!

#### Schritt 1: PAC-Datei laden
```
1. Im SPD Flash Tool: "Load Packet" klicken
2. Navigieren zu Ihrer .PAC Datei
3. Warten Sie, bis Datei geladen ist
```

#### Schritt 2: Gerät in Download-Modus
```
1. Gerät KOMPLETT ausschalten
2. Volume DOWN Taste gedrückt HALTEN
3. USB-Kabel anschließen (während Taste gedrückt)
4. 5-10 Sekunden gedrückt halten
5. SPD Tool sollte Gerät erkennen (COM Port erscheint)
```

#### Schritt 3: Flash starten
```
1. Im SPD Tool: "Download" oder "Start" klicken
2. NICHT USB-Kabel entfernen!
3. Warten Sie auf "Passed" oder "Download Success"
4. Dauer: 5-15 Minuten
```

#### Schritt 4: Gerät neu starten
```
1. USB-Kabel entfernen
2. Power-Taste 10 Sekunden halten
3. Gerät bootet neu
4. Erster Boot: 5-10 Minuten (NICHT unterbrechen!)
```

**Detaillierte Anleitung mit Screenshots:** Siehe [INSTALLATION.md](docs/INSTALLATION.md)

---

## ⚠️ Wichtige Warnungen

### 🔴 DATENVERLUST
```
Das Flashen der Firmware löscht ALLE Daten auf Ihrem Gerät!
Backup ist NICHT optional - es ist ERFORDERLICH!
```

### 🔴 GARANTIEVERLUST
```
Das manuelle Flashen kann die Herstellergarantie ungültig machen.
Realme Service Center kann Reparatur verweigern.
Überprüfen Sie Ihren Garantiestatus vor dem Flashen!
```

### 🔴 WIDEVINE DRM
```
Nach dem Flashen funktioniert HD-Streaming (Netflix, Amazon Prime)
möglicherweise nur in SD-Qualität (Widevine L3 statt L1).
Dies ist NICHT reversibel!
```

### 🔴 BRICK-RISIKO
```
Falsches Vorgehen kann Ihr Gerät unbrauchbar machen ("brick").
Verwenden Sie NUR Firmware für RMX3939!
NICHT für RMX3938, RMX3940 oder andere Modelle!
```

### 🔴 STROM & VERBINDUNG
```
Stellen Sie sicher:
✅ Akku mindestens 70% geladen
✅ USB-Kabel stabil verbunden (Original oder hochwertig)
✅ PC geht nicht in Standby während Flash
✅ Stabile Stromversorgung für PC und Gerät
```

---

## 🐛 Problemlösung

Häufige Probleme und Lösungen:

### Treiber werden nicht erkannt
→ Siehe [TROUBLESHOOTING.md - Treiber-Probleme](docs/TROUBLESHOOTING.md#treiber-probleme)

### SPD Flash Tool startet nicht
→ Siehe [TROUBLESHOOTING.md - SPD Flash Tool Probleme](docs/TROUBLESHOOTING.md#spd-flash-tool-probleme)

### Gerät wird nicht erkannt
→ Siehe [TROUBLESHOOTING.md - USB-Verbindungsprobleme](docs/TROUBLESHOOTING.md#usb-verbindungsprobleme)

### Flash-Prozess schlägt fehl
→ Siehe [TROUBLESHOOTING.md - Firmware-Flash-Fehler](docs/TROUBLESHOOTING.md#firmware-flash-fehler)

### Bootloop nach Flash
→ Siehe [TROUBLESHOOTING.md - Bootloop und Startprobleme](docs/TROUBLESHOOTING.md#bootloop-und-startprobleme)

**Vollständige Problemlösungen:** [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 📚 Dokumentation

| Dokument | Beschreibung |
|----------|--------------|
| [README.md](README.md) | Dieses Dokument - Übersicht und Schnellstart |
| [FIRMWARE-GUIDE.md](docs/FIRMWARE-GUIDE.md) | Anleitung zum Firmware-Download |
| [INSTALLATION.md](docs/INSTALLATION.md) | Detaillierte Installations-Anleitung |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Problemlösungen und Fehlerbehebung |
| [BOOTLOADER_UNLOCK.md](docs/BOOTLOADER_UNLOCK.md) | Bootloader entsperren (falls benötigt) |
| [CHANGELOG.md](docs/CHANGELOG.md) | Versions-Historie |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | Entwickler-Dokumentation |

---

## 🔗 Ressourcen und Links

### Offizielle Ressourcen
- **Realme Support:** https://www.realme.com/support
- **Realme Community:** https://c.realme.com/
- **Android Platform Tools:** https://developer.android.com/tools/releases/platform-tools

### Tools und Treiber
- **SPD Flash Tool:** https://spdflashtool.com/
- **SPD USB Drivers:** https://tech-latest.com/download-latest-spd-drivers-spreadtrum-windows/
- **Realme USB Drivers:** https://gsmxr.com/oppo-oneplus-realme-latest-driver-setup/

### Community-Support
- **XDA Developers:** https://xda-developers.com/
- **Reddit r/Realme:** https://reddit.com/r/Realme
- **Telegram:** Suchen Sie nach "Realme C63" Gruppen

---

## 🤝 Beitragen

Beiträge sind willkommen! Bitte:

1. Forken Sie das Repository
2. Erstellen Sie einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Committen Sie Ihre Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Pushen Sie zum Branch (`git push origin feature/AmazingFeature`)
5. Öffnen Sie einen Pull Request

Siehe [DEVELOPMENT.md](docs/DEVELOPMENT.md) für Details.

---

## 📜 Lizenz

Dieses Projekt ist lizenziert unter der MIT License - siehe [LICENSE](LICENSE) Datei für Details.

**Copyright © 2026 Realme C63 Installation Team**

---

## ⚖️ Haftungsausschluss

```
WICHTIGER HINWEIS:

Dieses Tool und die Dokumentation werden "AS IS" ohne Garantien bereitgestellt.
Die Nutzung erfolgt auf eigenes Risiko.

Der/die Entwickler haften NICHT für:
• Datenverlust oder Beschädigung
• Geräteschäden oder "Brick"
• Garantieverlust
• Widevine DRM Downgrade
• Funktionsverlust (NFC, Fingerprint, etc.)
• Sicherheitsprobleme
• Finanzielle Verluste durch Reparaturen
• Jegliche andere direkte oder indirekte Schäden

Vor der Nutzung:
✅ Erstellen Sie ein vollständiges Backup
✅ Überprüfen Sie Ihren Garantiestatus
✅ Lesen Sie ALLE Dokumentation sorgfältig
✅ Verstehen Sie die Risiken
✅ Nutzen Sie auf eigene Verantwortung

Bei Unsicherheit: Lassen Sie die Installation von einem Fachmann durchführen
oder nutzen Sie offizielle Realme Service Center!
```

---

## 🏆 Credits & Anerkennung

**Entwickelt von:** Realme C63 Installation Team  
**Basierend auf:** SPD Flash Tool by Spreadtrum/Unisoc  

**Besonderer Dank an:**
- Spreadtrum/Unisoc für SPD Flash Tool
- Google für Android Platform Tools
- Realme Community für Tests und Feedback
- XDA Developers Community
- Alle Firmware-Anbieter und Mirroring-Services

---

**Letzte Aktualisierung:** 2026-01-10  
**Version:** 1.0.0  
**Status:** Produktionsreif ✅

---

## 📞 Support erhalten

1. **Lesen Sie die Dokumentation** - Die meisten Fragen werden beantwortet in:
   - [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
   - [FIRMWARE-GUIDE.md](docs/FIRMWARE-GUIDE.md)
   - [INSTALLATION.md](docs/INSTALLATION.md)

2. **Suchen Sie in bestehenden Issues** - Vielleicht wurde Ihr Problem bereits gelöst

3. **Erstellen Sie ein neues Issue** - Falls Sie einen Bug gefunden haben:
   - Geben Sie detaillierte Beschreibung
   - Fügen Sie Log-Datei bei (`%TEMP%\Realme-C63-Installation\logs\`)
   - Nennen Sie Ihre Windows-Version
   - Beschreiben Sie die genauen Schritte zur Reproduktion

4. **Community fragen** - XDA, Reddit, Telegram Gruppen

---

**Made with ❤️ for Realme C63 Community**