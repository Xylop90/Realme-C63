#Requires -Version 5.1
<#
.SYNOPSIS
    UI-Automation für SPD Flash Tool
    
.DESCRIPTION
    Automatisiert die GUI-Interaktion mit SPD Flash Tool
    über UIAutomation oder AutoHotkey
    
.NOTES
    Author: Realme C63 Automated Installation System
    Version: 1.0
    Date: 2026-01-10
#>

# Importiere Logger
. "$PSScriptRoot\logger.ps1"

function Test-UIAutomationAvailable {
    <#
    .SYNOPSIS
    Prüft ob UIAutomation verfügbar ist
    #>
    try {
        Add-Type -AssemblyName UIAutomationClient -ErrorAction Stop
        Add-Type -AssemblyName UIAutomationTypes -ErrorAction Stop
        return $true
    }
    catch {
        Write-LogWarning "UIAutomation nicht verfügbar: $($_.Exception.Message)"
        return $false
    }
}

function Find-WindowByTitle {
    <#
    .SYNOPSIS
    Findet Fenster nach Titel
    #>
    param(
        [string]$Title,
        [int]$TimeoutSeconds = 30
    )
    
    Write-LogInfo "Suche Fenster: $Title"
    $startTime = Get-Date
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
        $processes = Get-Process | Where-Object { $_.MainWindowTitle -like "*$Title*" }
        
        if ($processes) {
            Write-LogInfo "Fenster gefunden: $($processes[0].MainWindowTitle)"
            return $processes[0]
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    Write-LogWarning "Fenster nicht gefunden: $Title"
    return $null
}

function Click-ButtonByText {
    <#
    .SYNOPSIS
    Klickt Button anhand des Textes
    #>
    param(
        [System.Diagnostics.Process]$Process,
        [string]$ButtonText
    )
    
    try {
        Write-LogInfo "Versuche Button zu klicken: $ButtonText"
        
        # Verwende Windows Forms für einfache Automation
        Add-Type -AssemblyName System.Windows.Forms
        
        # Hole Fenster-Handle
        $hwnd = $Process.MainWindowHandle
        if ($hwnd -eq 0) {
            Write-LogError "Kein gültiges Fenster-Handle"
            return $false
        }
        
        # Setze Fenster in den Vordergrund
        [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
        [Microsoft.VisualBasic.Interaction]::AppActivate($Process.Id)
        Start-Sleep -Milliseconds 500
        
        Write-LogDebug "Fenster aktiviert, manuelle Interaktion kann erforderlich sein"
        return $true
    }
    catch {
        Write-LogError "Fehler beim Klicken: $($_.Exception.Message)"
        return $false
    }
}

function Send-Keystrokes {
    <#
    .SYNOPSIS
    Sendet Tastatureingaben an Anwendung
    #>
    param(
        [System.Diagnostics.Process]$Process,
        [string]$Keys
    )
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        
        # Aktiviere Fenster
        [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
        [Microsoft.VisualBasic.Interaction]::AppActivate($Process.Id)
        Start-Sleep -Milliseconds 300
        
        # Sende Tasten
        [System.Windows.Forms.SendKeys]::SendWait($Keys)
        Write-LogDebug "Tasten gesendet: $Keys"
        return $true
    }
    catch {
        Write-LogError "Fehler beim Senden von Tasten: $($_.Exception.Message)"
        return $false
    }
}

function Wait-ForProcessWindow {
    <#
    .SYNOPSIS
    Wartet bis Prozess ein Fenster hat
    #>
    param(
        [string]$ProcessName,
        [int]$TimeoutSeconds = 30
    )
    
    Write-LogInfo "Warte auf Prozess-Fenster: $ProcessName"
    $startTime = Get-Date
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | 
            Where-Object { $_.MainWindowHandle -ne 0 } |
            Select-Object -First 1
        
        if ($process) {
            Write-LogInfo "Prozess-Fenster gefunden"
            return $process
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    Write-LogWarning "Prozess-Fenster nicht gefunden: $ProcessName"
    return $null
}

function New-AutoHotkeyScript {
    <#
    .SYNOPSIS
    Generiert AutoHotkey-Script als Fallback
    #>
    param(
        [string]$WindowTitle,
        [string]$ScriptPath,
        [string[]]$Actions
    )
    
    $ahkScript = @"
; Auto-generated SPD Flash Tool Automation Script
; Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Window

; Warte auf Fenster
WinWait, $WindowTitle, , 30
if ErrorLevel
{
    MsgBox, Fenster nicht gefunden: $WindowTitle
    ExitApp, 1
}

WinActivate, $WindowTitle
Sleep, 500

"@
    
    # Füge Actions hinzu
    foreach ($action in $Actions) {
        $ahkScript += "$action`n"
    }
    
    $ahkScript += "`nExitApp, 0`n"
    
    # Speichere Script
    $ahkScript | Out-File -FilePath $ScriptPath -Encoding ASCII
    Write-LogInfo "AutoHotkey-Script generiert: $ScriptPath"
    
    return $ScriptPath
}

function Invoke-AutoHotkeyScript {
    <#
    .SYNOPSIS
    Führt AutoHotkey-Script aus
    #>
    param([string]$ScriptPath)
    
    # Suche AutoHotkey
    $ahkPaths = @(
        "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe",
        "$env:ProgramFiles(x86)\AutoHotkey\AutoHotkey.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\AutoHotkey.exe"
    )
    
    $ahkExe = $ahkPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if (-not $ahkExe) {
        Write-LogWarning "AutoHotkey nicht installiert"
        return $false
    }
    
    try {
        Write-LogInfo "Führe AutoHotkey-Script aus: $ScriptPath"
        Start-Process -FilePath $ahkExe -ArgumentList "`"$ScriptPath`"" -Wait
        return $true
    }
    catch {
        Write-LogError "Fehler beim Ausführen des AHK-Scripts: $($_.Exception.Message)"
        return $false
    }
}

function New-ManualInstructionHTML {
    <#
    .SYNOPSIS
    Generiert HTML-Anleitung als Fallback
    #>
    param(
        [string]$OutputPath,
        [hashtable]$Instructions
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SPD Flash Tool - Manuelle Anleitung</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        .step {
            background: #ecf0f1;
            margin: 15px 0;
            padding: 15px;
            border-left: 4px solid #3498db;
            border-radius: 5px;
        }
        .step-number {
            font-weight: bold;
            color: #3498db;
            font-size: 1.2em;
        }
        .warning {
            background: #fff3cd;
            border-left-color: #ffc107;
            color: #856404;
        }
        .success {
            background: #d4edda;
            border-left-color: #28a745;
            color: #155724;
        }
        code {
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 SPD Flash Tool - Manuelle Anleitung</h1>
        <p><strong>Generiert am:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="step warning">
            <p><strong>⚠️ Wichtig:</strong> Die automatische GUI-Steuerung war nicht möglich. 
            Bitte folgen Sie diesen manuellen Schritten.</p>
        </div>
"@
    
    $stepNumber = 1
    foreach ($key in $Instructions.Keys) {
        $html += @"
        <div class="step">
            <span class="step-number">Schritt $stepNumber:</span> $($Instructions[$key])
        </div>
"@
        $stepNumber++
    }
    
    $html += @"
        <div class="step success">
            <p><strong>✅ Fertig!</strong> Wenn alle Schritte erfolgreich waren, 
            sollte die Installation abgeschlossen sein.</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-LogInfo "Manuelle Anleitung generiert: $OutputPath"
    
    # Öffne im Browser
    Start-Process $OutputPath
    
    return $OutputPath
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Test-UIAutomationAvailable',
    'Find-WindowByTitle',
    'Click-ButtonByText',
    'Send-Keystrokes',
    'Wait-ForProcessWindow',
    'New-AutoHotkeyScript',
    'Invoke-AutoHotkeyScript',
    'New-ManualInstructionHTML'
)
