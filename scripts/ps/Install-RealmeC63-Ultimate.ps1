#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Realme C63 Ultimate Auto-Installer - Haupt-Orchestrator

.DESCRIPTION
    KI-gestützter Vollautomatischer Installations-Assistent für Realme C63
    mit Bootloader-Unlock, Root (Magisk), TWRP und Auto-Updates

.PARAMETER WorkingDirectory
    Arbeitsverzeichnis für Downloads und temporäre Dateien

.PARAMETER SkipToolInstall
    Überspringt die Tool-Installation

.PARAMETER SkipBootloaderUnlock
    Überspringt den Bootloader-Unlock

.PARAMETER SkipRoot
    Überspringt die Root-Installation

.NOTES
    Author: Xylop90
    Version: 2.0.0
    Copyright: © Elektronikx-Center-Matte by Alexander Mathey
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = (Join-Path $PSScriptRoot "..\.."),
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipToolInstall,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBootloaderUnlock,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipRoot
)

# Set error action
$ErrorActionPreference = "Stop"

# Initialize script variables
$script:WorkDir = $WorkingDirectory
$script:LogsDir = Join-Path $WorkDir "work\logs"
$script:ToolsDir = Join-Path $WorkDir "work\tools"
$script:ConfigDir = Join-Path $WorkDir "config"

# Import modules
$modulesPath = Join-Path $PSScriptRoot "..\modules"

try {
    Import-Module (Join-Path $modulesPath "UI-Helper.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $modulesPath "Advanced-Logger.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $modulesPath "Download-Manager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $modulesPath "Device-Manager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $modulesPath "Tool-Manager.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $modulesPath "Bootloader-Unlock.psm1") -Force -ErrorAction Stop
    Import-Module (Join-Path $modulesPath "Root-Manager.psm1") -Force -ErrorAction Stop
}
catch {
    Write-Host "ERROR: Failed to import required modules: $_" -ForegroundColor Red
    Write-Host "Please ensure all module files are present in: $modulesPath" -ForegroundColor Red
    exit 1
}

function Initialize-Installer {
    <#
    .SYNOPSIS
    Initialisiert den Installer
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Show banner
        Show-ASCIIBanner
        
        # Initialize logger
        if (-not (Test-Path $script:LogsDir)) {
            New-Item -Path $script:LogsDir -ItemType Directory -Force | Out-Null
        }
        
        $initialized = Initialize-Logger -LogDirectory $script:LogsDir -MinimumLevel "INFO"
        
        if (-not $initialized) {
            Write-Host "WARNING: Logger initialization failed, continuing without logging" -ForegroundColor Yellow
        }
        
        Write-Log -Message "Realme C63 Ultimate Auto-Installer started" -Level "INFO" -Category "Main"
        Write-Log -Message "Working directory: $script:WorkDir" -Level "INFO" -Category "Main"
        
        # Load configuration
        $configPath = Join-Path $script:ConfigDir "installer-config.json"
        if (Test-Path $configPath) {
            $script:Config = Get-Content $configPath -Raw | ConvertFrom-Json
            Write-Log -Message "Configuration loaded" -Level "INFO" -Category "Main"
        }
        else {
            Write-Log -Message "Configuration file not found, using defaults" -Level "WARNING" -Category "Main"
        }
        
        return $true
    }
    catch {
        Write-Host "ERROR: Initialization failed: $_" -ForegroundColor Red
        return $false
    }
}

function Test-Prerequisites {
    <#
    .SYNOPSIS
    Prüft alle Voraussetzungen
    #>
    [CmdletBinding()]
    param()
    
    try {
        Show-StepBanner -Step "VORAUSSETZUNGEN PRÜFEN" -Description "System- und Geräte-Checks"
        
        $checks = @{
            "Windows 10/11"           = ($PSVersionTable.PSVersion.Major -ge 5)
            "Administrator-Rechte"    = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            "PowerShell 5.1+"         = ($PSVersionTable.PSVersion.Major -ge 5 -and $PSVersionTable.PSVersion.Minor -ge 1)
            "Internetverbindung"      = (Test-Connection -ComputerName google.com -Count 1 -Quiet)
        }
        
        $allPassed = $true
        
        foreach ($check in $checks.GetEnumerator()) {
            if ($check.Value) {
                Show-StatusMessage -Message "$($check.Key): OK" -Status "Success"
            }
            else {
                Show-StatusMessage -Message "$($check.Key): FEHLER" -Status "Error"
                $allPassed = $false
            }
        }
        
        if (-not $allPassed) {
            Show-ErrorBox -Title "Voraussetzungen nicht erfüllt" `
                -Message "Nicht alle Voraussetzungen sind erfüllt" `
                -Details @("Bitte beheben Sie die Fehler und starten Sie neu")
            return $false
        }
        
        Write-Log -Message "All prerequisites met" -Level "INFO" -Category "Main"
        return $true
    }
    catch {
        Write-ErrorLog -Message "Prerequisites check failed" -ErrorRecord $_ -Category "Main"
        return $false
    }
}

