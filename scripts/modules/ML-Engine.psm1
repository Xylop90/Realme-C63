<#
.SYNOPSIS
    ML Engine - AI-powered Decision Making for Installation Automation

.DESCRIPTION
    Provides intelligent decision-making capabilities using heuristics and
    pattern recognition for optimal installation paths and troubleshooting.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

#Requires -Version 5.1

# Import required modules
Import-Module "$PSScriptRoot\Logger.psm1" -Force
Import-Module "$PSScriptRoot\UI-Helper.psm1" -Force

<#
.SYNOPSIS
    Analyzes device and recommends optimal unlock method
#>
function Get-OptimalUnlockMethod {
    [CmdletBinding()]
    param(
        [hashtable]$DeviceInfo,
        [array]$AvailableMethods
    )
    
    try {
        Write-Log "Analyzing device for optimal unlock method..." "INFO"
        
        # Load bootloader methods config
        $config = Get-Content "config\bootloader-methods.json" | ConvertFrom-Json
        
        # Scoring system for method selection
        $scores = @{}
        
        foreach ($method in $config.methods) {
            $score = 0
            
            # Base score from success rate
            $score += $method.successRate
            
            # Bonus for device-specific compatibility
            if ($DeviceInfo.Model -match "RMX3939" -and $method.name -eq "unisoc-unlock") {
                $score += 20  # Highly recommended for RMX3939
            }
            
            # Penalty for requirements not met
            if ($method.requirements.fastbootMode -and -not $DeviceInfo.InFastboot) {
                $score -= 10
            }
            
            # Bonus for fewer steps
            $score -= ($method.steps.Count * 0.5)
            
            $scores[$method.name] = @{
                Method = $method
                Score = $score
            }
        }
        
        # Get best method
        $bestMethod = ($scores.GetEnumerator() | Sort-Object { $_.Value.Score } -Descending | Select-Object -First 1).Value.Method
        
        Write-Log "Recommended method: $($bestMethod.name) (score: $($scores[$bestMethod.name].Score))" "INFO"
        
        return @{
            RecommendedMethod = $bestMethod
            AllScores = $scores
            Confidence = [math]::Min(100, $scores[$bestMethod.name].Score)
        }
    }
    catch {
        Write-Log "Failed to determine optimal unlock method: $_" "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Predicts installation success probability
#>
function Get-InstallationSuccessProbability {
    [CmdletBinding()]
    param(
        [hashtable]$DeviceInfo,
        [hashtable]$SystemInfo,
        [string]$Operation
    )
    
    try {
        Write-Log "Calculating success probability for $Operation..." "INFO"
        
        $probability = 100.0
        $factors = @()
        
        # Device connection quality
        if ($DeviceInfo.Connected) {
            $factors += "Device connected (+10%)"
            $probability += 10
        }
        else {
            $factors += "Device not connected (-30%)"
            $probability -= 30
        }
        
        # Bootloader status
        if ($Operation -eq "Root" -and $DeviceInfo.BootloaderUnlocked) {
            $factors += "Bootloader unlocked (+15%)"
            $probability += 15
        }
        elseif ($Operation -eq "Root" -and -not $DeviceInfo.BootloaderUnlocked) {
            $factors += "Bootloader locked (-40%)"
            $probability -= 40
        }
        
        # Administrator rights
        if ($SystemInfo.IsAdmin) {
            $factors += "Admin rights (+10%)"
            $probability += 10
        }
        else {
            $factors += "No admin rights (-15%)"
            $probability -= 15
        }
        
        # ADB/Fastboot availability
        if ($SystemInfo.ADBAvailable) {
            $factors += "ADB available (+5%)"
            $probability += 5
        }
        
        # Battery level (if available)
        if ($DeviceInfo.BatteryLevel -and $DeviceInfo.BatteryLevel -lt 30) {
            $factors += "Low battery (-10%)"
            $probability -= 10
        }
        elseif ($DeviceInfo.BatteryLevel -and $DeviceInfo.BatteryLevel -gt 50) {
            $factors += "Good battery (+5%)"
            $probability += 5
        }
        
        # Clamp probability
        $probability = [math]::Max(0, [math]::Min(100, $probability))
        
        Write-Log "Success probability: $probability%" "INFO"
        
        return @{
            Probability = $probability
            Factors = $factors
            Recommendation = if ($probability -ge 70) { "Proceed" } elseif ($probability -ge 40) { "Proceed with caution" } else { "Not recommended" }
        }
    }
    catch {
        Write-Log "Failed to calculate success probability: $_" "ERROR"
        return @{ Probability = 50; Factors = @("Unable to calculate"); Recommendation = "Unknown" }
    }
}

<#
.SYNOPSIS
    Analyzes errors and suggests solutions
#>
function Get-ErrorSolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [string]$Operation
    )
    
    try {
        Write-Log "Analyzing error: $ErrorMessage" "INFO"
        
        # Error pattern matching
        $solutions = @()
        
        # Device not found errors
        if ($ErrorMessage -match "device not found|no devices|cannot connect") {
            $solutions += "1. Ensure device is connected via USB"
            $solutions += "2. Enable USB Debugging in Developer Options"
            $solutions += "3. Try a different USB cable or port"
            $solutions += "4. Install/reinstall USB drivers"
            $solutions += "5. Restart ADB server: adb kill-server && adb start-server"
        }
        
        # Bootloader locked errors
        if ($ErrorMessage -match "bootloader.*locked|FAILED.*locked") {
            $solutions += "1. Unlock bootloader first"
            $solutions += "2. Use bootloader unlock methods: unisoc-unlock, CVE, or DeepTesting"
            $solutions += "3. Check if OEM unlocking is enabled in Developer Options"
        }
        
        # Permission errors
        if ($ErrorMessage -match "permission denied|access denied|administrator") {
            $solutions += "1. Run PowerShell as Administrator"
            $solutions += "2. Check file permissions"
            $solutions += "3. Disable antivirus temporarily"
        }
        
        # Python/unisoc-unlock errors
        if ($ErrorMessage -match "python|unisoc|module not found") {
            $solutions += "1. Ensure Python is installed correctly"
            $solutions += "2. Reinstall unisoc-unlock: pip install unisoc-unlock"
            $solutions += "3. Check Python PATH configuration"
        }
        
        # Firmware/file errors
        if ($ErrorMessage -match "file not found|cannot open|invalid") {
            $solutions += "1. Verify firmware file path"
            $solutions += "2. Re-download firmware if corrupted"
            $solutions += "3. Check file integrity (SHA256)"
            $solutions += "4. Ensure sufficient disk space"
        }
        
        # Driver errors
        if ($ErrorMessage -match "driver|COM port|device not recognized") {
            $solutions += "1. Install SPD/Unisoc drivers"
            $solutions += "2. Install Realme USB drivers"
            $solutions += "3. Restart computer after driver installation"
            $solutions += "4. Try different USB port (USB 2.0 recommended)"
        }
        
        # Generic fallback
        if ($solutions.Count -eq 0) {
            $solutions += "1. Check log files for detailed error information"
            $solutions += "2. Restart device and try again"
            $solutions += "3. Ensure all prerequisites are met"
            $solutions += "4. Consult online documentation and forums"
        }
        
        return @{
            ErrorType = $Operation
            Solutions = $solutions
            Confidence = if ($solutions.Count -gt 1) { "High" } else { "Medium" }
        }
    }
    catch {
        Write-Log "Error analysis failed: $_" "ERROR"
        return @{ ErrorType = "Unknown"; Solutions = @("Unable to analyze error"); Confidence = "Low" }
    }
}

