#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Post-Installation Finalisierung für Realme C63
    
.DESCRIPTION
    Cleanup, Dokumentation und System-Wiederherstellung
    nach erfolgreicher Installation
    
.NOTES
    Author: Elektronikx-Center-Matte by Alexander Mathey
    Version: 1.0
    Date: 2026-01-10
#>

param(
    [string]$WorkingDirectory = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

# Importiere Module
. "$WorkingDirectory\scripts\lib\logger.ps1"
. "$WorkingDirectory\scripts\lib\registry-manager.ps1"

# Initialisiere Logger falls nicht bereits initialisiert
if (-not $Script:LogFile) {
    Initialize-Logger -LogDirectory "$WorkingDirectory\logs" -Level "INFO"
}

Write-LogSection "Post-Installation Finalisierung gestartet"

# ============================================================================
# CLEANUP
# ============================================================================

function Remove-TemporaryFiles {
    <#
    .SYNOPSIS
    Entfernt temporäre Dateien
    #>
    
    Write-LogInfo "Entferne temporäre Dateien..."
    
    $workDir = Join-Path $WorkingDirectory "work"
    
    # Lösche ZIP-Archive
    $zipFiles = Get-ChildItem -Path $workDir -Filter "*.zip" -Recurse -ErrorAction SilentlyContinue
    foreach ($zip in $zipFiles) {
        try {
            Remove-Item -Path $zip.FullName -Force
            Write-LogDebug "Gelöscht: $($zip.Name)"
        }
        catch {
            Write-LogWarning "Konnte nicht löschen: $($zip.Name)"
        }
    }
    
    # Lösche temp Verzeichnisse
    $tempDirs = @("extracted", "temp", "tmp")
    foreach ($dir in $tempDirs) {
        $path = Join-Path $workDir $dir
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force
                Write-LogDebug "Gelöscht: $dir"
            }
            catch {
                Write-LogWarning "Konnte nicht löschen: $dir"
            }
        }
    }
    
    Write-LogInfo "Cleanup abgeschlossen"
}

# ============================================================================
# SYSTEM-WIEDERHERSTELLUNG
# ============================================================================

function Restore-SystemSettings {
    <#
    .SYNOPSIS
    Stellt System-Einstellungen wieder her
    #>
    
    Write-LogInfo "Stelle System-Einstellungen wieder her..."
    
    # Test-Signing deaktivieren
    Write-LogInfo "Deaktiviere Test-Signing..."
    Disable-TestSigning | Out-Null
    
    # Windows Defender Ausnahmen entfernen
    Write-LogInfo "Entferne Windows Defender Ausnahmen..."
    $workPath = Join-Path $WorkingDirectory "work"
    $firmwarePath = Join-Path $WorkingDirectory "firmware"
    
    Remove-WindowsDefenderExclusion -Path $workPath
    Remove-WindowsDefenderExclusion -Path $firmwarePath
    
    # Firewall-Regeln entfernen
    Write-LogInfo "Entferne Firewall-Regeln..."
    Remove-FirewallRule -Name "ADB Server"
    
    Write-LogInfo "System-Einstellungen wiederhergestellt"
    Write-LogWarning "HINWEIS: Neustart empfohlen für Test-Signing Deaktivierung"
}

# ============================================================================
# BACKUP ERSTELLEN
# ============================================================================

