<#
.SYNOPSIS
    SPD-Automation Modul fuer SPD Flash Tool Integration

.DESCRIPTION
    Funktionen fuer:
    - SPD Flash Tool Prozess-Management
    - GUI-Automation (UI Automation Framework)
    - Success-Detection

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
    
    Hinweis: Vollstaendige GUI-Automation erfordert UI Automation Framework
    und ist komplex. Dieses Modul bietet Basis-Funktionalitaet.
#>

# Lade Logger wenn verfuegbar
$modulePath = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $modulePath "modules\Logger.psm1") -Force -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Sucht nach installiertem SPD Flash Tool

.EXAMPLE
    Find-SPDFlashTool
#>
function Find-SPDFlashTool {
    [CmdletBinding()]
    param()

    # Bekannte Installationspfade
    $possiblePaths = @(
        "C:\Program Files\SPD Flash Tool\SPD_Upgrade_Tool.exe",
        "C:\Program Files (x86)\SPD Flash Tool\SPD_Upgrade_Tool.exe",
        "C:\SPD Flash Tool\SPD_Upgrade_Tool.exe",
        "$env:USERPROFILE\Desktop\SPD Flash Tool\SPD_Upgrade_Tool.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path -Path $path) {
            if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                Write-SuccessLog "SPD Flash Tool gefunden: $path"
            }
            return $path
        }
    }

    if (Get-Command Write-WarnLog -ErrorAction SilentlyContinue) {
        Write-WarnLog "SPD Flash Tool nicht gefunden"
    }
    return $null
}

<#
.SYNOPSIS
    Startet SPD Flash Tool

.PARAMETER ToolPath
    Pfad zur SPD Flash Tool .exe

.EXAMPLE
    Start-SPDFlashTool -ToolPath "C:\SPD Flash Tool\SPD_Upgrade_Tool.exe"
#>
function Start-SPDFlashTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ToolPath = ""
    )

    if (-not $ToolPath) {
        $ToolPath = Find-SPDFlashTool
    }

    if (-not $ToolPath -or -not (Test-Path -Path $ToolPath)) {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "SPD Flash Tool nicht gefunden"
        }
        return $null
    }

    try {
        if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
            Write-InfoLog "Starte SPD Flash Tool..."
        }

        $process = Start-Process -FilePath $ToolPath -PassThru
        Start-Sleep -Seconds 2

        if ($process -and -not $process.HasExited) {
            if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                Write-SuccessLog "SPD Flash Tool gestartet (PID: $($process.Id))"
            }
            return $process
        }
        else {
            if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
                Write-ErrorLog "SPD Flash Tool konnte nicht gestartet werden"
            }
            return $null
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler beim Starten des SPD Flash Tools: $_" -Exception $_.Exception
        }
        return $null
    }
}

<#
.SYNOPSIS
    Prueft ob SPD Flash Tool laeuft

.EXAMPLE
    Test-SPDFlashToolRunning
#>
function Test-SPDFlashToolRunning {
    [CmdletBinding()]
    param()

    try {
        $process = Get-Process -Name "SPD_Upgrade_Tool" -ErrorAction SilentlyContinue
        return $process -ne $null
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Stoppt SPD Flash Tool

.EXAMPLE
    Stop-SPDFlashTool
#>
function Stop-SPDFlashTool {
    [CmdletBinding()]
    param()

    try {
        $processes = Get-Process -Name "SPD_Upgrade_Tool" -ErrorAction SilentlyContinue
        
        if ($processes) {
            foreach ($process in $processes) {
                $process.CloseMainWindow() | Out-Null
                Start-Sleep -Seconds 2
                
                if (-not $process.HasExited) {
                    $process.Kill()
                }
            }

            if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
                Write-InfoLog "SPD Flash Tool beendet"
            }
            return $true
        }
        else {
            if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
                Write-InfoLog "SPD Flash Tool laeuft nicht"
            }
            return $true
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler beim Beenden des SPD Flash Tools: $_" -Exception $_.Exception
        }
        return $false
    }
}

<#
.SYNOPSIS
    Zeigt Anweisungen fuer manuelles Flashen

.PARAMETER FirmwarePath
    Pfad zur Firmware-Datei

.EXAMPLE
    Show-FlashInstructions -FirmwarePath "C:\firmware.pac"
#>
function Show-FlashInstructions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$FirmwarePath = ""
    )

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Yellow
    Write-Host "              SPD FLASH TOOL - MANUELLE ANWEISUNGEN                        " -ForegroundColor Yellow
    Write-Host "============================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Schritte zum Flashen der Firmware:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. SPD Flash Tool oeffnen" -ForegroundColor White
    Write-Host "2. Klicken Sie auf 'Load Packet' und waehlen Sie die .pac-Datei:" -ForegroundColor White
    
    if ($FirmwarePath) {
        Write-Host "   $FirmwarePath" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "3. Geraet ausschalten" -ForegroundColor White
    Write-Host "4. Geraet im Download-Modus verbinden:" -ForegroundColor White
    Write-Host "   - Druecken und halten: Lautstaerke Runter + Lautstaerke Hoch" -ForegroundColor Gray
    Write-Host "   - USB-Kabel anschliessen" -ForegroundColor Gray
    Write-Host "   - Warten bis 'COM Port' im SPD Tool erscheint" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Klicken Sie auf 'Start Downloading' (Play-Button)" -ForegroundColor White
    Write-Host "6. Warten Sie bis 'Passed' angezeigt wird" -ForegroundColor White
    Write-Host "7. Geraet wird automatisch neu starten" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[!] WICHTIG: Unterbrechen Sie den Vorgang NICHT!" -ForegroundColor Red
    Write-Host "[!] Trennen Sie das USB-Kabel NICHT waehrend des Flash-Vorgangs!" -ForegroundColor Red
    Write-Host ""
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Find-SPDFlashTool',
    'Start-SPDFlashTool',
    'Test-SPDFlashToolRunning',
    'Stop-SPDFlashTool',
    'Show-FlashInstructions'
)
