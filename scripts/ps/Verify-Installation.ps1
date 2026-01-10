<#
.SYNOPSIS
    Post-installation verification for Realme C63 setup
    
.DESCRIPTION
    Performs comprehensive verification of device status, installed components,
    and generates a detailed health report
    
.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0
    
.EXAMPLE
    .\Verify-Installation.ps1
    .\Verify-Installation.ps1 -GenerateReport
#>

[CmdletBinding()]
param(
    [switch]$GenerateReport,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Import required modules
$modulesPath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulesPath "Device-Manager.psm1") -Force
Import-Module (Join-Path $modulesPath "Driver-Manager.psm1") -Force
Import-Module (Join-Path $modulesPath "Root-Manager.psm1") -Force
Import-Module (Join-Path $modulesPath "Bootloader-Unlock.psm1") -Force
Import-Module (Join-Path $modulesPath "Logger.psm1") -Force
Import-Module (Join-Path $modulesPath "UI-Helper.psm1") -Force

function Write-VerificationResult {
    param(
        [string]$Test,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $status = if ($Passed) { "✓ PASS" } else { "✗ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "[$status]" -ForegroundColor $color -NoNewline
    Write-Host " $Test" -NoNewline
    if ($Details) {
        Write-Host " - $Details" -ForegroundColor Gray
    } else {
        Write-Host ""
    }
}

Write-ColoredMessage "═══ Realme C63 Installation Verification ═══" "Cyan"
Write-Host ""

$results = @{}
$totalTests = 0
$passedTests = 0

# Test 1: ADB Connectivity
Write-ColoredMessage "`n[Test 1/7] ADB Connectivity" "Yellow"
$totalTests++
try {
    $adbAvailable = Test-ADBAvailable
    $results["ADB"] = $adbAvailable
    if ($adbAvailable) { $passedTests++ }
    Write-VerificationResult "ADB available and functional" $adbAvailable
} catch {
    Write-VerificationResult "ADB connectivity" $false "Error: $_"
}

# Test 2: Device Connection
Write-ColoredMessage "`n[Test 2/7] Device Connection" "Yellow"
$totalTests++
try {
    $deviceConnected = Test-DeviceConnected
    $results["Device"] = $deviceConnected
    if ($deviceConnected) {
        $passedTests++
        $deviceInfo = Get-DeviceInfo
        Write-VerificationResult "Device connected" $true "Model: $($deviceInfo.Model)"
    } else {
        Write-VerificationResult "Device connected" $false "No device found"
    }
} catch {
    Write-VerificationResult "Device connection" $false "Error: $_"
}

# Test 3: Bootloader Status
Write-ColoredMessage "`n[Test 3/7] Bootloader Status" "Yellow"
$totalTests++
try {
    $bootloaderUnlocked = Test-BootloaderUnlocked
    $results["Bootloader"] = $bootloaderUnlocked
    if ($bootloaderUnlocked) { $passedTests++ }
    $status = if ($bootloaderUnlocked) { "Unlocked" } else { "Locked" }
    Write-VerificationResult "Bootloader status" $true "Status: $status"
} catch {
    Write-VerificationResult "Bootloader check" $false "Error: $_"
}

# Test 4: Root Access
Write-ColoredMessage "`n[Test 4/7] Root Access" "Yellow"
$totalTests++
try {
    $rootInstalled = Test-MagiskInstalled
    $results["Root"] = $rootInstalled
    if ($rootInstalled) { $passedTests++ }
    $status = if ($rootInstalled) { "Installed" } else { "Not installed" }
    Write-VerificationResult "Root access (Magisk)" $rootInstalled "Status: $status"
} catch {
    Write-VerificationResult "Root check" $false "Error: $_"
}

# Test 5: Drivers
Write-ColoredMessage "`n[Test 5/7] USB Drivers" "Yellow"
$totalTests++
try {
    $driversInstalled = Test-DriversInstalled
    $results["Drivers"] = $driversInstalled
    if ($driversInstalled) { $passedTests++ }
    Write-VerificationResult "USB drivers installed" $driversInstalled
} catch {
    Write-VerificationResult "Driver check" $false "Error: $_"
}

# Test 6: Fastboot
Write-ColoredMessage "`n[Test 6/7] Fastboot Mode" "Yellow"
$totalTests++
try {
    $fastbootAvailable = Test-FastbootAvailable
    $results["Fastboot"] = $fastbootAvailable
    if ($fastbootAvailable) { $passedTests++ }
    Write-VerificationResult "Fastboot available" $fastbootAvailable
} catch {
    Write-VerificationResult "Fastboot check" $false "Error: $_"
}

# Test 7: Storage Access
Write-ColoredMessage "`n[Test 7/7] Storage Access" "Yellow"
$totalTests++
try {
    # Test if we can access device storage
    $storageTest = & adb shell "ls /sdcard" 2>&1
    $storageAccessible = $LASTEXITCODE -eq 0
    $results["Storage"] = $storageAccessible
    if ($storageAccessible) { $passedTests++ }
    Write-VerificationResult "Device storage accessible" $storageAccessible
} catch {
    Write-VerificationResult "Storage access" $false "Error: $_"
}

# Calculate health score
$healthScore = [math]::Round(($passedTests / $totalTests) * 100)

# Display summary
Write-ColoredMessage "`n═══ Verification Summary ═══" "Cyan"
Write-Host "Tests Passed: $passedTests / $totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "Health Score: $healthScore%" -ForegroundColor $(
    if ($healthScore -ge 90) { "Green" }
    elseif ($healthScore -ge 70) { "Yellow" }
    else { "Red" }
)

# Generate HTML report if requested
if ($GenerateReport) {
    $reportPath = Join-Path $PSScriptRoot "..\..\work\reports\verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    $reportDir = Split-Path $reportPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    # Simple HTML report
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Realme C63 Verification Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .pass { color: green; }
        .fail { color: red; }
        .score { font-size: 24px; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Realme C63 Installation Verification Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <h2>Results</h2>
    <ul>
$(foreach ($key in $results.Keys) {
    $class = if ($results[$key]) { "pass" } else { "fail" }
    $status = if ($results[$key]) { "PASS" } else { "FAIL" }
    "        <li class='$class'>$key: $status</li>`n"
})
    </ul>
    <h2>Health Score</h2>
    <p class='score'>$healthScore%</p>
    <p>Tests Passed: $passedTests / $totalTests</p>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColoredMessage "`nReport saved: $reportPath" "Green"
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
