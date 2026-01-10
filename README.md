# Realme C63 (RMX3939) - Vollautomatische Installation

**Version:** 1.0.0  
**Datum:** 2026-01-10  
**Copyright:** © 2026 Elektronikx-Center-Matte by Alexander Mathey

---

## 🎯 Überblick

Dieses Repository enthält ein **ZERO-TOUCH Installations-System** für das Realme C63 (RMX3939) Smartphone. Das System automatisiert den kompletten Flash-Prozess unter Windows 11:

✅ **Vollautomatisch** - Nur 1 Doppelklick zum Starten  
✅ **Selbst-konfigurierend** - Erstellt alle Configs automatisch  
✅ **Selbstheilend** - Retry-Logik und Fallbacks  
✅ **Optimiert** - Parallele Downloads, Caching  
✅ **Sicher** - Hash-Checks, Signaturen, Backups  
✅ **Dokumentiert** - Auto-generierte Reports  

---

## 📋 Systemanforderungen

- **Betriebssystem:** Windows 11 (auch Windows 10 kompatibel)
- **PowerShell:** Version 5.1 oder höher
- **Administrator-Rechte:** Erforderlich
- **Internet-Verbindung:** Für Tool- und Treiber-Downloads
- **Freier Speicherplatz:** Mindestens 10 GB
- **USB-Kabel:** Hochwertiges USB-Kabel (Daten + Laden)

---

## 🚀 Schnellstart

### 1. Repository klonen oder herunterladen

```bash
git clone https://github.com/Xylop90/Realme-C63.git
cd Realme-C63
```

### 2. Installation starten

**Doppelklick auf `install.cmd`** im Root-Verzeichnis

Oder über Kommandozeile:

```cmd
install.cmd
```

Das war's! Das System führt automatisch aus:
- ✅ Admin-Rechte-Anforderung
- ✅ Verzeichnisse erstellen
- ✅ Konfiguration generieren
- ✅ Tools herunterladen
- ✅ Treiber installieren
- ✅ Firmware vorbereiten
- ✅ SPD Flash Tool einrichten
- ✅ Dokumentation erstellen

---

## 📁 Verzeichnisstruktur

```
Realme-C63/
├── install.cmd                      # ← Haupteinstiegspunkt (HIER STARTEN!)
├── install.bat                      # Alternative
│
├── scripts/                         # Alle PowerShell-Scripts
│   ├── bootstrap/                   # Bootstrap & Orchestrierung
│   │   └── master-installer.ps1   # Haupt-Installer
│   ├── drivers/                     # Treiber-Installation
│   │   ├── auto-driver-installer.ps1
│   │   └── device-detection.ps1
│   ├── flash/                       # Flash-Prozess
│   │   ├── firmware-downloader.ps1
│   │   └── spd-flash-automation.ps1
│   ├── post-install/                # Post-Installation
│   │   ├── finalize.ps1
│   │   └── verification.ps1
│   └── lib/                         # Bibliotheken
│       ├── logger.ps1
│       ├── downloader.ps1
│       ├── registry-manager.ps1
│       └── ui-automation.ps1
│
├── config/                          # Konfiguration (auto-generiert)
├── work/                            # Download-Cache (auto-generiert)
├── logs/                            # Log-Dateien (auto-generiert)
├── backup/                          # Geräte-Backups (auto-generiert)
├── firmware/                        # Firmware-Dateien (auto-generiert)
└── docs/                            # Dokumentation
    ├── INSTALLATION-REPORT.md      # Auto-generiert nach Installation
    ├── TROUBLESHOOTING.md          # Fehlerbehebung
    └── FIRMWARE-GUIDE.md           # Firmware-Anleitung
```

---

## 🔧 Was wird installiert?

### Tools
- **Android Platform Tools** (ADB/Fastboot)
- **SPD Flash Tool** (für Unisoc-Geräte)
- **7-Zip CLI** (für Entpacken)

### Treiber
- **SPD/Unisoc USB Driver**
- **Realme Universal USB Driver**

### Firmware
- Automatische Suche nach passender Firmware
- Oder manuelle Platzierung in `firmware/` Ordner

---

## 📝 Schritt-für-Schritt Anleitung

### Phase 1: Vorbereitung

1. **Gerät vorbereiten:**
   - Akku mindestens 50% geladen
   - USB-Debugging aktiviert (optional)
   - Alle wichtigen Daten gesichert

2. **PC vorbereiten:**
   - Windows Updates installiert
   - Antivirenprogramm temporär deaktiviert (optional)

### Phase 2: Installation

1. **Starte `install.cmd`**
   - Doppelklick auf Datei
   - UAC-Prompt bestätigen (Admin-Rechte)

