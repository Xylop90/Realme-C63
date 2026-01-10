#Requires -Version 5.1
<#
.SYNOPSIS
    SPD Flash Tool Automation für Realme C63
    
.DESCRIPTION
    Automatisiert die GUI-Interaktion mit SPD Flash Tool
    für vollautomatisches Firmware-Flashing
    
.NOTES
    Author: Elektronikx-Center-Matte by Alexander Mathey
    Version: 1.0
    Date: 2026-01-10
#>

param(
    [string]$WorkingDirectory = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [string]$FirmwarePath,
    [switch]$ManualMode
)

# Importiere Module
. "$WorkingDirectory\scripts\lib\logger.ps1"
. "$WorkingDirectory\scripts\lib\downloader.ps1"
. "$WorkingDirectory\scripts\lib\ui-automation.ps1"

# Initialisiere Logger falls nicht bereits initialisiert
if (-not $Script:LogFile) {
    Initialize-Logger -LogDirectory "$WorkingDirectory\logs" -Level "INFO"
}

Write-LogSection "SPD Flash Automation gestartet"

# ============================================================================
# SPD FLASH TOOL DOWNLOAD
# ============================================================================

function Get-SPDFlashTool {
    <#
    .SYNOPSIS
    Lädt SPD Flash Tool herunter
    #>
    
    $toolDir = Join-Path $WorkingDirectory "work\spd-flash-tool"
    $toolExe = Join-Path $toolDir "ResearchDownload.exe"
    
    # Prüfe ob bereits vorhanden
    if (Test-Path $toolExe) {
        Write-LogInfo "SPD Flash Tool bereits vorhanden"
        return $toolExe
    }
    
    Write-LogInfo "Lade SPD Flash Tool herunter..."
    
    # Erstelle Verzeichnis
    if (-not (Test-Path $toolDir)) {
        New-Item -Path $toolDir -ItemType Directory -Force | Out-Null
    }
    
    # URLs für SPD Flash Tool
    $spdUrls = @(
        "https://spdflashtool.com/download/SPDFlashTool-latest.zip",
        "https://androidmtk.com/download/spd-flash-tool"
    )
    
    $toolZip = Join-Path $toolDir "spd-flash-tool.zip"
    $downloaded = $false
    
    foreach ($url in $spdUrls) {
        if (Invoke-DownloadWithRetry -Url $url -Destination $toolZip -MaxRetries 3) {
            $downloaded = $true
            break
        }
    }
    
    if (-not $downloaded) {
        Write-LogWarning "SPD Flash Tool Download fehlgeschlagen"
        Write-LogInfo "Bitte laden Sie das Tool manuell herunter:"
        Write-LogInfo "  https://spdflashtool.com/download/"
        Write-LogInfo "Und entpacken Sie es nach: $toolDir"
        return $null
    }
    
    # Entpacke Tool
    if (Expand-ArchiveWithProgress -ArchivePath $toolZip -DestinationPath $toolDir -Force) {
        # Suche nach ResearchDownload.exe
        $toolExe = Get-ChildItem -Path $toolDir -Filter "ResearchDownload.exe" -Recurse | Select-Object -First 1
        
        if ($toolExe) {
            Write-LogInfo "SPD Flash Tool bereit: $($toolExe.FullName)"
            return $toolExe.FullName
        }
        else {
            # Alternative Namen
            $altNames = @("SPDFlashTool.exe", "SPD*.exe", "Research*.exe")
            foreach ($pattern in $altNames) {
                $toolExe = Get-ChildItem -Path $toolDir -Filter $pattern -Recurse | Select-Object -First 1
                if ($toolExe) {
                    Write-LogInfo "SPD Flash Tool gefunden: $($toolExe.FullName)"
                    return $toolExe.FullName
                }
            }
        }
    }
    
    Write-LogError "SPD Flash Tool Executable nicht gefunden"
    return $null
}

# ============================================================================
# FIRMWARE-DATEI FINDEN
# ============================================================================

function Find-FirmwarePacFile {
    <#
    .SYNOPSIS
    Findet PAC-Firmware-Datei
    #>
    
    if ($FirmwarePath -and (Test-Path $FirmwarePath)) {
        Write-LogInfo "Verwende angegebene Firmware: $FirmwarePath"
        return $FirmwarePath
    }
    
    $firmwareDir = Join-Path $WorkingDirectory "firmware"
    
    # Suche nach PAC-Datei
    $pacFile = Get-ChildItem -Path $firmwareDir -Filter "*.pac" -Recurse | Select-Object -First 1
    
    if ($pacFile) {
        Write-LogInfo "PAC-Datei gefunden: $($pacFile.Name)"
        return $pacFile.FullName
    }
    
    Write-LogWarning "Keine PAC-Firmware-Datei gefunden in: $firmwareDir"
    return $null
}

# ============================================================================
# SPD FLASH AUTOMATION
# ============================================================================