<#
.SYNOPSIS
    Recommends next action based on current state
#>
function Get-NextActionRecommendation {
    [CmdletBinding()]
    param(
        [hashtable]$CurrentState
    )
    
    try {
        Write-Log "Determining next recommended action..." "INFO"
        
        $recommendations = @()
        
        # Check bootloader status
        if (-not $CurrentState.BootloaderUnlocked) {
            $recommendations += @{
                Action = "Unlock Bootloader"
                Priority = "High"
                Reason = "Required for root access and custom recovery"
                Command = "Unlock-Bootloader"
            }
        }
        
        # Check root status
        if ($CurrentState.BootloaderUnlocked -and -not $CurrentState.Rooted) {
            $recommendations += @{
                Action = "Install Magisk Root"
                Priority = "Medium"
                Reason = "Gain root access for advanced features"
                Command = "Install-MagiskRoot"
            }
        }
        
        # Check drivers
        if (-not $CurrentState.DriversInstalled) {
            $recommendations += @{
                Action = "Install Drivers"
                Priority = "High"
                Reason = "Required for device communication"
                Command = "Install-SPDDrivers; Install-RealmeDrivers"
            }
        }
        
        # Check for updates
        if ($CurrentState.UpdatesAvailable) {
            $recommendations += @{
                Action = "Update Tools"
                Priority = "Low"
                Reason = "Newer versions available"
                Command = "Check-MagiskUpdate; Check-ADBUpdate"
            }
        }
        
        # Sort by priority
        $priorityOrder = @{ "High" = 1; "Medium" = 2; "Low" = 3 }
        $recommendations = $recommendations | Sort-Object { $priorityOrder[$_.Priority] }
        
        if ($recommendations.Count -eq 0) {
            $recommendations += @{
                Action = "System Ready"
                Priority = "Info"
                Reason = "All components configured"
                Command = $null
            }
        }
        
        Write-Log "Next recommended action: $($recommendations[0].Action)" "INFO"
        
        return $recommendations
    }
    catch {
        Write-Log "Failed to determine next action: $_" "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Analyzes system health and provides report
#>
function Get-SystemHealthReport {
    [CmdletBinding()]
    param(
        [hashtable]$SystemInfo,
        [hashtable]$DeviceInfo
    )
    
    try {
        Write-Log "Generating system health report..." "INFO"
        
        $healthScore = 100
        $issues = @()
        $recommendations = @()
        
        # Check prerequisites
        if (-not $SystemInfo.IsAdmin) {
            $healthScore -= 15
            $issues += "Not running as Administrator"
            $recommendations += "Run PowerShell as Administrator for full functionality"
        }
        
        if (-not $SystemInfo.ADBAvailable) {
            $healthScore -= 20
            $issues += "ADB not available"
            $recommendations += "Install Android Platform Tools"
        }
        
        if (-not $DeviceInfo.Connected) {
            $healthScore -= 25
            $issues += "Device not connected"
            $recommendations += "Connect device via USB and enable USB Debugging"
        }
        
        # Clamp score
        $healthScore = [math]::Max(0, $healthScore)
        
        # Determine health status
        $status = if ($healthScore -ge 80) { "Excellent" }
        elseif ($healthScore -ge 60) { "Good" }
        elseif ($healthScore -ge 40) { "Fair" }
        else { "Poor" }
        
        return @{
            HealthScore = $healthScore
            Status = $status
            Issues = $issues
            Recommendations = $recommendations
        }
    }
    catch {
        Write-Log "Failed to generate health report: $_" "ERROR"
        return @{ HealthScore = 0; Status = "Unknown"; Issues = @("Report generation failed"); Recommendations = @() }
    }
}

<#
.SYNOPSIS
    Displays AI recommendation report
#>
function Show-AIRecommendations {
    [CmdletBinding()]
    param(
        [hashtable]$DeviceInfo,
        [hashtable]$SystemInfo
    )
    
    try {
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          AI-Powered Recommendations                           ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        
        # System health
        $health = Get-SystemHealthReport -SystemInfo $SystemInfo -DeviceInfo $DeviceInfo
        
        Write-Host "`nSystem Health: " -NoNewline -ForegroundColor Yellow
        $color = switch ($health.Status) {
            "Excellent" { "Green" }
            "Good" { "Cyan" }
            "Fair" { "Yellow" }
            default { "Red" }
        }
        Write-Host "$($health.Status) ($($health.HealthScore)%)" -ForegroundColor $color
        
        if ($health.Issues.Count -gt 0) {
            Write-Host "`nIssues Detected:" -ForegroundColor Yellow
            foreach ($issue in $health.Issues) {
                Write-Host "  ✗ $issue" -ForegroundColor Red
            }
        }
        
        if ($health.Recommendations.Count -gt 0) {
            Write-Host "`nRecommendations:" -ForegroundColor Yellow
            $i = 1
            foreach ($rec in $health.Recommendations) {
                Write-Host "  $i. $rec" -ForegroundColor Cyan
                $i++
            }
        }
        
        # Next actions
        $currentState = @{
            BootloaderUnlocked = $DeviceInfo.BootloaderUnlocked
            Rooted = $DeviceInfo.Rooted
            DriversInstalled = $SystemInfo.DriversInstalled
            UpdatesAvailable = $false
        }
        
        $nextActions = Get-NextActionRecommendation -CurrentState $currentState
        
        if ($nextActions.Count -gt 0) {
            Write-Host "`nSuggested Next Steps:" -ForegroundColor Yellow
            foreach ($action in $nextActions) {
                $priorityColor = switch ($action.Priority) {
                    "High" { "Red" }
                    "Medium" { "Yellow" }
                    default { "Gray" }
                }
                Write-Host "  [$($action.Priority)] " -NoNewline -ForegroundColor $priorityColor
                Write-Host "$($action.Action)" -ForegroundColor White
                Write-Host "     → $($action.Reason)" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n"
    }
    catch {
        Write-Log "Failed to show AI recommendations: $_" "ERROR"
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Get-OptimalUnlockMethod',
    'Get-InstallationSuccessProbability',
    'Get-ErrorSolution',
    'Get-NextActionRecommendation',
    'Get-SystemHealthReport',
    'Show-AIRecommendations'
)