2. **Automatischer Ablauf:**
   ```
   [*] Verzeichnisstruktur wird erstellt...
   [*] Konfiguration wird generiert...
   [*] System wird vorbereitet...
   [*] Tools werden heruntergeladen...
   [*] Treiber werden installiert...
   [*] Firmware wird vorbereitet...
   [*] SPD Flash Tool wird eingerichtet...
   ```

3. **Firmware-Download:**
   - Falls automatisch: Wartet auf Download
   - Falls manuell: Anleitung wird angezeigt
   - Firmware in `firmware/` Ordner ablegen

### Phase 3: Flashing

1. **SPD Flash Tool wird gestartet**
   - GUI-Anleitung öffnet sich automatisch
   - Oder: AutoHotkey-Script für Automation

2. **Gerät verbinden:**
   - Gerät ausschalten
   - **Download-Modus:** Power + Vol Up/Down halten
   - USB-Kabel anschließen

3. **Flash-Prozess:**
   - "Load Packet" → Firmware auswählen
   - "Start" → Warten (5-10 Minuten)
   - "Passed" → Fertig!

### Phase 4: Abschluss

1. **Automatischer Neustart**
   - Gerät startet neu
   - Erster Boot dauert länger (5-10 Min)

2. **Post-Installation:**
   - Cleanup wird durchgeführt
   - Report wird generiert
   - System-Einstellungen werden wiederhergestellt

---

## ⚙️ Erweiterte Optionen

### Zero-Touch Modus

Vollautomatisch ohne Prompts:

```cmd
install.cmd -ZeroTouch
```

### Nur Treiber installieren

```powershell
.\scripts\drivers\auto-driver-installer.ps1
```

### Nur Firmware herunterladen

```powershell
.\scripts\flash\firmware-downloader.ps1
```

### Installation verifizieren

```powershell
.\scripts\post-install\verification.ps1
```

---

## 📊 Logs und Reports

Nach der Installation finden Sie:

- **Installations-Log:** `logs/install-YYYYMMDD-HHMMSS.log`
- **Installations-Report:** `docs/INSTALLATION-REPORT.md`
- **System-Info:** `docs/SYSTEM-INFO.md`
- **Geräte-Backup:** `backup/backup-YYYYMMDD-HHMMSS/`

---

## ❓ Häufige Fragen (FAQ)

### Wird die Garantie ungültig?
Ja, durch das Flashen von Custom Firmware erlischt die Herstellergarantie.

### Gehen meine Daten verloren?
Ja, beim Flashen werden alle Daten gelöscht. **Backup erstellen!**

### Funktioniert es auch unter Windows 10?
Ja, Windows 10 wird unterstützt (PowerShell 5.1+ erforderlich).

### Brauche ich den Bootloader zu entsperren?
Für Stock-Firmware normalerweise nicht. Für Custom ROMs ja.

### Was ist der Download-Modus?
Spezieller Modus für Firmware-Flash. Zugriff: Gerät aus + Power + Vol-Tasten.

### Wo finde ich Firmware?
- GetDroidTips: https://www.getdroidtips.com/realme-c63-stock-rom/
- Realme Community: https://www.realmebbs.com/
- Firmware Database: https://firmwarefile.com/

---

## 🛠️ Troubleshooting

Bei Problemen:

1. **Logs prüfen:** `logs/install-YYYYMMDD-HHMMSS.log`
2. **Troubleshooting-Guide:** `docs/TROUBLESHOOTING.md`
3. **GitHub Issues:** [Issue erstellen](https://github.com/Xylop90/Realme-C63/issues)

Häufige Probleme:
- **Gerät nicht erkannt:** Treiber neu installieren, USB-Kabel wechseln
- **Download fehlgeschlagen:** Internet-Verbindung prüfen, VPN deaktivieren
- **Flash fehlgeschlagen:** Download-Modus sicherstellen, Firmware erneut laden

---

## 🤝 Beitragen

Contributions sind willkommen!

1. Fork das Repository
2. Erstelle einen Feature-Branch
3. Committe deine Änderungen
4. Pushe zum Branch
5. Öffne einen Pull Request

---

## 📜 Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei

---

## ⚠️ Disclaimer

- Dieses Tool wird bereitgestellt "AS IS" ohne Garantien
- Die Nutzung erfolgt auf eigenes Risiko
- Der Entwickler haftet nicht für Datenverlust oder Geräteschäden
- **Erstellen Sie ein Backup vor der Nutzung!**

---

## 👨‍💻 Entwickler

**Alexander Mathey**  
Elektronikx-Center-Matte

---

## 🌟 Support

Wenn dieses Projekt hilfreich war:
- ⭐ Gib dem Repository einen Star
- 🐛 Melde Bugs via Issues
- 💡 Schlage Features vor
- 📖 Verbessere die Dokumentation

---

**Letzte Aktualisierung:** 2026-01-10  
**Version:** 1.0.0