function New-DeviceBackup {
    <#
    .SYNOPSIS
    Erstellt Geräte-Backup
    #>
    
    Write-LogInfo "Erstelle Geräte-Backup..."
    
    $adbExe = Join-Path $WorkingDirectory "work\platform-tools\adb.exe"
    
    if (-not (Test-Path $adbExe)) {
        Write-LogWarning "ADB nicht verfügbar für Backup"
        return $false
    }
    
    try {
        # Starte ADB
        & $adbExe start-server 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        # Prüfe Geräteverbindung
        $devices = & $adbExe devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
        
        if (-not $devices) {
            Write-LogWarning "Kein Gerät verbunden für Backup"
            return $false
        }
        
        # Erstelle Backup-Verzeichnis
        $backupDir = Join-Path $WorkingDirectory "backup"
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = Join-Path $backupDir "backup-$timestamp"
        
        if (-not (Test-Path $backupPath)) {
            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        }
        
        # Sichere Geräte-Informationen
        Write-LogInfo "Sichere Geräte-Informationen..."
        
        $deviceInfo = @{
            Model = (& $adbExe shell getprop ro.product.model 2>&1).Trim()
            Manufacturer = (& $adbExe shell getprop ro.product.manufacturer 2>&1).Trim()
            AndroidVersion = (& $adbExe shell getprop ro.build.version.release 2>&1).Trim()
            BuildID = (& $adbExe shell getprop ro.build.id 2>&1).Trim()
            Serial = (& $adbExe shell getprop ro.serialno 2>&1).Trim()
            BackupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $deviceInfo | ConvertTo-Json | Out-File -FilePath (Join-Path $backupPath "device-info.json") -Encoding UTF8
        
        # Sichere Build-Props
        & $adbExe shell getprop > (Join-Path $backupPath "build.prop")
        
        Write-LogInfo "Backup erstellt: $backupPath"
        return $true
    }
    catch {
        Write-LogError "Fehler beim Backup: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# DOKUMENTATION GENERIEREN
# ============================================================================

function New-InstallationReport {
    <#
    .SYNOPSIS
    Generiert Installations-Report
    #>
    
    Write-LogInfo "Generiere Installations-Report..."
    
    $docsDir = Join-Path $WorkingDirectory "docs"
    $reportPath = Join-Path $docsDir "INSTALLATION-REPORT.md"
    
    $report = @"
# Realme C63 (RMX3939) - Installations-Report

**Generiert am:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Installation erfolgreich abgeschlossen! ✅

---

## System-Informationen

- **Betriebssystem:** Windows $(([Environment]::OSVersion.Version.Major))
- **PowerShell Version:** $($PSVersionTable.PSVersion)
- **Installation Version:** 1.0.0

---

## Installierte Komponenten

### Tools
- ✅ Android Platform Tools (ADB/Fastboot)
- ✅ SPD Flash Tool
- ✅ 7-Zip CLI

### Treiber
- ✅ SPD/Unisoc USB Driver
- ✅ Realme Universal USB Driver

### Firmware
- ✅ Realme C63 (RMX3939) Stock Firmware

---

## Verzeichnisstruktur

\`\`\`
$WorkingDirectory/
├── config/          # Konfigurationsdateien
├── work/            # Tools und Downloads
├── logs/            # Installations-Logs
├── backup/          # Geräte-Backups
├── firmware/        # Firmware-Dateien
└── docs/            # Dokumentation
\`\`\`

---

## Nächste Schritte

1. **Gerät neu starten**
   - Gerät sollte automatisch neu starten
   - Erster Start kann 5-10 Minuten dauern

2. **Einrichtung**
   - Folgen Sie dem Setup-Assistenten
   - Verbinden Sie sich mit WLAN
   - Melden Sie sich mit Google-Konto an

3. **Verifizierung**
   - Prüfen Sie ob alle Funktionen arbeiten
   - Testen Sie Kamera, WLAN, Bluetooth

4. **Backup wiederherstellen**
   - Stellen Sie Ihre Daten wieder her (falls vorhanden)
   - Backup-Dateien finden Sie in: \`backup/\`

---

## Support & Troubleshooting

Bei Problemen:
- Prüfen Sie die Log-Dateien in: \`logs/\`
- Konsultieren Sie: \`docs/TROUBLESHOOTING.md\`
- Besuchen Sie: Realme Community Forum

---

## Lizenz & Copyright

Copyright © 2026 Elektronikx-Center-Matte by Alexander Mathey

Dieses Tool wird bereitgestellt "AS IS" ohne Garantien.
Die Nutzung erfolgt auf eigenes Risiko.

---

**Erstellt mit:** Realme C63 Automated Installation System v1.0.0
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-LogInfo "Report erstellt: $reportPath"
    
    return $reportPath
}

function New-SystemInfoReport {
    <#
    .SYNOPSIS
    Generiert System-Info Report
    #>
    
    $docsDir = Join-Path $WorkingDirectory "docs"
    $reportPath = Join-Path $docsDir "SYSTEM-INFO.md"
    
    $report = @"
# System-Informationen

**Generiert am:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Windows-System

- **Version:** $(([Environment]::OSVersion.Version))
- **Architektur:** $([Environment]::Is64BitOperatingSystem)
- **Computer Name:** $($env:COMPUTERNAME)
- **Benutzer:** $($env:USERNAME)

## PowerShell

- **Version:** $($PSVersionTable.PSVersion)
- **Edition:** $($PSVersionTable.PSEdition)
- **CLR Version:** $($PSVersionTable.CLRVersion)

## Installationspfade

- **Arbeitsverzeichnis:** $WorkingDirectory
- **Logs:** $(Join-Path $WorkingDirectory 'logs')
- **Tools:** $(Join-Path $WorkingDirectory 'work')
- **Firmware:** $(Join-Path $WorkingDirectory 'firmware')

---

**Erstellt mit:** Realme C63 Automated Installation System
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-LogInfo "System-Info erstellt: $reportPath"
    
    return $reportPath
}

# ============================================================================
# HAUPTAUSFÜHRUNG
# ============================================================================

function Start-Finalization {
    try {
        Write-LogInfo "Arbeitsverzeichnis: $WorkingDirectory"
        
        # Cleanup
        Remove-TemporaryFiles
        
        # Backup
        New-DeviceBackup | Out-Null
        
        # Dokumentation
        $reportPath = New-InstallationReport
        $sysinfoPath = New-SystemInfoReport
        
        # System-Wiederherstellung
        Write-Host ""
        Write-Host "System-Einstellungen wiederherstellen?" -ForegroundColor Yellow
        Write-Host "(Test-Signing deaktivieren, Defender-Ausnahmen entfernen)" -ForegroundColor Yellow
        $response = Read-Host "Wiederherstellen? (J/N)"
        
        if ($response -eq "J" -or $response -eq "j" -or $response -eq "Y" -or $response -eq "y") {
            Restore-SystemSettings
        }
        
        Write-LogSection "Finalisierung abgeschlossen"
        Write-LogInfo ""
        Write-LogInfo "Installations-Report: $reportPath"
        Write-LogInfo "System-Info: $sysinfoPath"
        Write-LogInfo ""
        
        # Öffne Report
        Start-Process $reportPath
        
        return $true
    }
    catch {
        Write-LogError "Fehler bei Finalisierung: $($_.Exception.Message)"
        Write-LogError $_.ScriptStackTrace
        return $false
    }
}

# Führe Finalisierung aus
$result = Start-Finalization
exit $(if ($result) { 0 } else { 1 })
