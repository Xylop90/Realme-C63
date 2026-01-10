# Realme C63 (RMX3939) - Häufig gestellte Fragen (FAQ)

## Allgemeine Fragen

### Was ist SPD Flash Tool?
SPD Flash Tool (auch Spreadtrum Flash Tool) ist ein Windows-Tool zum Flashen von Firmware auf Geräten mit Spreadtrum/Unisoc-Chipsätzen. Es ist das offizielle Tool für diese Chips und unterscheidet sich von ADB/Fastboot (für Qualcomm) oder SP Flash Tool (für MediaTek).

### Warum funktioniert ADB/Fastboot nicht mit meinem Realme C63?
Das Realme C63 (RMX3939) verwendet einen Unisoc/Spreadtrum-Chipset, **nicht** Qualcomm. Daher funktionieren die Standard-Android-Tools (ADB, Fastboot) nicht für das Flashen der Stock-Firmware. Sie benötigen SPD Flash Tool.

### Verliere ich meine Daten?
**Ja**, das Flashen der Stock-Firmware führt zu einem **vollständigen Datenverlust**. Erstellen Sie unbedingt ein Backup vor dem Start.

### Wird meine Garantie ungültig?
Das Flashen der offiziellen Stock-Firmware sollte die Garantie **nicht** beeinträchtigen, da Sie das offizielle Betriebssystem installieren. Anders als beim Flashen von Custom ROMs wird hier kein Bootloader entsperrt.

---

## Installation

### Welche Windows-Version benötige ich?
- **Empfohlen:** Windows 11
- **Minimum:** Windows 10 (64-bit)
- PowerShell 5.1 oder höher
- Administrator-Rechte

### Kann ich das Skript auf Windows 10 verwenden?
Ja, das Skript ist mit Windows 10 kompatibel, wurde aber für Windows 11 optimiert. Bei Windows 10 können einzelne Funktionen leicht abweichen.

### Benötige ich eine Internetverbindung?
Ja, für:
- Download von SPD Flash Tool
- Download der USB-Treiber
- Download der Firmware

Die Dateien werden im `work/cache/` Verzeichnis gecacht und können bei erneutem Start wiederverwendet werden.

### Wie groß ist der gesamte Download?
- SPD Flash Tool: ~50 MB
- USB-Treiber: ~20 MB
- Firmware: **2-4 GB** (je nach Version)
- **Gesamt:** ca. 2-4.5 GB

---

## Flash-Prozess

### Wie lange dauert der Flash-Prozess?
- **Download:** 10-30 Minuten (abhängig von Internetgeschwindigkeit)
- **Installation:** 5-10 Minuten
- **Flash:** 5-15 Minuten
- **Erster Boot:** 5-10 Minuten
- **Gesamt:** 30-65 Minuten

### Muss ich den Bootloader entsperren?
**Nein!** Das ist der große Vorteil: Beim Flashen der Stock-Firmware mit SPD Flash Tool muss der Bootloader **nicht** entsperrt werden.

### Was ist der Download-Modus?
Der Download-Modus (auch SPD Download Mode) ist ein spezieller Modus, in dem das Gerät über USB geflasht werden kann. Er wird aktiviert durch:
1. Gerät ausschalten
2. VOLUME DOWN gedrückt halten
3. USB-Kabel anschließen
4. 5-10 Sekunden warten

**Hinweis:** Der Bildschirm bleibt schwarz - das ist normal!

### Kann ich während des Flash das Kabel trennen?
**AUF KEINEN FALL!** Das Trennen des USB-Kabels während des Flash-Vorgangs kann zu einem nicht mehr bootbaren Gerät führen (Brick).

---

## Firmware

### Welche Firmware-Version soll ich verwenden?
- **latest:** Neueste verfügbare Firmware (empfohlen für neue Features)
- **stable:** Stabilere ältere Version (empfohlen bei Problemen)

```powershell
# Stable Version verwenden
.\scripts\ps\install-realme-c63.ps1 -FirmwareVersion stable
```

### Wo finde ich die Firmware?
Die Konfiguration (`config/downloads.json`) enthält mehrere Quellen:
- https://realmefirmware.com/realme-c63-4g-firmware/
- https://www.getdroidtips.com/realme-c63-firmware/
- https://gsmmafia.com/realme-c63-rmx3939-flash-file/

### Was ist eine .PAC-Datei?
.PAC (Package) ist das Firmware-Format für Spreadtrum/Unisoc-Geräte. Es enthält alle System-Partitionen und wird direkt von SPD Flash Tool verarbeitet.

### Kann ich eine Firmware von einem anderen Modell verwenden?
**NEIN!** Verwenden Sie **nur** Firmware für **RMX3939**. Das Flashen falscher Firmware kann Ihr Gerät unbrauchbar machen.

---

## Treiber

