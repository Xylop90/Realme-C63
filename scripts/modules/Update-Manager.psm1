<#
.SYNOPSIS
    Update Manager Module for Realme C63 Installer
.DESCRIPTION
    Handles automatic updates for all tools and system components
    using GitHub Releases API and web scraping.
.NOTES
    Part of Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Copyright © 2026
#>

# Import required modules
Import-Module "$PSScriptRoot\Logger.psm1" -Force
Import-Module "$PSScriptRoot\Download-Manager.psm1" -Force
Import-Module "$PSScriptRoot\UI-Helper.psm1" -Force

# Load configuration
$toolVersions = Get-Content "$PSScriptRoot\..\..\config\tool-versions.json" | ConvertFrom-Json

<#
.SYNOPSIS
    Gets latest version from GitHub releases
.DESCRIPTION
    Queries GitHub API for the latest release of a repository
.PARAMETER Repository
    GitHub repository in format "owner/repo"
.OUTPUTS
    Latest version information
#>
function Get-GitHubLatestRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository
    )
    
    try {
        $apiUrl = "https://api.github.com/repos/$Repository/releases/latest"
        Write-LogMessage "Checking GitHub for latest release: $Repository" "INFO"
        
        $headers = @{
            "User-Agent" = "Realme-C63-Installer"
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 10
        
        return [PSCustomObject]@{
            Version = $response.tag_name
            Name = $response.name
            PublishedAt = $response.published_at
            DownloadUrl = $response.assets[0].browser_download_url
            Assets = $response.assets
        }
    }
    catch {
        Write-LogMessage "Error checking GitHub release: $_" "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Compares version strings
.DESCRIPTION
    Compares two version strings to determine if update is available
.PARAMETER CurrentVersion
    Current installed version
.PARAMETER LatestVersion
    Latest available version
.OUTPUTS
    $true if update is available
#>
function Test-UpdateAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,
        
        [Parameter(Mandatory = $true)]
        [string]$LatestVersion
    )
    
    try {
        # Remove 'v' prefix if present
        $current = $CurrentVersion -replace '^v', ''
        $latest = $LatestVersion -replace '^v', ''
        
        # Try to parse as version objects
        try {
            $currentVer = [version]$current
            $latestVer = [version]$latest
            return $latestVer -gt $currentVer
        }
        catch {
            # Fallback to string comparison
            return $latest -ne $current
        }
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Checks for Magisk updates
.DESCRIPTION
    Checks if a newer version of Magisk is available
.OUTPUTS
    Update information object
#>
function Test-MagiskUpdate {
    [CmdletBinding()]
    param()
    
    try {
        $magiskTool = $toolVersions.tools | Where-Object { $_.name -eq "magisk" }
        $currentVersion = $magiskTool.version
        
        Write-LogMessage "Checking for Magisk updates (current: $currentVersion)..." "INFO"
        
        $latest = Get-GitHubLatestRelease -Repository "topjohnwu/Magisk"
        
        if ($latest) {
            $updateAvailable = Test-UpdateAvailable -CurrentVersion $currentVersion -LatestVersion $latest.Version
            
            return [PSCustomObject]@{
                Tool = "Magisk"
                CurrentVersion = $currentVersion
                LatestVersion = $latest.Version
                UpdateAvailable = $updateAvailable
                DownloadUrl = $latest.DownloadUrl
                PublishedAt = $latest.PublishedAt
            }
        }
        
        return $null
    }
    catch {
        Write-LogMessage "Error checking Magisk update: $_" "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Checks for ADB Platform Tools updates
.DESCRIPTION
    Checks if a newer version of Android Platform Tools is available
.OUTPUTS
    Update information object
#>
function Test-ADBUpdate {
    [CmdletBinding()]
    param()
    
    try {
        $adbTool = $toolVersions.tools | Where-Object { $_.name -eq "adb_platform_tools" }
        $currentVersion = $adbTool.version
        
        Write-LogMessage "Checking for ADB Platform Tools updates (current: $currentVersion)..." "INFO"
        
        # ADB doesn't have a public API, return manual check info
        return [PSCustomObject]@{
            Tool = "ADB Platform Tools"
            CurrentVersion = $currentVersion
            LatestVersion = "Check manually"
            UpdateAvailable = $false
            DownloadUrl = "https://developer.android.com/tools/releases/platform-tools"
            Note = "Check https://developer.android.com/tools/releases/platform-tools for updates"
        }
    }
    catch {
        Write-LogMessage "Error checking ADB update: $_" "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Checks for Python updates
.DESCRIPTION
    Checks if a newer version of Python Embedded is available
.OUTPUTS
    Update information object
#>
function Test-PythonUpdate {
    [CmdletBinding()]
    param()
    
    try {
        $pythonTool = $toolVersions.tools | Where-Object { $_.name -eq "python_embedded" }
        $currentVersion = $pythonTool.version
        
        Write-LogMessage "Checking for Python updates (current: $currentVersion)..." "INFO"
        
        # Python.org doesn't have easy API, return manual check
        return [PSCustomObject]@{
            Tool = "Python Embedded"
            CurrentVersion = $currentVersion
            LatestVersion = "Check manually"
            UpdateAvailable = $false
            DownloadUrl = "https://www.python.org/downloads/"
            Note = "Check https://www.python.org/downloads/ for Python 3.11 updates"
        }
    }
    catch {
        Write-LogMessage "Error checking Python update: $_" "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Checks for all tool updates
.DESCRIPTION
    Checks for updates for all configured tools
.OUTPUTS
    Array of update information objects
#>
function Test-AllUpdates {
    [CmdletBinding()]
    param()
    
    try {
        Write-ColoredMessage "`n=== Checking for Updates ===" "Cyan"
        
        $updates = @()
        
        # Check Magisk
        $magiskUpdate = Test-MagiskUpdate
        if ($magiskUpdate) { $updates += $magiskUpdate }
        
        # Check ADB
        $adbUpdate = Test-ADBUpdate
        if ($adbUpdate) { $updates += $adbUpdate }
        
        # Check Python
        $pythonUpdate = Test-PythonUpdate
        if ($pythonUpdate) { $updates += $pythonUpdate }
        
        return $updates
    }
    catch {
        Write-LogMessage "Error checking updates: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Shows update information
.DESCRIPTION
    Displays available updates in a formatted table
.PARAMETER Updates
    Array of update information objects
#>
function Show-UpdateInformation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Updates
    )
    
    try {
        Write-ColoredMessage "`n=== Update Status ===" "Cyan"
        
        if ($Updates.Count -eq 0) {
            Write-ColoredMessage "No update information available" "Yellow"
            return
        }
        
        $hasUpdates = $false
        
        foreach ($update in $Updates) {
            Write-Host "`n$($update.Tool):" -ForegroundColor White
            Write-Host "  Current: " -NoNewline
            Write-Host $update.CurrentVersion -ForegroundColor Yellow
            Write-Host "  Latest:  " -NoNewline
            Write-Host $update.LatestVersion -ForegroundColor $(if ($update.UpdateAvailable) { "Green" } else { "Yellow" })
            
            if ($update.UpdateAvailable) {
                Write-ColoredMessage "  ⬆ Update Available!" "Green"
                Write-Host "  Download: " -NoNewline
                Write-Host $update.DownloadUrl -ForegroundColor Cyan
                $hasUpdates = $true
            }
            elseif ($update.Note) {
                Write-ColoredMessage "  ℹ $($update.Note)" "Cyan"
            }
            else {
                Write-ColoredMessage "  ✓ Up to date" "Green"
            }
        }
        
        if ($hasUpdates) {
            Write-Host ""
            Write-ColoredMessage "Updates are available! Consider updating to the latest versions." "Yellow"
        } else {
            Write-Host ""
            Write-ColoredMessage "All tools are up to date." "Green"
        }
    }
    catch {
        Write-LogMessage "Error showing update information: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Downloads and installs tool update
.DESCRIPTION
    Downloads and installs an update for a specific tool
.PARAMETER ToolName
    Name of the tool to update
.PARAMETER DownloadUrl
    URL to download the update
#>
function Install-ToolUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$DownloadUrl
    )
    
    try {
        Write-ColoredMessage "Updating $ToolName..." "Yellow"
        
        $tempPath = "$PSScriptRoot\..\..\work\downloads\$ToolName-update"
        if (-not (Test-Path $tempPath)) {
            New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
        }
        
        $filename = [System.IO.Path]::GetFileName($DownloadUrl)
        $downloadPath = Join-Path $tempPath $filename
        
        # Download update
        $downloaded = Get-FileWithResume -Url $DownloadUrl -OutputPath $downloadPath
        
        if ($downloaded) {
            Write-ColoredMessage "Update downloaded successfully" "Green"
            Write-ColoredMessage "Location: $downloadPath" "Cyan"
            Write-ColoredMessage "Please install manually if automatic installation is not available" "Yellow"
            return $true
        }
        
        return $false
    }
    catch {
        Write-LogMessage "Error installing update: $_" "ERROR"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-GitHubLatestRelease',
    'Test-UpdateAvailable',
    'Test-MagiskUpdate',
    'Test-ADBUpdate',
    'Test-PythonUpdate',
    'Test-AllUpdates',
    'Show-UpdateInformation',
    'Install-ToolUpdate'
)