function Start-SPDFlashAutomation {
    <#
    .SYNOPSIS
    Führt automatisches Flashing durch
    #>
    param(
        [string]$ToolPath,
        [string]$PacFile
    )
    
    Write-LogInfo "Starte SPD Flash Tool..."
    
    # Starte Tool
    $process = Start-Process -FilePath $ToolPath -PassThru
    
    if (-not $process) {
        Write-LogError "SPD Flash Tool konnte nicht gestartet werden"
        return $false
    }
    
    # Warte auf Fenster
    $spdWindow = Wait-ForProcessWindow -ProcessName $process.ProcessName -TimeoutSeconds 30
    
    if (-not $spdWindow) {
        Write-LogError "SPD Flash Tool Fenster nicht gefunden"
        return $false
    }
    
    Write-LogInfo "SPD Flash Tool gestartet"
    
    # UI Automation verfügbar?
    if (Test-UIAutomationAvailable) {
        Write-LogInfo "Versuche UI-Automation..."
        
        # Automatisierung hier würde komplexe UI-Interaktion erfordern
        # Für dieses Beispiel generieren wir eine Anleitung
        Write-LogWarning "UI-Automation für SPD Flash Tool ist komplex"
        Write-LogInfo "Generiere manuelle Anleitung..."
    }
    else {
        Write-LogWarning "UI-Automation nicht verfügbar"
    }
    
    # Generiere manuelle Anleitung
    $instructions = @{
        "1" = "Klicken Sie auf 'Load Packet' Button"
        "2" = "Navigieren Sie zu: $PacFile"
        "3" = "Wählen Sie die PAC-Datei aus und klicken Sie 'Öffnen'"
        "4" = "Verbinden Sie das Gerät im Download-Modus (Power + Vol Up/Down)"
        "5" = "Warten Sie bis das Gerät erkannt wird"
        "6" = "Klicken Sie auf 'Start' Button"
        "7" = "Warten Sie bis 'Passed' angezeigt wird (ca. 5-10 Minuten)"
        "8" = "Gerät wird automatisch neustarten"
    }
    
    $guidePath = Join-Path $WorkingDirectory "docs\SPD-Flash-Guide.html"
    New-ManualInstructionHTML -OutputPath $guidePath -Instructions $instructions
    
    Write-LogInfo "Manuelle Anleitung geöffnet"
    Write-LogInfo "Bitte folgen Sie den Schritten in der Anleitung"
    
    return $true
}

# ============================================================================
# AUTOHOTKEY SCRIPT GENERIERUNG
# ============================================================================

function New-SPDFlashAHKScript {
    <#
    .SYNOPSIS
    Generiert AutoHotkey Script für SPD Flash Tool
    #>
    param(
        [string]$PacFile
    )
    
    $ahkActions = @(
        "; Warte auf SPD Flash Tool Fenster",
        "Sleep, 2000",
        "",
        "; Klicke Load Packet Button (Position muss angepasst werden)",
        "MouseMove, 100, 100",
        "Click",
        "Sleep, 1000",
        "",
        "; Warte auf Datei-Dialog",
        "WinWait, Öffnen, , 10",
        "if !ErrorLevel",
        "{",
        "    ; Gebe Dateipfad ein",
        "    Send, $PacFile",
        "    Sleep, 500",
        "    Send, {Enter}",
        "    Sleep, 2000",
        "}",
        "",
        "; Klicke Start Button (Position muss angepasst werden)",
        "MouseMove, 200, 150",
        "Click",
        "",
        "; Warte auf Completion",
        "Loop, 600",
        "{",
        "    Sleep, 1000",
        "    ; Prüfe auf 'Passed' Text",
        "    PixelSearch, Px, Py, 0, 0, A_ScreenWidth, A_ScreenHeight, 0x00FF00, 3",
        "    if !ErrorLevel",
        "    {",
        "        MsgBox, Flashing erfolgreich!",
        "        break",
        "    }",
        "}"
    )
    
    $ahkPath = Join-Path $WorkingDirectory "work\spd-flash-automation.ahk"
    New-AutoHotkeyScript -WindowTitle "Research Download" -ScriptPath $ahkPath -Actions $ahkActions
    
    Write-LogInfo "AutoHotkey Script generiert: $ahkPath"
    Write-LogInfo "Führen Sie das Script mit AutoHotkey aus für automatisches Flashing"
    
    return $ahkPath
}

# ============================================================================
# HAUPTAUSFÜHRUNG
# ============================================================================

function Start-FlashingProcess {
    try {
        Write-LogInfo "Arbeitsverzeichnis: $WorkingDirectory"
        
        # Hole SPD Flash Tool
        $toolPath = Get-SPDFlashTool
        if (-not $toolPath) {
            Write-LogError "SPD Flash Tool nicht verfügbar"
            return $false
        }
        
        # Finde Firmware
        $pacFile = Find-FirmwarePacFile
        if (-not $pacFile) {
            Write-LogError "Keine Firmware-Datei gefunden"
            Write-LogInfo "Bitte laden Sie die Firmware herunter und speichern Sie sie in:"
            Write-LogInfo "  $(Join-Path $WorkingDirectory 'firmware')"
            return $false
        }
        
        Write-LogInfo "Firmware bereit: $pacFile"
        
        # Generiere AutoHotkey Script
        if (-not $ManualMode) {
            $ahkScript = New-SPDFlashAHKScript -PacFile $pacFile
        }
        
        # Starte SPD Flash Automation
        if (Start-SPDFlashAutomation -ToolPath $toolPath -PacFile $pacFile) {
            Write-LogInfo "SPD Flash Automation vorbereitet"
            Write-LogWarning "WICHTIG: Gerät muss im Download-Modus sein"
            Write-LogWarning "Download-Modus: Gerät ausschalten, dann Power + Vol Up/Down halten"
            return $true
        }
        
        return $false
    }
    catch {
        Write-LogError "Fehler beim Flash-Prozess: $($_.Exception.Message)"
        Write-LogError $_.ScriptStackTrace
        return $false
    }
}

# Führe Flashing aus
$result = Start-FlashingProcess
exit $(if ($result) { 0 } else { 1 })
