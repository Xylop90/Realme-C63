# Troubleshooting Guide - Realme C63 Installation

**Version:** 1.0.0  
**Datum:** 2026-01-10

---

## 🔍 Allgemeine Probleme

### Installation startet nicht

**Problem:** `install.cmd` führt nichts aus oder schließt sofort

**Lösungen:**
1. **Als Administrator ausführen:**
   - Rechtsklick auf `install.cmd`
   - "Als Administrator ausführen" wählen

2. **PowerShell Execution Policy:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```

3. **PowerShell Version prüfen:**
   ```powershell
   $PSVersionTable.PSVersion
   ```
   - Sollte mindestens 5.1 sein

---

## 🔌 Verbindungsprobleme

### Gerät wird nicht erkannt

**Problem:** ADB findet das Gerät nicht

**Lösungen:**

1. **USB-Debugging aktivieren:**
   - Einstellungen → Über das Telefon
   - Build-Nummer 7x tippen (Entwickleroptionen aktivieren)
   - Einstellungen → Entwickleroptionen
   - USB-Debugging aktivieren

2. **Treiber neu installieren:**
   ```powershell
   .\scripts\drivers\auto-driver-installer.ps1
   ```

3. **USB-Kabel wechseln:**
   - Verwenden Sie ein hochwertiges USB-Kabel
   - Manche Kabel können nur laden, keine Daten übertragen

4. **USB-Port wechseln:**
   - Versuchen Sie einen anderen USB-Port
   - Bevorzugt USB 2.0 statt USB 3.0

5. **ADB Server neu starten:**
   ```cmd
   adb kill-server
   adb start-server
   adb devices
   ```

6. **USB-Autorisierung:**
   - Schauen Sie auf das Gerät
   - Bestätigen Sie die RSA-Fingerprint Anfrage

### Gerät im Download-Modus nicht erkannt

**Problem:** SPD Flash Tool findet das Gerät nicht

**Lösungen:**

1. **Download-Modus richtig aktivieren:**
   - Gerät vollständig ausschalten
   - Power + Volume Up/Down gleichzeitig halten
   - ODER: Power + Volume Down + Home (je nach Modell)

2. **Treiber prüfen:**
   - Geräte-Manager öffnen (devmgmt.msc)
   - Suchen nach "Spreadtrum" oder "Unisoc" Geräten
   - Gelbes Ausrufezeichen? → Treiber neu installieren

3. **Test-Signing aktivieren:**
   ```cmd
   bcdedit /set testsigning on
   ```
   - Neustart erforderlich!

---

## 💾 Download-Probleme

### Tool-Downloads schlagen fehl

**Problem:** Platform Tools oder SPD Flash Tool können nicht heruntergeladen werden

**Lösungen:**

1. **Internet-Verbindung prüfen:**
   ```powershell
   Test-Connection google.com
   ```

2. **Firewall/Antivirus:**
   - Windows Defender temporär deaktivieren
   - Firewall-Ausnahme für PowerShell hinzufügen

3. **VPN deaktivieren:**
   - Manche VPNs blockieren Downloads

4. **Proxy-Einstellungen:**
   - Prüfen Sie Ihre Proxy-Konfiguration

5. **Manuelle Downloads:**
   - Platform Tools: https://developer.android.com/studio/releases/platform-tools
   - In `work/platform-tools/` entpacken

### Firmware-Download fehlgeschlagen

**Problem:** Firmware kann nicht automatisch heruntergeladen werden

**Lösungen:**

1. **Manuelle Firmware-Download:**
   - GetDroidTips: https://www.getdroidtips.com/realme-c63-stock-rom/
   - Firmware Database: https://firmwarefile.com/realme-c63
   - Realme Community: https://www.realmebbs.com/

2. **Firmware speichern:**
   - Firmware in `firmware/` Ordner ablegen
   - Unterstützte Formate: `.pac`, `.zip`, `.tar`

3. **Firmware verifizieren:**
   ```powershell
   .\scripts\flash\firmware-downloader.ps1
   ```

---

## ⚡ Flash-Probleme

### SPD Flash Tool startet nicht

**Problem:** ResearchDownload.exe startet nicht oder stürzt ab

**Lösungen:**

1. **Kompatibilitätsmodus:**
   - Rechtsklick auf ResearchDownload.exe
   - Eigenschaften → Kompatibilität
   - "Windows 7" oder "Windows 8" Modus wählen

2. **Als Administrator ausführen:**
   - Rechtsklick auf Executable
   - "Als Administrator ausführen"

3. **Visual C++ Redistributables installieren:**
   - Download: https://aka.ms/vs/17/release/vc_redist.x86.exe
   - Installieren und neu starten

4. **Manueller Download:**
   - https://spdflashtool.com/download/
   - In `work/spd-flash-tool/` entpacken

### Flash-Prozess schlägt fehl

**Problem:** "Failed" oder "Error" im SPD Flash Tool

**Lösungen:**

1. **Firmware neu laden:**
   - Im SPD Tool: "Stop"
   - "Load Packet" erneut klicken
   - Firmware neu auswählen

2. **Gerät neu verbinden:**
   - USB-Kabel abziehen
   - Gerät ausschalten
   - Download-Modus erneut aktivieren
   - USB-Kabel anschließen

3. **Anderen USB-Port verwenden:**
   - Direkt am Mainboard (nicht USB-Hub)

4. **Firmware erneut herunterladen:**
   - Datei könnte beschädigt sein
   - Hash-Check durchführen

5. **Batterie aufladen:**
   - Mindestens 50% Akku erforderlich

### Flash bleibt hängen

**Problem:** Progress bar bewegt sich nicht

**Lösungen:**

1. **Geduld:**
   - Flash kann 5-10 Minuten dauern
   - Nicht unterbrechen!

2. **Nach 15 Minuten:**
   - "Stop" klicken
   - Gerät trennen
   - Prozess neu starten

---

## 🔧 Treiber-Probleme

### Treiber-Installation schlägt fehl

**Problem:** PnPUtil meldet Fehler

**Lösungen:**

1. **Test-Signing aktivieren:**
   ```cmd
   bcdedit /set testsigning on
   ```
   - Neustart erforderlich

2. **Alte Treiber entfernen:**
   ```powershell
   pnputil /enum-drivers
   # Finde Spreadtrum/Realme Treiber
   pnputil /delete-driver oem##.inf /uninstall
   ```

3. **Manuelle Installation:**
   - Geräte-Manager öffnen
   - Unbekanntes Gerät → Rechtsklick
   - "Treiber aktualisieren"
   - "Ordner durchsuchen": `work/spd-driver/` oder `work/realme-driver/`

4. **Driver Signature Enforcement deaktivieren:**
   - PC neu starten
   - F8 drücken beim Booten
   - "Erzwingung der Treibersignatur deaktivieren" wählen

### Treiber nach Installation nicht sichtbar

**Problem:** Gerät im Geräte-Manager nicht vorhanden

**Lösungen:**

1. **Nach Hardware-Änderungen suchen:**
   - Geräte-Manager → Aktion
   - "Nach geänderter Hardware suchen"

2. **Ausgeblendete Geräte anzeigen:**
   - Geräte-Manager → Ansicht
   - "Ausgeblendete Geräte anzeigen"

3. **USB-Controller neu installieren:**
   - Geräte-Manager → USB-Controller
   - Jeden Controller deinstallieren
   - PC neu starten (automatische Neu-Installation)

---

## 📝 Log-Analyse

### Log-Dateien finden

```
logs/install-YYYYMMDD-HHMMSS.log
```

### Wichtige Fehler-Patterns

**Download-Fehler:**
```
[ERROR] Download nach 5 Versuchen fehlgeschlagen
```
→ Internet-Verbindung prüfen

**Treiber-Fehler:**
```
[ERROR] Fehler beim Installieren des Treibers
```
→ Test-Signing aktivieren

**ADB-Fehler:**
```
[WARN] Kein Gerät gefunden
```
→ USB-Debugging aktivieren

---

## 🔄 System-Wiederherstellung

### Test-Signing deaktivieren

Nach erfolgreicher Installation:

```cmd
bcdedit /set testsigning off
```

### Windows Defender Ausnahmen entfernen

```powershell
Remove-MpPreference -ExclusionPath "C:\Path\To\Realme-C63\work"
```

### Alle Änderungen rückgängig machen

```powershell
.\scripts\post-install\finalize.ps1
```

---

## 🆘 Notfall-Prozeduren

### Gerät bootet nicht mehr (Brick)

**Sofortmaßnahmen:**

1. **Hard Reset versuchen:**
   - Power + Volume Down 10 Sekunden halten

2. **Recovery Mode:**
   - Power + Volume Up halten
   - "Wipe data/factory reset"

3. **Firmware erneut flashen:**
   - Download-Modus
   - SPD Flash Tool mit Stock-Firmware

4. **Service-Center:**
   - Wenn nichts hilft: Realme Service-Center aufsuchen

### Daten retten nach fehlgeschlagenem Flash

1. **ADB Shell verwenden:**
   ```cmd
   adb shell
   ls /sdcard/
   adb pull /sdcard/DCIM/ ./backup/photos/
   ```

2. **Recovery-Modus:**
   - Custom Recovery (TWRP) flashen
   - Dateien via ADB sichern

---

## 📞 Support-Kontakte

### Online-Ressourcen

- **GitHub Issues:** https://github.com/Xylop90/Realme-C63/issues
- **XDA Developers:** https://forum.xda-developers.com/
- **Realme Community:** https://www.realmebbs.com/

### Vor Support-Anfrage

Bitte folgende Informationen bereitstellen:

1. **Log-Datei:** `logs/install-YYYYMMDD-HHMMSS.log`
2. **Windows Version:** `winver`
3. **PowerShell Version:** `$PSVersionTable.PSVersion`
4. **Gerät-Info:** Model, Android-Version
5. **Fehler-Screenshot**
6. **Schritte zur Reproduktion**

---

## ✅ Checkliste bei Problemen

- [ ] Als Administrator ausgeführt?
- [ ] PowerShell 5.1+ installiert?
- [ ] Internet-Verbindung aktiv?
- [ ] USB-Debugging aktiviert?
- [ ] Treiber installiert?
- [ ] Test-Signing aktiviert?
- [ ] Richtiger Download-Modus?
- [ ] Firmware im richtigen Ordner?
- [ ] Log-Datei geprüft?
- [ ] Anderes USB-Kabel probiert?

---

**Weitere Hilfe benötigt?**  
Öffne ein Issue auf GitHub: https://github.com/Xylop90/Realme-C63/issues

---

**Letzte Aktualisierung:** 2026-01-10