function Show-MainMenu {
    <#
    .SYNOPSIS
    Zeigt das Hauptmenü an
    #>
    [CmdletBinding()]
    param()
    
    $options = @(
        "Vollständige Installation (Empfohlen)",
        "Nur Tools installieren",
        "Nur Bootloader entsperren",
        "Nur Root installieren (Magisk)",
        "Geräte-Information anzeigen",
        "Erweiterte Optionen",
        "Beenden"
    )
    
    $selection = Show-Menu -Options $options -Title "HAUPTMENÜ - Bitte wählen Sie eine Option:"
    
    return $selection
}

function Start-FullInstallation {
    <#
    .SYNOPSIS
    Führt die vollständige Installation durch
    #>
    [CmdletBinding()]
    param()
    
    try {
        Show-StepBanner -Step "VOLLSTÄNDIGE INSTALLATION" -Description "Automatische Installation aller Komponenten"
        
        $steps = @{
            "Tools installieren"      = "Pending"
            "Gerät verbinden"         = "Pending"
            "Bootloader entsperren"   = "Pending"
            "Root installieren"       = "Pending"
            "Abschluss"               = "Pending"
        }
        
        Show-InstallationProgress -Steps $steps
        
        # Step 1: Install Tools
        if (-not $SkipToolInstall) {
            $steps["Tools installieren"] = "InProgress"
            Show-InstallationProgress -Steps $steps
            
            $success = Install-AllTools -WorkDirectory $script:WorkDir
            
            $steps["Tools installieren"] = if ($success) { "Complete" } else { "Failed" }
            Show-InstallationProgress -Steps $steps
            
            if (-not $success) {
                Show-ErrorBox -Title "Tool-Installation fehlgeschlagen" `
                    -Message "Einige Tools konnten nicht installiert werden" `
                    -Details @("Installation wird fortgesetzt, aber einige Funktionen sind möglicherweise nicht verfügbar")
            }
        }
        else {
            $steps["Tools installieren"] = "Skipped"
        }
        
        # Step 2: Connect Device
        $steps["Gerät verbinden"] = "InProgress"
        Show-InstallationProgress -Steps $steps
        
        Start-ADBServer | Out-Null
        
        if (-not (Test-DeviceConnected)) {
            Show-StatusMessage -Message "Bitte verbinden Sie Ihr Realme C63 via USB" -Status "Warning"
            Show-StatusMessage -Message "Aktivieren Sie USB-Debugging in den Entwickleroptionen" -Status "Info"
            
            $connected = Wait-ForDevice -TimeoutSeconds 60
            
            if (-not $connected) {
                Show-ErrorBox -Title "Gerät nicht gefunden" `
                    -Message "Kein Gerät konnte erkannt werden" `
                    -Details @(
                    "Stellen Sie sicher, dass USB-Debugging aktiviert ist",
                    "Akzeptieren Sie die USB-Debugging-Anfrage auf dem Gerät",
                    "Verwenden Sie ein funktionierendes USB-Kabel"
                )
                return $false
            }
        }
        
        # Get device info
        $deviceInfo = Get-DeviceInfo
        
        if ($deviceInfo) {
            Show-StatusMessage -Message "Gerät erkannt: $($deviceInfo.Model)" -Status "Success"
            
            # Check compatibility
            $compatible = Test-DeviceCompatible -DeviceInfo $deviceInfo
            
            if (-not $compatible) {
                $continue = Show-Confirmation -Message "Gerät ist möglicherweise nicht kompatibel. Trotzdem fortfahren?" -DefaultYes $false
                if (-not $continue) {
                    return $false
                }
            }
        }
        
        $steps["Gerät verbinden"] = "Complete"
        Show-InstallationProgress -Steps $steps
        
        # Step 3: Unlock Bootloader
        if (-not $SkipBootloaderUnlock) {
            $steps["Bootloader entsperren"] = "InProgress"
            Show-InstallationProgress -Steps $steps
            
            $success = Start-BootloaderUnlock -WorkDirectory $script:WorkDir
            
            $steps["Bootloader entsperren"] = if ($success) { "Complete" } else { "Failed" }
            Show-InstallationProgress -Steps $steps
            
            if (-not $success) {
                $continue = Show-Confirmation -Message "Bootloader-Unlock fehlgeschlagen. Trotzdem fortfahren?" -DefaultYes $false
                if (-not $continue) {
                    return $false
                }
            }
        }
        else {
            $steps["Bootloader entsperren"] = "Skipped"
        }
        
        # Step 4: Install Root
        if (-not $SkipRoot) {
            $steps["Root installieren"] = "InProgress"
            Show-InstallationProgress -Steps $steps
            
            $success = Start-RootProcess -WorkDirectory $script:WorkDir
            
            $steps["Root installieren"] = if ($success) { "Complete" } else { "Failed" }
            Show-InstallationProgress -Steps $steps
        }
        else {
            $steps["Root installieren"] = "Skipped"
        }
        
        # Step 5: Completion
        $steps["Abschluss"] = "Complete"
        Show-InstallationProgress -Steps $steps
        
        Show-CompletionScreen
        
        return $true
    }
    catch {
        Write-ErrorLog -Message "Full installation failed" -ErrorRecord $_ -Category "Main"
        return $false
    }
}

