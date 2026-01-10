#Requires -Version 5.1
<#
.SYNOPSIS
    SPD Flash Tool automation helper for Realme C63 (RMX3939)

.DESCRIPTION
    Provides automation functions for SPD Flash Tool GUI interaction and process management.
    Since SPD Flash Tool doesn't have a command-line interface, this module helps prepare
    the environment and provides clear instructions for manual steps.

.NOTES
    Author: Realme C63 SPD Flash Tool Automation
    Version: 1.0
#>

function Start-SPDFlashTool {
    <#
    .SYNOPSIS
        Start SPD Flash Tool with firmware pre-loaded
    
    .PARAMETER ToolPath
        Path to SPD Flash Tool executable
    
    .PARAMETER FirmwarePath
        Path to .PAC firmware file
    
    .OUTPUTS
        Process object or $null on failure
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolPath,
        
        [Parameter(Mandatory = $false)]
        [string]$FirmwarePath
    )
    
    try {
        if (-not (Test-Path $ToolPath)) {
            Write-Log "SPD Flash Tool not found: $ToolPath" "ERROR"
            return $null
        }
        
        Write-Log "Starting SPD Flash Tool..." "INFO"
        
        # Start the tool
        $process = Start-Process -FilePath $ToolPath -PassThru -WorkingDirectory (Split-Path -Parent $ToolPath)
        
        if ($process) {
            Write-Log "SPD Flash Tool started (PID: $($process.Id))" "SUCCESS"
            
            # Give the tool time to initialize
            Start-Sleep -Seconds 3
            
            return $process
        }
        else {
            Write-Log "Failed to start SPD Flash Tool" "ERROR"
            return $null
        }
    }
    catch {
        Write-Log "Error starting SPD Flash Tool: $_" "ERROR"
        return $null
    }
}

function Show-SPDFlashInstructions {
    <#
    .SYNOPSIS
        Display detailed step-by-step instructions for using SPD Flash Tool
    
    .PARAMETER FirmwarePath
        Path to the firmware file to flash
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FirmwarePath
    )
    
    $firmwareName = Split-Path -Leaf $FirmwarePath
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                       ║" -ForegroundColor Cyan
    Write-Host "║              SPD FLASH TOOL - MANUELLE SCHRITTE                       ║" -ForegroundColor Cyan
    Write-Host "║                                                                       ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Firmware bereit: " -NoNewline -ForegroundColor White
    Write-Host $firmwareName -ForegroundColor Yellow
    Write-Host "Pfad: " -NoNewline -ForegroundColor White
    Write-Host $FirmwarePath -ForegroundColor Gray
    Write-Host ""
    Write-Host "┌─ SCHRITT 1: Firmware laden" -ForegroundColor Cyan
    Write-Host "│  1. Klicken Sie auf 'Load Packet' oder 'Browse'" -ForegroundColor White
    Write-Host "│  2. Navigieren Sie zu:" -ForegroundColor White
    Write-Host "│     $FirmwarePath" -ForegroundColor Gray
    Write-Host "│  3. Wählen Sie die .PAC-Datei aus" -ForegroundColor White
    Write-Host "│  4. Warten Sie, bis die Firmware geladen ist" -ForegroundColor White
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "┌─ SCHRITT 2: Gerät vorbereiten" -ForegroundColor Cyan
    Write-Host "│  1. Schalten Sie das Realme C63 VOLLSTÄNDIG AUS" -ForegroundColor White
    Write-Host "│  2. Trennen Sie das USB-Kabel (falls verbunden)" -ForegroundColor White
    Write-Host "│  3. Warten Sie 5 Sekunden" -ForegroundColor White
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "┌─ SCHRITT 3: Download-Modus aktivieren" -ForegroundColor Cyan
    Write-Host "│  1. Halten Sie die VOLUME DOWN-Taste gedrückt" -ForegroundColor White
    Write-Host "│  2. WÄHREND Sie die Taste halten:" -ForegroundColor Yellow
    Write-Host "│     Verbinden Sie das USB-Kabel mit dem PC" -ForegroundColor Yellow
    Write-Host "│  3. Halten Sie die Taste 5-10 Sekunden weiter gedrückt" -ForegroundColor White
    Write-Host "│  4. Das Gerät sollte im SPD Download-Modus sein" -ForegroundColor White
    Write-Host "│     (Bildschirm bleibt schwarz - das ist normal!)" -ForegroundColor Green
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "┌─ SCHRITT 4: Flash starten" -ForegroundColor Cyan
    Write-Host "│  1. SPD Flash Tool sollte das Gerät erkennen" -ForegroundColor White
    Write-Host "│     (COM-Port wird angezeigt)" -ForegroundColor White
    Write-Host "│  2. Klicken Sie auf 'Start' oder 'Download'" -ForegroundColor White
    Write-Host "│  3. Der Flash-Prozess beginnt automatisch" -ForegroundColor White
    Write-Host "│  4. NICHT das USB-Kabel trennen während des Flash!" -ForegroundColor Red
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "┌─ SCHRITT 5: Fertigstellung" -ForegroundColor Cyan
    Write-Host "│  1. Warten Sie auf 'PASSED' oder 'Download Success'" -ForegroundColor White
    Write-Host "│  2. Das Gerät startet automatisch neu" -ForegroundColor White
    Write-Host "│  3. Erster Boot kann 5-10 Minuten dauern" -ForegroundColor Yellow
    Write-Host "│  4. USB-Kabel kann nach 'PASSED' getrennt werden" -ForegroundColor White
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️  WICHTIGE HINWEISE:" -ForegroundColor Yellow
    Write-Host "   • Alle Daten werden gelöscht (Factory Reset)" -ForegroundColor Yellow
    Write-Host "   • Akku sollte mindestens 50% geladen sein" -ForegroundColor Yellow
    Write-Host "   • Verwenden Sie ein originales USB-Kabel" -ForegroundColor Yellow
    Write-Host "   • Bei Fehler: Gerät neu starten und wiederholen" -ForegroundColor Yellow
    Write-Host ""
}

