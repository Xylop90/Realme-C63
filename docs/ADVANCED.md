# Erweiterte Optionen - Realme C63 Installer

## Kommandozeilen-Parameter

### Install-RealmeC63.ps1

```powershell
.\scripts\ps\Install-RealmeC63.ps1 [-WorkingDirectory <path>] [-SkipDriverInstall]
```

**Parameter:**
- `-WorkingDirectory`: Benutzerdefiniertes Arbeitsverzeichnis
- `-SkipDriverInstall`: Überspringt Treiber-Installation

### Beispiele

```powershell
# Mit benutzerdefiniertem Verzeichnis
.\scripts\ps\Install-RealmeC63.ps1 -WorkingDirectory "D:\Realme"

# Ohne Treiber-Installation
.\scripts\ps\Install-RealmeC63.ps1 -SkipDriverInstall
```

## Konfiguration anpassen

### installer-config.json

Hauptkonfiguration in `config/installer-config.json`:

```json
{
  "automation": {
    "silent_driver_install": true,
    "auto_device_detection": true,
    "create_desktop_shortcut": true
  },
  "advanced": {
    "parallel_downloads": true,
    "use_bits_transfer": true,
    "max_retries": 3,
    "timeout_seconds": 300
  }
}
```

## Module direkt nutzen

### Logger

```powershell
Import-Module .\scripts\modules\Logger.psm1
Initialize-Logger -LogPath "test.log" -Level "DEBUG"
Write-InfoLog "Test message"
```

### Download-Manager

```powershell
Import-Module .\scripts\modules\Download-Manager.psm1
Invoke-SmartDownload -Url "https://example.com/file.zip" -Destination "output.zip"
```

## Entwickler-Optionen

### PSScriptAnalyzer

```powershell
Install-Module -Name PSScriptAnalyzer -Force
Invoke-ScriptAnalyzer -Path .\scripts\ -Recurse
```

### Pester-Tests

```powershell
Install-Module -Name Pester -Force
Invoke-Pester -Path .\tests\
```

---

**Letzte Aktualisierung:** 2026-01-10
