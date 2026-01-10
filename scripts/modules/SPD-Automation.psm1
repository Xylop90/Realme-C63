<#
.SYNOPSIS
    SPD Flash Tool Automation for Realme C63 (RMX3939)

.DESCRIPTION
    Automates SPD/Spreadtrum flash tool operations for RMX3939.
    Handles firmware flashing, tool download, and guided automation.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

#Requires -Version 5.1

# Import required modules
Import-Module "$PSScriptRoot\Logger.psm1" -Force
Import-Module "$PSScriptRoot\UI-Helper.psm1" -Force
Import-Module "$PSScriptRoot\Download-Manager.psm1" -Force
Import-Module "$PSScriptRoot\Hash-Verifier.psm1" -Force

<#
.SYNOPSIS
    Downloads SPD Flash Tool
#>
function Get-SPDFlashTool {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "work\extracted\spd"
    )
    
    try {
        Write-Log "Downloading SPD Flash Tool..." "INFO"
        Show-Message "Downloading SPD Flash Tool..." "INFO"
        
        # Load tool versions config
        $config = Get-Content "config\tool-versions.json" | ConvertFrom-Json
        $spdTool = $config.tools | Where-Object { $_.name -eq "SPD Flash Tool" }
        
        if (-not $spdTool) {
            throw "SPD Flash Tool configuration not found"
        }
        
        # Download SPD Flash Tool
        $downloadPath = "work\downloads\spd-flash-tool.zip"
        
        $downloadResult = Download-FileWithRetry -Url $spdTool.url -OutputPath $downloadPath -ExpectedHash $spdTool.sha256
        
        if (-not $downloadResult.Success) {
            throw "Failed to download SPD Flash Tool"
        }
        
        # Extract
        Write-Log "Extracting SPD Flash Tool..." "INFO"
        Show-ProgressBar -Percent 50 -Status "Extracting..."
        
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
        Expand-Archive -Path $downloadPath -DestinationPath $OutputPath -Force
        
        Write-Log "SPD Flash Tool extracted to $OutputPath" "OK"
        Show-ProgressBar -Percent 100 -Status "Complete"
        
        return @{
            Success = $true
            Path = $OutputPath
            Executable = (Get-ChildItem -Path $OutputPath -Filter "*.exe" -Recurse | Select-Object -First 1).FullName
        }
    }
    catch {
        Write-Log "SPD Flash Tool download failed: $_" "ERROR"
        Show-Message "SPD Flash Tool download failed: $_" "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

<#
.SYNOPSIS
    Downloads SPD Research Tool
#>
function Get-SPDResearchTool {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "work\extracted\spd-research"
    )
    
    try {
        Write-Log "Downloading SPD Research Tool..." "INFO"
        Show-Message "Downloading SPD Research Tool..." "INFO"
        
        # Load tool versions config
        $config = Get-Content "config\tool-versions.json" | ConvertFrom-Json
        $researchTool = $config.tools | Where-Object { $_.name -eq "SPD Research Tool" }
        
        if (-not $researchTool) {
            throw "SPD Research Tool configuration not found"
        }
        
        # Download
        $downloadPath = "work\downloads\spd-research-tool.zip"
        
        $downloadResult = Download-FileWithRetry -Url $researchTool.url -OutputPath $downloadPath
        
        if (-not $downloadResult.Success) {
            throw "Failed to download SPD Research Tool"
        }
        
        # Extract
        Write-Log "Extracting SPD Research Tool..." "INFO"
        Show-ProgressBar -Percent 50 -Status "Extracting..."
        
        $null = New-Item -ItemType Directory -Path $OutputPath -Force
        Expand-Archive -Path $downloadPath -DestinationPath $OutputPath -Force
        
        Write-Log "SPD Research Tool extracted to $OutputPath" "OK"
        Write-Log "Default password: SFT123" "INFO"
        Show-ProgressBar -Percent 100 -Status "Complete"
        
        return @{
            Success = $true
            Path = $OutputPath
            Password = "SFT123"
            Executable = (Get-ChildItem -Path $OutputPath -Filter "*.exe" -Recurse | Select-Object -First 1).FullName
        }
    }
    catch {
        Write-Log "SPD Research Tool download failed: $_" "ERROR"
        Show-Message "SPD Research Tool download failed: $_" "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

<#
.SYNOPSIS
    Starts SPD Flash Tool with guided instructions
#>
function Start-SPDFlash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FirmwarePath,
        
        [string]$ToolPath
    )
    
    try {
        Write-Log "Starting SPD Flash process..." "INFO"
        
        # Get SPD Flash Tool if not provided
        if (-not $ToolPath) {
            $toolResult = Get-SPDFlashTool
            if (-not $toolResult.Success) {
                throw "Failed to get SPD Flash Tool"
            }
            $ToolPath = $toolResult.Executable
        }
        
        # Verify firmware exists
        if (-not (Test-Path $FirmwarePath)) {
            throw "Firmware not found: $FirmwarePath"
        }
        
        # Launch SPD Flash Tool
        Write-Log "Launching SPD Flash Tool..." "INFO"
        Start-Process $ToolPath
        
        Start-Sleep -Seconds 3
        
        # Show guided instructions
        Show-SPDFlashInstructions -FirmwarePath $FirmwarePath
        
        # Wait for user confirmation
        $confirmation = Show-ConfirmDialog "Has the flashing completed successfully?"
        
        if ($confirmation) {
            Write-Log "SPD Flash completed successfully" "OK"
            Show-Message "Firmware flashed successfully!" "OK"
            return @{ Success = $true }
        }
        else {
            Write-Log "SPD Flash reported as unsuccessful" "WARN"
            return @{ Success = $false; Error = "User reported flash failure" }
        }
    }
    catch {
        Write-Log "SPD Flash failed: $_" "ERROR"
        Show-Message "SPD Flash failed: $_" "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

<#
.SYNOPSIS
    Shows guided instructions for SPD Flash Tool
#>
function Show-SPDFlashInstructions {
    [CmdletBinding()]
    param(
        [string]$FirmwarePath
    )
    
    try {
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SPD Flash Tool - Step-by-Step Guide                  ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        
        $steps = @(
            "Click 'Load Packet' and select: $FirmwarePath",
            "Power off your device completely",
            "Hold Volume Down button",
            "Connect USB cable while holding Volume Down",
            "Wait for the device to be detected (COM port appears)",
            "Flash will start automatically",
            "Wait for 'Passed' message (green)",
            "Disconnect USB cable",
            "Power on your device"
        )
        
        Write-Host "`nFollow these steps carefully:`n" -ForegroundColor Yellow
        
        $stepNumber = 1
        foreach ($step in $steps) {
            Write-Host "  $stepNumber. " -NoNewline -ForegroundColor Magenta
            Write-Host $step -ForegroundColor White
            $stepNumber++
        }
        
        Write-Host "`n⚠️  IMPORTANT WARNINGS:" -ForegroundColor Red
        Write-Host "  • Do NOT disconnect during flashing" -ForegroundColor Yellow
        Write-Host "  • Ensure battery is charged (>50%)" -ForegroundColor Yellow
        Write-Host "  • Use original USB cable if possible" -ForegroundColor Yellow
        Write-Host "  • Wait for 'Passed' confirmation" -ForegroundColor Yellow
        
        Write-Host "`n"
    }
    catch {
        Write-Log "Failed to show SPD instructions: $_" "ERROR"
    }
}

<#
.SYNOPSIS
    Tests if SPD drivers are installed
#>
function Test-SPDDriversInstalled {
    [CmdletBinding()]
    param()
    
    try {
        # Check for Spreadtrum/Unisoc drivers
        $drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object {
            $_.DeviceName -match "Spreadtrum|Unisoc|SPD"
        }
        
        if ($drivers) {
            Write-Log "SPD drivers detected: $($drivers.Count) device(s)" "OK"
            return $true
        }
        
        Write-Log "SPD drivers not detected" "WARN"
        return $false
    }
    catch {
        Write-Log "SPD driver detection failed: $_" "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Displays SPD tool information
#>
function Show-SPDToolInfo {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          SPD Flash Tool Information                           ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        
        Write-Host "`nSPD Flash Tool R27.24.2301" -ForegroundColor Yellow
        Write-Host "  Purpose: Flash firmware to Unisoc/Spreadtrum devices" -ForegroundColor Gray
        Write-Host "  Device: Realme C63 (RMX3939)" -ForegroundColor Gray
        Write-Host "  Chipset: Unisoc/Spreadtrum" -ForegroundColor Gray
        
        Write-Host "`nSPD Research Tool R4.0.0001" -ForegroundColor Yellow
        Write-Host "  Purpose: Advanced diagnostics and development" -ForegroundColor Gray
        Write-Host "  Default Password: SFT123" -ForegroundColor Gray
        
        Write-Host "`nDriver Status:" -ForegroundColor Yellow
        if (Test-SPDDriversInstalled) {
            Write-Host "  ✓ SPD Drivers Installed" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ SPD Drivers Not Detected" -ForegroundColor Red
            Write-Host "  → Install drivers using Driver-Manager module" -ForegroundColor Cyan
        }
        
        Write-Host "`nDownload Links:" -ForegroundColor Yellow
        Write-Host "  SPD Flash Tool: https://spdflashtool.com/download/spd-flash-tool-r27-24-2301" -ForegroundColor Gray
        Write-Host "  SPD Research Tool: https://spdflashtool.com/research-tool/spd-research-tool-r4-0-0001" -ForegroundColor Gray
        Write-Host "  SPD Drivers: https://tech-latest.com/download-latest-spd-drivers-spreadtrum-windows/" -ForegroundColor Gray
        
        Write-Host "`nGuides:" -ForegroundColor Yellow
        Write-Host "  • https://www.passfab.com/android/spd-flash-tool.html" -ForegroundColor Gray
        Write-Host "  • https://www.gizdev.com/latest-spd-research-tool-and-spd-upgrade-tool/" -ForegroundColor Gray
        
        Write-Host "`n"
    }
    catch {
        Write-Log "Failed to show SPD tool info: $_" "ERROR"
    }
}

<#
.SYNOPSIS
    Prepares device for SPD flashing
#>
function Initialize-SPDFlash {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Preparing for SPD Flash..." "INFO"
        Show-Message "Preparing SPD Flash environment..." "INFO"
        
        # Check for SPD drivers
        if (-not (Test-SPDDriversInstalled)) {
            Show-Message "⚠️  SPD drivers not detected!" "WARN"
            $installDrivers = Show-ConfirmDialog "Install SPD drivers now?"
            
            if ($installDrivers) {
                # Import Driver-Manager and install
                Import-Module "$PSScriptRoot\Driver-Manager.psm1" -Force
                $driverResult = Install-SPDDrivers
                
                if (-not $driverResult.Success) {
                    throw "Failed to install SPD drivers"
                }
            }
            else {
                Write-Log "User skipped driver installation" "WARN"
            }
        }
        
        # Download SPD Flash Tool
        $toolResult = Get-SPDFlashTool
        
        if (-not $toolResult.Success) {
            throw "Failed to get SPD Flash Tool"
        }
        
        Write-Log "SPD Flash preparation complete" "OK"
        Show-Message "SPD Flash ready!" "OK"
        
        return @{
            Success = $true
            ToolPath = $toolResult.Executable
        }
    }
    catch {
        Write-Log "SPD Flash preparation failed: $_" "ERROR"
        Show-Message "SPD Flash preparation failed: $_" "ERROR"
        return @{ Success = $false; Error = $_.ToString() }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Get-SPDFlashTool',
    'Get-SPDResearchTool',
    'Start-SPDFlash',
    'Show-SPDFlashInstructions',
    'Test-SPDDriversInstalled',
    'Show-SPDToolInfo',
    'Initialize-SPDFlash'
)