function Wait-ForSPDDevice {
    <#
    .SYNOPSIS
        Wait for SPD device to be detected
    
    .PARAMETER TimeoutSeconds
        Timeout in seconds (default: 60)
    
    .OUTPUTS
        Boolean indicating if device was detected
    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 60
    )
    
    Write-Log "Waiting for SPD device to be detected..." "INFO"
    Write-Log "Timeout: $TimeoutSeconds seconds" "DEBUG"
    
    $startTime = Get-Date
    $detected = $false
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds -and -not $detected) {
        # Check for SPD/Spreadtrum device in Device Manager
        # Using WMI to query USB devices
        try {
            $devices = Get-WmiObject -Class Win32_PnPEntity | Where-Object {
                $_.Caption -match "Spreadtrum|SPRD|SPD|Download" -or
                $_.DeviceID -match "VID_1782"  # Spreadtrum Vendor ID
            }
            
            if ($devices) {
                Write-Log "SPD device detected!" "SUCCESS"
                foreach ($device in $devices) {
                    Write-Log "Device: $($device.Caption)" "INFO"
                }
                $detected = $true
                break
            }
        }
        catch {
            # Silently continue on WMI errors
        }
        
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 2
    }
    
    Write-Host ""
    
    if (-not $detected) {
        Write-Log "SPD device not detected within timeout period" "WARN"
    }
    
    return $detected
}

function Test-SPDDriversInstalled {
    <#
    .SYNOPSIS
        Check if SPD drivers are installed
    
    .OUTPUTS
        Boolean indicating if drivers are installed
    #>
    try {
        # Check for Spreadtrum drivers in system
        $drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object {
            $_.DeviceName -match "Spreadtrum|SPRD|SPD" -or
            $_.InfName -match "spd|spreadtrum"
        }
        
        if ($drivers) {
            Write-Log "SPD drivers found:" "SUCCESS"
            foreach ($driver in $drivers) {
                Write-Log "  - $($driver.DeviceName) (v$($driver.DriverVersion))" "INFO"
            }
            return $true
        }
        else {
            Write-Log "No SPD drivers found in system" "WARN"
            return $false
        }
    }
    catch {
        Write-Log "Could not check for SPD drivers: $_" "WARN"
        return $false
    }
}

function Get-SPDFlashToolPath {
    <#
    .SYNOPSIS
        Find SPD Flash Tool executable in extracted directory
    
    .PARAMETER SearchPath
        Directory to search in
    
    .OUTPUTS
        Path to executable or $null if not found
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchPath
    )
    
    try {
        # Common SPD Flash Tool executable names
        $possibleNames = @(
            "SPD_Upgrade_Tool.exe",
            "SPD_Flash_Tool.exe",
            "ResearchDownload.exe",
            "UpgradeDownload.exe"
        )
        
        foreach ($name in $possibleNames) {
            $exePath = Get-ChildItem -Path $SearchPath -Filter $name -Recurse -ErrorAction SilentlyContinue | 
                       Select-Object -First 1 -ExpandProperty FullName
            
            if ($exePath) {
                Write-Log "Found SPD Flash Tool: $exePath" "SUCCESS"
                return $exePath
            }
        }
        
        # If not found, try to find any .exe in the directory
        Write-Log "Common SPD Flash Tool executables not found, searching for any .exe..." "WARN"
        $anyExe = Get-ChildItem -Path $SearchPath -Filter "*.exe" -Recurse | 
                  Where-Object { $_.Name -match "SPD|Download|Upgrade|Research" } |
                  Select-Object -First 1
        
        if ($anyExe) {
            Write-Log "Found potential SPD Flash Tool: $($anyExe.FullName)" "WARN"
            return $anyExe.FullName
        }
        
        Write-Log "No SPD Flash Tool executable found in $SearchPath" "ERROR"
        return $null
    }
    catch {
        Write-Log "Error searching for SPD Flash Tool: $_" "ERROR"
        return $null
    }
}

function Show-FlashProgressMonitor {
    <#
    .SYNOPSIS
        Display a progress monitor while flashing
    
    .PARAMETER DurationSeconds
        Expected duration of flash process
    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$DurationSeconds = 300
    )
    
    Write-Log "Monitoring flash process (estimated time: $DurationSeconds seconds)..." "INFO"
    
    $startTime = Get-Date
    $lastUpdate = $startTime
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $DurationSeconds) {
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $percent = [Math]::Min(100, ($elapsed / $DurationSeconds) * 100)
        
        if (((Get-Date) - $lastUpdate).TotalSeconds -ge 5) {
            Write-LogProgress -Activity "Flash Process" -Status "In Progress..." -PercentComplete $percent
            $lastUpdate = Get-Date
        }
        
        Start-Sleep -Seconds 1
    }
}

function Confirm-UserAction {
    <#
    .SYNOPSIS
        Prompt user to confirm an action was completed
    
    .PARAMETER Message
        Confirmation message
    
    .OUTPUTS
        Boolean indicating user's response
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
    $response = Read-Host "Fortfahren? (J/n)"
    
    return ($response -ne "n" -and $response -ne "N")
}

# Export functions
Export-ModuleMember -Function @(
    'Start-SPDFlashTool',
    'Show-SPDFlashInstructions',
    'Wait-ForSPDDevice',
    'Test-SPDDriversInstalled',
    'Get-SPDFlashToolPath',
    'Show-FlashProgressMonitor',
    'Confirm-UserAction'
)