function Show-DeviceInformation {
    <#
    .SYNOPSIS
    Zeigt detaillierte Geräte-Informationen an
    #>
    [CmdletBinding()]
    param()
    
    try {
        Show-StepBanner -Step "GERÄTE-INFORMATION" -Description "Detaillierte Informationen über Ihr Gerät"
        
        if (-not (Test-DeviceConnected)) {
            Show-StatusMessage -Message "Kein Gerät verbunden" -Status "Warning"
            return
        }
        
        $deviceInfo = Get-DeviceInfo
        
        if (-not $deviceInfo) {
            Show-StatusMessage -Message "Konnte Geräte-Informationen nicht abrufen" -Status "Error"
            return
        }
        
        Write-Host ""
        Write-ColoredOutput -Message "═══════════════════════════════════════════════════" -Type "Header"
        Write-ColoredOutput -Message "GERÄTE-INFORMATIONEN" -Type "Header"
        Write-ColoredOutput -Message "═══════════════════════════════════════════════════" -Type "Header"
        Write-Host ""
        
        $infoTable = @{
            "Modell"              = $deviceInfo.Model
            "Gerät"               = $deviceInfo.Device
            "Hersteller"          = $deviceInfo.Manufacturer
            "Marke"               = $deviceInfo.Brand
            "Android Version"     = $deviceInfo.AndroidVersion
            "SDK Version"         = $deviceInfo.SDKVersion
            "Build-Nummer"        = $deviceInfo.BuildNumber
            "Plattform"           = $deviceInfo.Platform
            "CPU-Architektur"     = $deviceInfo.CPUArchitecture
            "Serial"              = $deviceInfo.Serial
        }
        
        foreach ($item in $infoTable.GetEnumerator()) {
            Write-ColoredOutput -Message ("{0,-20}: {1}" -f $item.Key, $item.Value) -Type "Info"
        }
        
        Write-Host ""
        
        # Get device state
        $deviceState = Get-DeviceState -DeviceInfo $deviceInfo
        
        if ($deviceState) {
            Write-ColoredOutput -Message "═══════════════════════════════════════════════════" -Type "Header"
            Write-ColoredOutput -Message "GERÄTE-STATUS" -Type "Header"
            Write-ColoredOutput -Message "═══════════════════════════════════════════════════" -Type "Header"
            Write-Host ""
            
            $statusTable = @{
                "Root-Zugriff"        = if ($deviceState.IsRooted) { "Ja ✓" } else { "Nein ✗" }
                "Magisk installiert"  = if ($deviceState.HasMagisk) { "Ja ✓" } else { "Nein ✗" }
                "Bootloader gesperrt" = if ($deviceState.BootloaderLocked) { "Ja" } else { "Nein (entsperrt)" }
                "Stock-ROM"           = if ($deviceState.IsStock) { "Ja" } else { "Modifiziert" }
            }
            
            foreach ($item in $statusTable.GetEnumerator()) {
                $type = if ($item.Value -match "✓") { "Success" } elseif ($item.Value -match "✗") { "Warning" } else { "Info" }
                Write-ColoredOutput -Message ("{0,-20}: {1}" -f $item.Key, $item.Value) -Type $type
            }
            
            Write-Host ""
        }
        
        Read-Host "Drücken Sie Enter um fortzufahren"
    }
    catch {
        Write-ErrorLog -Message "Failed to show device information" -ErrorRecord $_ -Category "Main"
    }
}

