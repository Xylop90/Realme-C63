# Fehlerbehebung - Realme C63 Installer

## Häufige Probleme und Lösungen

### Installation

#### Problem: "Administrator-Rechte erforderlich"
**Lösung:**
1. Rechtsklick auf `INSTALL.bat`
2. "Als Administrator ausführen" wählen

#### Problem: PowerShell-Skript wird nicht ausgeführt
**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Downloads

#### Problem: Download schlägt fehl
**Lösung:**
- Internetverbindung prüfen
- Firewall-Einstellungen prüfen
- Windows Defender temporär deaktivieren

#### Problem: BITS-Transfer hängt
**Lösung:**
```powershell
Get-BitsTransfer | Remove-BitsTransfer
```

### Treiber

#### Problem: Treiber-Installation fehlgeschlagen
**Lösung:**
1. Windows-Updates installieren
2. Treibersignatur-Erzwingung deaktivieren
3. Manuell mit PNPUtil installieren

### Geräte

#### Problem: Gerät wird nicht erkannt
**Lösung:**
1. USB-Kabel prüfen
2. Anderen USB-Port verwenden
3. Treiber neu installieren
4. Gerät neu starten

---

Für weitere Hilfe siehe [README.md](../README.md)
