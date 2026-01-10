# Realme C63 (RMX3939) - Fehlerbehebung

## Inhaltsverzeichnis
- [Gerät nicht erkannt](#gerät-nicht-erkannt)
- [Flash fehlgeschlagen](#flash-fehlgeschlagen)
- [Treiber-Probleme](#treiber-probleme)
- [Bootloop nach Flash](#bootloop-nach-flash)
- [SPD Flash Tool Probleme](#spd-flash-tool-probleme)
- [Download-Probleme](#download-probleme)

---

## Gerät nicht erkannt

### Problem
SPD Flash Tool erkennt das Gerät nicht im Download-Modus.

### Lösungen

#### 1. Treiber überprüfen
```powershell
# Öffnen Sie den Geräte-Manager
devmgmt.msc
```
- Suchen Sie nach "Unbekanntes Gerät" oder Geräten mit gelbem Ausrufezeichen
- Rechtsklick → "Treiber aktualisieren"
- Manuell nach Treibern im `work/cache/drivers/` Verzeichnis suchen

#### 2. Download-Modus korrekt aktivieren
- Gerät **vollständig ausschalten**
- **VOLUME DOWN** drücken und **halten**
- USB-Kabel anschließen (während Taste gedrückt bleibt)
- Taste **5-10 Sekunden** weiter halten
- Bildschirm bleibt schwarz - das ist normal!

#### 3. Anderes USB-Kabel verwenden
- Verwenden Sie das Original-Kabel
- Oder ein hochwertiges Datenkabel (kein reines Ladekabel)
- Versuchen Sie verschiedene USB-Ports (bevorzugt USB 2.0)

#### 4. Neustart und erneut versuchen
```powershell
# Neustart des Geräts mit Tastenkombination:
# VOLUME UP + POWER für 10 Sekunden
```

---

## Flash fehlgeschlagen

### Problem
Flash-Prozess bricht mit Fehler ab oder zeigt "FAIL".

### Lösungen

#### 1. Akku-Ladung prüfen
- Mindestens **50% Akku-Ladung** erforderlich
- Am besten: Vollständig geladen

#### 2. Firmware-Datei überprüfen
```powershell
# Hash der Firmware prüfen
cd work\cache
Get-FileHash -Algorithm SHA256 *.pac
```
- Vergleichen Sie den Hash mit der Konfiguration
- Bei Abweichung: Firmware erneut herunterladen

#### 3. SPD Flash Tool neu starten
- SPD Flash Tool komplett beenden
- Als **Administrator** neu starten
- Firmware erneut laden
- Flash-Prozess wiederholen

#### 4. Andere Firmware-Version versuchen
```powershell
# Stabile Version verwenden statt latest
.\scripts\ps\install-realme-c63.ps1 -FirmwareVersion stable
```

---

## Treiber-Probleme

### Problem
Treiber-Installation schlägt fehl oder Treiber werden nicht erkannt.

### Lösungen

#### 1. Manuelle Treiber-Installation

**SPD/Spreadtrum Treiber:**
1. Öffnen Sie den Geräte-Manager
2. Verbinden Sie das Gerät im Download-Modus
3. Rechtsklick auf "Unbekanntes Gerät"
4. "Treiber aktualisieren" → "Auf dem Computer nach Treibern suchen"
5. Navigieren Sie zu: `work\cache\drivers\spd_drivers\`

**Realme Universal Treiber:**
1. Starten Sie die Treiber-Installation manuell
2. Datei: `work\cache\realme_universal.zip`
3. Entpacken und Setup.exe ausführen

#### 2. Alte Treiber deinstallieren
```powershell
# Öffnen Sie den Geräte-Manager
devmgmt.msc
```
- Alte/fehlerhafte Spreadtrum-Treiber deinstallieren
- PC neu starten
- Treiber neu installieren

#### 3. Treibersignatur-Überprüfung deaktivieren (Windows 11)
```powershell
# PowerShell als Administrator
bcdedit /set nointegritychecks on
bcdedit /set testsigning on
```
**Warnung:** Nach erfolgreicher Installation wieder aktivieren:
```powershell
bcdedit /set nointegritychecks off
bcdedit /set testsigning off
```

---

## Bootloop nach Flash

### Problem
Gerät bootet nach Flash nicht oder hängt im Bootloop.

### Lösungen

#### 1. Geduld beim ersten Boot
- Erster Boot nach Flash kann **5-10 Minuten** dauern
- Gerät wird mehrmals neu starten
- **NICHT unterbrechen!**

#### 2. Factory Reset durchführen
- In Recovery-Modus booten:
  - Gerät ausschalten
  - **VOLUME UP + POWER** gleichzeitig drücken
  - Bis Recovery-Menü erscheint
- "Wipe data/factory reset" auswählen
- Bestätigen und neu starten

#### 3. Erneut flashen
- Flash-Prozess komplett wiederholen
- Diesmal "Erase all" Option im SPD Flash Tool aktivieren

#### 4. Cache/Dalvik Cache löschen
Im Recovery-Modus:
- "Wipe cache partition" auswählen
- "Advanced" → "Wipe Dalvik Cache"
- Neu starten

---

## SPD Flash Tool Probleme

### Problem
SPD Flash Tool startet nicht oder funktioniert nicht korrekt.

### Lösungen

#### 1. Als Administrator ausführen
- Rechtsklick auf SPD Flash Tool
- "Als Administrator ausführen"

#### 2. Kompatibilitätsmodus
- Rechtsklick auf SPD Flash Tool
- "Eigenschaften" → "Kompatibilität"
- "Kompatibilitätsmodus für:" **Windows 8** oder **Windows 7** aktivieren

#### 3. Antivirus-Software deaktivieren
- Temporär Windows Defender/Antivirus deaktivieren
- SPD Flash Tool zur Ausnahmeliste hinzufügen

#### 4. .NET Framework installieren
SPD Flash Tool benötigt möglicherweise .NET Framework 3.5:
```powershell
# Als Administrator
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
```

---

## Download-Probleme

### Problem
Downloads schlagen fehl oder Links sind nicht erreichbar.

### Lösungen

#### 1. Alternative Download-Quellen
Die Config-Datei enthält mehrere Quellen:
- https://www.getdroidtips.com/realme-c63-firmware/
- https://realmefirmware.com/realme-c63-4g-firmware/
- https://gsmmafia.com/realme-c63-rmx3939-flash-file/
- https://romprovider.com/realme-c63-rmx3939-flash-file-stock-rom/

#### 2. VPN verwenden
Manche Websites sind regional blockiert:
- VPN aktivieren
- Land wechseln (z.B. USA, UK)

#### 3. Browser-Download
Wenn automatischer Download fehlschlägt:
1. URL aus Log-Datei kopieren
2. Im Browser öffnen
3. Manuell herunterladen
4. In `work\cache\` speichern

#### 4. Cache nutzen
```powershell
# Bereits heruntergeladene Dateien werden wiederverwendet
ls work\cache\
```

---

## Weitere Hilfe

### Log-Dateien prüfen
```powershell
# Neueste Log-Datei anzeigen
Get-ChildItem work\logs\ | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### Community-Support
- GitHub Issues: https://github.com/Xylop90/Realme-C63/issues
- XDA Developers Forum
- Realme Community Forum

### System-Informationen sammeln
```powershell
# System-Info für Support-Anfragen
systeminfo > system-info.txt
Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.DeviceName -match "Spreadtrum|SPRD"} > driver-info.txt
```

---

## Notfall-Wiederherstellung

### Gerät ist nicht mehr bootbar (Brick)

1. **Nicht panikieren!** Spreadtrum-Geräte sind schwer zu "bricken"
2. Zurück in Download-Modus booten (siehe oben)
3. Stock-Firmware erneut flashen
4. Bei Erfolg: Vollständiger Factory Reset

### Letzter Ausweg
- Autorisierte Realme Service Center kontaktieren
- Professionelle Flash-Service in Anspruch nehmen

---

**Letzte Aktualisierung:** 2026-01-10