function Show-CompletionScreen {
    <#
    .SYNOPSIS
    Zeigt den Abschluss-Bildschirm an
    #>
    [CmdletBinding()]
    param()
    
    Write-Host ""
    Write-ColoredOutput -Message "╔═══════════════════════════════════════════════════════════════════════╗" -Type "Success"
    Write-ColoredOutput -Message "║                                                                       ║" -Type "Success"
    Write-ColoredOutput -Message "║     ✓ INSTALLATION ERFOLGREICH ABGESCHLOSSEN!                        ║" -Type "Success"
    Write-ColoredOutput -Message "║                                                                       ║" -Type "Success"
    Write-ColoredOutput -Message "╚═══════════════════════════════════════════════════════════════════════╝" -Type "Success"
    Write-Host ""
    
    Write-ColoredOutput -Message "Nächste Schritte:" -Type "Header"
    Write-ColoredOutput -Message "• Ihr Gerät wurde erfolgreich modifiziert" -Type "Info"
    Write-ColoredOutput -Message "• Überprüfen Sie die Magisk App für Root-Management" -Type "Info"
    Write-ColoredOutput -Message "• Installieren Sie Magisk-Module nach Bedarf" -Type "Info"
    Write-ColoredOutput -Message "• Erstellen Sie ein Backup Ihres modifizierten Systems" -Type "Info"
    Write-Host ""
    
    Write-ColoredOutput -Message "Support & Dokumentation:" -Type "Header"
    Write-ColoredOutput -Message "• GitHub: https://github.com/Xylop90/Realme-C63" -Type "Info"
    Write-ColoredOutput -Message "• Issues: https://github.com/Xylop90/Realme-C63/issues" -Type "Info"
    Write-Host ""
    
    # Show log summary
    $summary = Get-LogSummary
    if ($summary) {
        Write-ColoredOutput -Message "Installation Summary:" -Type "Header"
        Write-ColoredOutput -Message "• Dauer: $($summary.duration.ToString('hh\:mm\:ss'))" -Type "Info"
        Write-ColoredOutput -Message "• Log-Datei: $($summary.log_file)" -Type "Info"
        Write-Host ""
    }
    
    Write-ColoredOutput -Message "Vielen Dank für die Nutzung des Realme C63 Ultimate Auto-Installers!" -Type "Success"
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    # Initialize
    $initialized = Initialize-Installer
    
    if (-not $initialized) {
        Write-Host "Initialization failed. Exiting..." -ForegroundColor Red
        exit 1
    }
    
    # Check prerequisites
    $prereqsMet = Test-Prerequisites
    
    if (-not $prereqsMet) {
        Write-Log -Message "Prerequisites not met, exiting" -Level "ERROR" -Category "Main"
        exit 1
    }
    
    # Main loop
    do {
        $selection = Show-MainMenu
        
        switch ($selection) {
            0 {
                # Full installation
                Start-FullInstallation
                Read-Host "`nDrücken Sie Enter um zum Hauptmenü zurückzukehren"
            }
            1 {
                # Tools only
                Install-AllTools -WorkDirectory $script:WorkDir
                Read-Host "`nDrücken Sie Enter um zum Hauptmenü zurückzukehren"
            }
            2 {
                # Bootloader only
                Start-BootloaderUnlock -WorkDirectory $script:WorkDir
                Read-Host "`nDrücken Sie Enter um zum Hauptmenü zurückzukehren"
            }
            3 {
                # Root only
                Start-RootProcess -WorkDirectory $script:WorkDir
                Read-Host "`nDrücken Sie Enter um zum Hauptmenü zurückzukehren"
            }
            4 {
                # Device info
                Show-DeviceInformation
            }
            5 {
                # Advanced options
                Write-ColoredOutput -Message "Erweiterte Optionen sind in einer zukünftigen Version verfügbar" -Type "Warning"
                Read-Host "`nDrücken Sie Enter um zum Hauptmenü zurückzukehren"
            }
            6 {
                # Exit
                Write-Host ""
                Write-ColoredOutput -Message "Auf Wiedersehen!" -Type "Success"
                Write-Log -Message "Installer exited by user" -Level "INFO" -Category "Main"
                exit 0
            }
        }
    } while ($true)
}
catch {
    Write-Host "`nFATAL ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    Write-ErrorLog -Message "Fatal error in main execution" -ErrorRecord $_ -Category "Main"
    
    Read-Host "`nDrücken Sie Enter zum Beenden"
    exit 1
}
