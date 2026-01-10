<#
.SYNOPSIS
    Firmware-Manager fuer Web-Scraping und Auto-Download

.DESCRIPTION
    Funktionen fuer:
    - Web-Scraping fuer Firmware-Links
    - Version-Detection
    - Auto-Download
    - PAC-Extraktion

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

# Lade Logger wenn verfuegbar
$modulePath = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $modulePath "modules\Logger.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulePath "modules\Download-Manager.psm1") -Force -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Laedt Firmware-Quellen aus Konfiguration

.PARAMETER ConfigPath
    Pfad zur firmware-sources.json

.EXAMPLE
    Get-FirmwareSources -ConfigPath "C:\config\firmware-sources.json"
#>
function Get-FirmwareSources {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (-not (Test-Path -Path $ConfigPath)) {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Firmware-Quellen-Konfiguration nicht gefunden: $ConfigPath"
        }
        return $null
    }

    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $config.sources
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler beim Laden der Firmware-Quellen: $_" -Exception $_.Exception
        }
        return $null
    }
}

<#
.SYNOPSIS
    Zeigt verfuegbare Firmware-Quellen an

.PARAMETER Sources
    Array von Firmware-Quellen

.EXAMPLE
    Show-FirmwareSources -Sources $sources
#>
function Show-FirmwareSources {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Sources
    )

    if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
        Write-InfoLog "Verfuegbare Firmware-Quellen:"
    }

    Write-Host ""
    Write-Host "Firmware-Quellen fuer Realme C63 (RMX3939):" -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Sources.Count; $i++) {
        $source = $Sources[$i]
        Write-Host ""
        Write-Host "[$($i + 1)] $($source.name)" -ForegroundColor Yellow
        Write-Host "    URL: $($source.url)" -ForegroundColor Gray
        Write-Host "    Zuverlaessigkeit: $($source.reliability)" -ForegroundColor Gray
        Write-Host "    Update-Frequenz: $($source.update_frequency)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

<#
.SYNOPSIS
    Versucht Firmware-Download-Links von einer Website zu extrahieren

.PARAMETER Url
    URL der Website

.PARAMETER Pattern
    Regex-Muster fuer Download-Links

.EXAMPLE
    Find-FirmwareLinks -Url "https://example.com/firmware" -Pattern "download.*\.zip"
#>
function Find-FirmwareLinks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$Pattern = "download|firmware|\.pac|\.zip"
    )

    try {
        if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
            Write-InfoLog "Suche Firmware-Links auf: $Url"
        }

        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30
        
        # Extrahiere alle Links
        $links = $response.Links | Where-Object {
            $_.href -match $Pattern
        } | Select-Object -ExpandProperty href -Unique

        if ($links) {
            if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                Write-SuccessLog "Gefunden: $($links.Count) potentielle Firmware-Links"
            }
            return $links
        }
        else {
            if (Get-Command Write-WarnLog -ErrorAction SilentlyContinue) {
                Write-WarnLog "Keine Firmware-Links gefunden"
            }
            return @()
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler beim Abrufen der Firmware-Links: $_" -Exception $_.Exception
        }
        return @()
    }
}

<#
.SYNOPSIS
    Zeigt interaktive Firmware-Auswahl an

.PARAMETER ConfigPath
    Pfad zur firmware-sources.json

.EXAMPLE
    Select-FirmwareSource -ConfigPath "C:\config\firmware-sources.json"
#>
function Select-FirmwareSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $sources = Get-FirmwareSources -ConfigPath $ConfigPath
    
    if (-not $sources) {
        return $null
    }

    Show-FirmwareSources -Sources $sources

    Write-Host "Waehlen Sie eine Firmware-Quelle (1-$($sources.Count)) oder 0 zum Abbrechen: " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host

    if ($selection -eq "0") {
        return $null
    }

    $index = [int]$selection - 1
    
    if ($index -ge 0 -and $index -lt $sources.Count) {
        return $sources[$index]
    }
    else {
        if (Get-Command Write-WarnLog -ErrorAction SilentlyContinue) {
            Write-WarnLog "Ungueltige Auswahl"
        }
        return $null
    }
}

<#
.SYNOPSIS
    Sucht .pac-Dateien in einem Verzeichnis

.PARAMETER Path
    Suchpfad

.EXAMPLE
    Find-PACFiles -Path "C:\Firmware"
#>
function Find-PACFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $pacFiles = Get-ChildItem -Path $Path -Filter "*.pac" -Recurse -ErrorAction SilentlyContinue
        return $pacFiles
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei PAC-Datei-Suche: $_" -Exception $_.Exception
        }
        return @()
    }
}

<#
.SYNOPSIS
    Verifiziert Firmware-Datei

.PARAMETER FilePath
    Pfad zur Firmware-Datei

.PARAMETER MinSizeMB
    Minimale Dateigroesse in MB

.EXAMPLE
    Test-FirmwareFile -FilePath "C:\firmware.pac" -MinSizeMB 500
#>
function Test-FirmwareFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [int]$MinSizeMB = 500
    )

    if (-not (Test-Path -Path $FilePath)) {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Firmware-Datei nicht gefunden: $FilePath"
        }
        return $false
    }

    $fileInfo = Get-Item -Path $FilePath
    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

    if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
        Write-InfoLog "Firmware-Datei: $(Split-Path -Path $FilePath -Leaf) ($fileSizeMB MB)"
    }

    if ($fileSizeMB -lt $MinSizeMB) {
        if (Get-Command Write-WarnLog -ErrorAction SilentlyContinue) {
            Write-WarnLog "Firmware-Datei zu klein (< $MinSizeMB MB): $fileSizeMB MB"
        }
        return $false
    }

    if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
        Write-SuccessLog "Firmware-Datei verifiziert"
    }
    return $true
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Get-FirmwareSources',
    'Show-FirmwareSources',
    'Find-FirmwareLinks',
    'Select-FirmwareSource',
    'Find-PACFiles',
    'Test-FirmwareFile'
)
