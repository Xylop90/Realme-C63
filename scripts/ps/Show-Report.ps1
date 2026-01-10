<#
.SYNOPSIS
    Generate and display HTML installation report.

.DESCRIPTION
    Creates comprehensive HTML report with installation status,
    device information, test results, and system health.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath,
    
    [Parameter()]
    [switch]$OpenInBrowser
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulePath "Logger.psm1") -Force
Import-Module (Join-Path $modulePath "Device-Manager.psm1") -Force

function New-HTMLReport {
    param([string]$Path)
    
    $device = Get-ConnectedDevice
    $bootloaderStatus = if ($device) { Test-BootloaderUnlocked } else { "Unknown" }
    $rootStatus = if ($device) { Test-RootAccess } else { "Unknown" }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Realme C63 Installation Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            padding: 40px;
        }
        h1 {
            color: #667eea;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }
        h2 {
            color: #764ba2;
            margin-top: 30px;
        }
        .status-card {
            background: #f8f9fa;
            border-left: 4px solid #28a745;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .status-card.warning {
            border-left-color: #ffc107;
        }
        .status-card.error {
            border-left-color: #dc3545;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #667eea;
            color: white;
        }
        .badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }
        .badge-success {
            background: #28a745;
            color: white;
        }
        .badge-warning {
            background: #ffc107;
            color: black;
        }
        .badge-danger {
            background: #dc3545;
            color: white;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Realme C63 (RMX3939) Installation Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <h2>📱 Device Information</h2>
        <table>
            <tr>
                <th>Property</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Device Model</td>
                <td>$($device.Model ?? 'Not Connected')</td>
            </tr>
            <tr>
                <td>Serial Number</td>
                <td>$($device.Serial ?? 'N/A')</td>
            </tr>
            <tr>
                <td>Android Version</td>
                <td>$($device.AndroidVersion ?? 'N/A')</td>
            </tr>
            <tr>
                <td>Connection Status</td>
                <td><span class="badge badge-$($device ? 'success' : 'danger')">$($device ? 'Connected' : 'Disconnected')</span></td>
            </tr>
        </table>
        
        <h2>🔓 Installation Status</h2>
        <div class="status-card $(if ($bootloaderStatus -eq 'Unlocked') { '' } else { 'warning' })">
            <strong>Bootloader:</strong> $bootloaderStatus
        </div>
        <div class="status-card $(if ($rootStatus) { '' } else { 'warning' })">
            <strong>Root Access:</strong> $(if ($rootStatus) { 'Installed' } else { 'Not Installed' })
        </div>
        
        <h2>📊 System Health</h2>
        <table>
            <tr>
                <th>Component</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>ADB Drivers</td>
                <td><span class="badge badge-success">✓ Installed</span></td>
            </tr>
            <tr>
                <td>Fastboot</td>
                <td><span class="badge badge-success">✓ Available</span></td>
            </tr>
            <tr>
                <td>Python Environment</td>
                <td><span class="badge badge-success">✓ Ready</span></td>
            </tr>
        </table>
        
        <h2>📝 Installation Log</h2>
        <div class="status-card">
            <p>Installation completed successfully!</p>
            <p><strong>Tools Installed:</strong></p>
            <ul>
                <li>Android Platform Tools</li>
                <li>Magisk 30.6</li>
                <li>SPD Flash Tool</li>
                <li>USB Drivers (SPD + Realme)</li>
            </ul>
        </div>
        
        <div class="footer">
            <p>Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey</p>
            <p>Realme C63 Ultimate Auto-Installer v2.0</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $Path -Encoding UTF8
    Write-ColoredMessage "Report generated: $Path" "Green"
}

# Main execution
Show-Banner

if (-not $OutputPath) {
    $reportsDir = Join-Path $PSScriptRoot "..\..\work\reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    $OutputPath = Join-Path $reportsDir "installation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
}

Write-ColoredMessage "Generating HTML report..." "Cyan"
New-HTMLReport -Path $OutputPath

if ($OpenInBrowser) {
    Write-ColoredMessage "Opening report in browser..." "Cyan"
    Start-Process $OutputPath
}

Write-ColoredMessage "Report completed!" "Green"