### Welche Treiber benötige ich?
Sie benötigen **beide** Treiber:
1. **Realme Universal Driver:** Für normale USB-Kommunikation
2. **SPD/Spreadtrum Driver:** Für SPD Flash Tool

### Wie überprüfe ich, ob Treiber installiert sind?
```powershell
# Geräte-Manager öffnen
devmgmt.msc
```
Suchen Sie nach "Spreadtrum" oder "SPRD" unter "USB-Controller" oder "Andere Geräte".

### Kann ich die Treiber manuell installieren?
Ja, wenn die automatische Installation fehlschlägt:
1. Entpacken Sie die Treiber aus `work\cache\drivers\`
2. Öffnen Sie Geräte-Manager
3. Rechtsklick auf unbekanntes Gerät
4. "Treiber aktualisieren" → "Auf dem Computer suchen"
5. Navigieren Sie zum entpackten Treiber-Ordner

---

## Fehlerbehebung

### Das Skript findet SPD Flash Tool nicht
SPD Flash Tool hat keinen standardisierten Namen. Das Skript sucht nach:
- `SPD_Upgrade_Tool.exe`
- `SPD_Flash_Tool.exe`
- `ResearchDownload.exe`
- `UpgradeDownload.exe`

Falls nicht gefunden, müssen Sie es manuell herunterladen und entpacken.

### "Hash verification failed" Fehler
Wenn die Hash-Verifikation fehlschlägt:
1. Datei könnte beschädigt sein → Erneut herunterladen
2. Config enthält falschen Hash → Hash in Config aktualisieren

Sie können mit `-ForceNoPrompt` fortfahren, aber **auf eigene Gefahr!**

### Gerät bleibt im Bootloop
Siehe [TROUBLESHOOTING.md](TROUBLESHOOTING.md#bootloop-nach-flash)

### SPD Flash Tool zeigt "Failed" oder "Error"
Mögliche Ursachen:
1. Falsche Firmware (falsches Modell)
2. Kabel-/Verbindungsproblem
3. Treiber nicht korrekt installiert
4. Niedriger Akkustand

---

## Erweiterte Fragen

### Kann ich das Skript im Test-Modus ausführen?
Ja! Der Test-Modus simuliert den Prozess ohne echte Downloads oder Flash:
```powershell
.\scripts\ps\install-realme-c63.ps1 -TestMode
```

### Wie kann ich die Treiber-Installation überspringen?
```powershell
.\scripts\ps\install-realme-c63.ps1 -SkipDriverInstall
```

### Wo sind die Log-Dateien?
Log-Dateien werden gespeichert in:
```
work\logs\install-YYYYMMDD-HHmmss.log
```

Letzte Log-Datei anzeigen:
```powershell
Get-ChildItem work\logs\ | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### Kann ich das Skript für andere Realme-Geräte verwenden?
Das Skript ist **spezifisch für RMX3939** (Realme C63). Für andere Modelle:
1. Müssen Sie die Firmware-URLs in `config/downloads.json` anpassen
2. Überprüfen Sie, ob das Gerät einen Spreadtrum/Unisoc-Chip hat
3. Verwenden Sie die korrekte Modellnummer

### Was ist der Unterschied zu Custom ROMs?
- **Stock-Firmware:** Offizielle Realme Software, kein Bootloader-Unlock nötig
- **Custom ROM:** Modifizierte Software, benötigt Bootloader-Unlock, void Garantie

Das Skript ist **nur** für Stock-Firmware!

---

## Sicherheit

### Ist das Skript sicher?
Ja, das Skript:
- Lädt nur offizielle Tools und Treiber
- Verwendet HTTPS für Downloads
- Verifiziert SHA256-Hashes (wenn verfügbar)
- Ist Open Source (kann überprüft werden)

### Könnte mein Gerät "gebrickt" werden?
Das Risiko ist **sehr gering**, da:
- Sie offizielle Stock-Firmware flashen
- Spreadtrum-Geräte einen Notfall-Download-Modus haben
- Der Prozess gut dokumentiert ist

**Wichtig:** Folgen Sie den Anweisungen genau!

### Wird mein Gerät gerootet?
**Nein**, das Flashen der Stock-Firmware rootet Ihr Gerät **nicht**. Es wird auf den Werkszustand zurückgesetzt.

---

## Support

### Wo bekomme ich Hilfe?
1. **Dokumentation:** Lesen Sie [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. **GitHub Issues:** https://github.com/Xylop90/Realme-C63/issues
3. **Log-Datei:** Immer bei Support-Anfragen anhängen

### Kann ich zur Entwicklung beitragen?
Ja! Pull Requests sind willkommen:
- Verbesserungen am Skript
- Aktualisierung der Download-Links
- Übersetzungen
- Dokumentation

---

**Letzte Aktualisierung:** 2026-01-10
