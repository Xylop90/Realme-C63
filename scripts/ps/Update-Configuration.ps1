<#
.SYNOPSIS
    Update-Configuration - Aktualisiert Konfigurationsdateien

.DESCRIPTION
    Funktionen für:
    - Konfigurationsvalidierung
    - Update von URLs und Versionen
    - Backup von Konfigurationen

.EXAMPLE
    .\Update-Configuration.ps1

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ""
)

# Setze Standardpfade
$script:RootDir = Split-Path -Path $PSScriptRoot -Parent
$script:RootDir = Split-Path -Path $script:RootDir -Parent

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $script:RootDir "config"
}

# ============================================================================
# KONFIGURATION LADEN
# ============================================================================

function Get-ConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Host "[FEHLER] Konfigurationsdatei nicht gefunden: $FilePath" -ForegroundColor Red
        return $null
    }

    try {
        $config = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        Write-Host "[OK] Konfiguration geladen: $(Split-Path -Path $FilePath -Leaf)" -ForegroundColor Green
        return $config
    }
    catch {
        Write-Host "[FEHLER] Konnte Konfiguration nicht laden: $_" -ForegroundColor Red
        return $null
    }
}

# ============================================================================
# KONFIGURATION SPEICHERN
# ============================================================================

function Save-ConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Backup erstellen
        if (Test-Path -Path $FilePath) {
            $backupPath = "$FilePath.bak"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Host "[INFO] Backup erstellt: $backupPath" -ForegroundColor Cyan
        }

        # Speichern
        $json = $Config | ConvertTo-Json -Depth 10
        $json | Out-File -FilePath $FilePath -Encoding UTF8 -Force
        
        Write-Host "[OK] Konfiguration gespeichert: $(Split-Path -Path $FilePath -Leaf)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FEHLER] Konnte Konfiguration nicht speichern: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# KONFIGURATION VALIDIEREN
# ============================================================================

function Test-ConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigType
    )

    $isValid = $true

    switch ($ConfigType) {
        "installer" {
            if (-not $Config.version) {
                Write-Host "[FEHLER] 'version' fehlt in Konfiguration" -ForegroundColor Red
                $isValid = $false
            }
            if (-not $Config.sources) {
                Write-Host "[FEHLER] 'sources' fehlt in Konfiguration" -ForegroundColor Red
                $isValid = $false
            }
        }
        "firmware" {
            if (-not $Config.sources) {
                Write-Host "[FEHLER] 'sources' fehlt in Firmware-Konfiguration" -ForegroundColor Red
                $isValid = $false
            }
        }
        "tools" {
            if (-not $Config.tools) {
                Write-Host "[FEHLER] 'tools' fehlt in Tool-Versions-Konfiguration" -ForegroundColor Red
                $isValid = $false
            }
        }
    }

    if ($isValid) {
        Write-Host "[OK] Konfiguration ist valide" -ForegroundColor Green
    }

    return $isValid
}

# ============================================================================
# VERSIONEN AKTUALISIEREN
# ============================================================================

function Update-ToolVersions {
    [CmdletBinding()]
    param()

    $versionsFile = Join-Path $ConfigPath "tool-versions.json"
    $config = Get-ConfigFile -FilePath $versionsFile

    if (-not $config) {
        return $false
    }

    Write-Host ""
    Write-Host "[*] Aktualisiere Tool-Versionen..." -ForegroundColor Cyan

    # Aktualisiere Last-Check
    $config.last_check = Get-Date -Format "yyyy-MM-dd"

    # Speichern
    return Save-ConfigFile -Config $config -FilePath $versionsFile
}

# ============================================================================
# KONFIGURATION ANZEIGEN
# ============================================================================

function Show-Configuration {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "                    Aktuelle Konfiguration                                  " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Installer Config
    $installerConfig = Join-Path $ConfigPath "installer-config.json"
    if (Test-Path $installerConfig) {
        $config = Get-ConfigFile -FilePath $installerConfig
        if ($config) {
            Write-Host "Installer-Konfiguration:" -ForegroundColor Yellow
            Write-Host "  Version: $($config.version)" -ForegroundColor White
            Write-Host "  Auto-Update: $($config.auto_update_config)" -ForegroundColor White
            Write-Host "  Sprache: $($config.ui.language)" -ForegroundColor White
            Write-Host ""
        }
    }

    # Firmware Config
    $firmwareConfig = Join-Path $ConfigPath "firmware-sources.json"
    if (Test-Path $firmwareConfig) {
        $config = Get-ConfigFile -FilePath $firmwareConfig
        if ($config) {
            Write-Host "Firmware-Quellen:" -ForegroundColor Yellow
            Write-Host "  Anzahl Quellen: $($config.sources.Count)" -ForegroundColor White
            Write-Host "  Letztes Update: $($config.last_updated)" -ForegroundColor White
            Write-Host ""
        }
    }

    # Tool Versions
    $toolsConfig = Join-Path $ConfigPath "tool-versions.json"
    if (Test-Path $toolsConfig) {
        $config = Get-ConfigFile -FilePath $toolsConfig
        if ($config) {
            Write-Host "Tool-Versionen:" -ForegroundColor Yellow
            Write-Host "  Letzter Check: $($config.last_check)" -ForegroundColor White
            
            foreach ($tool in $config.tools.PSObject.Properties) {
                $toolData = $tool.Value
                Write-Host "  $($toolData.name): $($toolData.current_version)" -ForegroundColor Gray
            }
            Write-Host ""
        }
    }

    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# HAUPTFUNKTION
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "            Update-Configuration - Konfigurations-Manager                   " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Zeige aktuelle Konfiguration
    Show-Configuration

    # Validiere Konfigurationen
    Write-Host "[*] Validiere Konfigurationen..." -ForegroundColor Cyan
    
    $installerConfigFile = Join-Path $ConfigPath "installer-config.json"
    $installerConfig = Get-ConfigFile -FilePath $installerConfigFile
    if ($installerConfig) {
        Test-ConfigFile -Config $installerConfig -ConfigType "installer" | Out-Null
    }

    $firmwareConfigFile = Join-Path $ConfigPath "firmware-sources.json"
    $firmwareConfig = Get-ConfigFile -FilePath $firmwareConfigFile
    if ($firmwareConfig) {
        Test-ConfigFile -Config $firmwareConfig -ConfigType "firmware" | Out-Null
    }

    $toolsConfigFile = Join-Path $ConfigPath "tool-versions.json"
    $toolsConfig = Get-ConfigFile -FilePath $toolsConfigFile
    if ($toolsConfig) {
        Test-ConfigFile -Config $toolsConfig -ConfigType "tools" | Out-Null
    }

    # Aktualisiere Tool-Versionen
    Update-ToolVersions | Out-Null

    Write-Host ""
    Write-Host "[OK] Konfigurationsprüfung abgeschlossen" -ForegroundColor Green
    Write-Host ""
}

Main
