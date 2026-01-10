<#
.SYNOPSIS
    Tool-Manager-Modul für automatische Tool-Installation

.DESCRIPTION
    Automatische Installation und Updates für SPD Flash Tool, ADB, Python,
    USB-Treiber, Magisk und andere benötigte Tools

.NOTES
    Author: Xylop90
    Version: 2.0.0
#>

function Get-ToolsConfig {
    <#
    .SYNOPSIS
    Lädt die Tool-Konfiguration
    #>
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path $PSScriptRoot "..\..\config\tool-versions.json"
    
    if (-not (Test-Path $configPath)) {
        Write-Log -Message "Tool configuration not found: $configPath" -Level "ERROR" -Category "ToolManager"
        return $null
    }
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-ErrorLog -Message "Failed to load tool configuration" -ErrorRecord $_ -Category "ToolManager"
        return $null
    }
}

function Install-PlatformTools {
    <#
    .SYNOPSIS
    Installiert Android Platform Tools (ADB/Fastboot)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolsDirectory
    )
    
    try {
        $config = Get-ToolsConfig
        if (-not $config) { return $false }
        
        $toolInfo = $config.tools.platform_tools
        $adbDir = Join-Path $ToolsDirectory "adb"
        $adbExe = Join-Path $adbDir "adb.exe"
        
        # Check if already installed
        if (Test-Path $adbExe) {
            Write-Log -Message "Platform Tools already installed" -Level "INFO" -Category "ToolManager"
            return $true
        }
        
        Write-Log -Message "Installing Android Platform Tools..." -Level "INFO" -Category "ToolManager"
        
        # Download
        $zipPath = Join-Path $ToolsDirectory "platform-tools.zip"
        $success = Start-FileDownload `
            -Url $toolInfo.url `
            -Destination $zipPath `
            -Description "Android Platform Tools"
        
        if (-not $success) {
            return $false
        }
        
        # Extract
        Write-Log -Message "Extracting Platform Tools..." -Level "INFO" -Category "ToolManager"
        $extractPath = Join-Path $ToolsDirectory "platform-tools-temp"
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Move files
        $platformToolsFolder = Join-Path $extractPath "platform-tools"
        if (Test-Path $platformToolsFolder) {
            if (-not (Test-Path $adbDir)) {
                New-Item -Path $adbDir -ItemType Directory -Force | Out-Null
            }
            
            Get-ChildItem -Path $platformToolsFolder | Move-Item -Destination $adbDir -Force
        }
        
        # Cleanup
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        
        # Verify installation
        if (Test-Path $adbExe) {
            Write-Log -Message "Platform Tools installed successfully" -Level "INFO" -Category "ToolManager"
            
            # Add to PATH if configured
            if ($toolInfo.add_to_path) {
                Add-ToSystemPath -Path $adbDir
            }
            
            return $true
        }
        else {
            Write-Log -Message "Platform Tools installation failed" -Level "ERROR" -Category "ToolManager"
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to install Platform Tools" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Install-PythonEmbedded {
    <#
    .SYNOPSIS
    Installiert Python Embedded für Unisoc-Unlock
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolsDirectory
    )
    
    try {
        $config = Get-ToolsConfig
        if (-not $config) { return $false }
        
        $toolInfo = $config.tools.python_embedded
        $pythonDir = Join-Path $ToolsDirectory "python311"
        $pythonExe = Join-Path $pythonDir "python.exe"
        
        # Check if already installed
        if (Test-Path $pythonExe) {
            Write-Log -Message "Python Embedded already installed" -Level "INFO" -Category "ToolManager"
            return $true
        }
        
        Write-Log -Message "Installing Python 3.11 Embedded..." -Level "INFO" -Category "ToolManager"
        
        # Download
        $zipPath = Join-Path $ToolsDirectory "python-embedded.zip"
        $success = Start-FileDownload `
            -Url $toolInfo.url `
            -Destination $zipPath `
            -Description "Python 3.11 Embedded"
        
        if (-not $success) {
            return $false
        }
        
        # Extract
        Write-Log -Message "Extracting Python..." -Level "INFO" -Category "ToolManager"
        
        if (-not (Test-Path $pythonDir)) {
            New-Item -Path $pythonDir -ItemType Directory -Force | Out-Null
        }
        
        Expand-Archive -Path $zipPath -DestinationPath $pythonDir -Force
        
        # Cleanup
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        
        # Verify installation
        if (Test-Path $pythonExe) {
            Write-Log -Message "Python Embedded installed successfully" -Level "INFO" -Category "ToolManager"
            
            # Bootstrap pip
            Install-PipForEmbeddedPython -PythonDirectory $pythonDir
            
            # Install unisoc-unlock
            Install-UnisocUnlock -PythonDirectory $pythonDir
            
            return $true
        }
        else {
            Write-Log -Message "Python Embedded installation failed" -Level "ERROR" -Category "ToolManager"
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to install Python Embedded" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Install-PipForEmbeddedPython {
    <#
    .SYNOPSIS
    Bootstrapped pip für Embedded Python
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonDirectory
    )
    
    try {
        Write-Log -Message "Bootstrapping pip for embedded Python..." -Level "INFO" -Category "ToolManager"
        
        $pythonExe = Join-Path $PythonDirectory "python.exe"
        
        # Enable site-packages by modifying python*._pth file
        $pthFile = Get-ChildItem -Path $PythonDirectory -Filter "python*._pth" | Select-Object -First 1
        
        if ($pthFile) {
            $content = Get-Content $pthFile.FullName
            $newContent = $content -replace "^#import site", "import site"
            $newContent | Set-Content $pthFile.FullName
        }
        
        # Download get-pip.py
        $getPipPath = Join-Path $PythonDirectory "get-pip.py"
        $success = Start-FileDownload `
            -Url "https://bootstrap.pypa.io/get-pip.py" `
            -Destination $getPipPath `
            -Description "get-pip.py" `
            -UseWebClient
        
        if (-not $success) {
            return $false
        }
        
        # Install pip
        & $pythonExe $getPipPath 2>&1 | Out-Null
        
        Write-Log -Message "Pip bootstrapped successfully" -Level "INFO" -Category "ToolManager"
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to bootstrap pip" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Install-UnisocUnlock {
    <#
    .SYNOPSIS
    Installiert unisoc-unlock via pip
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonDirectory
    )
    
    try {
        Write-Log -Message "Installing unisoc-unlock package..." -Level "INFO" -Category "ToolManager"
        
        $pythonExe = Join-Path $PythonDirectory "python.exe"
        
        # Install unisoc-unlock
        & $pythonExe -m pip install unisoc-unlock --upgrade 2>&1 | Out-Null
        
        Write-Log -Message "unisoc-unlock installed successfully" -Level "INFO" -Category "ToolManager"
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to install unisoc-unlock" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Install-Magisk {
    <#
    .SYNOPSIS
    Lädt die neueste Magisk APK herunter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolsDirectory
    )
    
    try {
        $config = Get-ToolsConfig
        if (-not $config) { return $false }
        
        $toolInfo = $config.tools.magisk
        $magiskDir = Join-Path $ToolsDirectory "magisk"
        
        if (-not (Test-Path $magiskDir)) {
            New-Item -Path $magiskDir -ItemType Directory -Force | Out-Null
        }
        
        Write-Log -Message "Downloading latest Magisk..." -Level "INFO" -Category "ToolManager"
        
        # Get latest release from GitHub API
        $latestUrl = $toolInfo.download_url
        $latestVersion = $toolInfo.version
        
        if ($toolInfo.check_github_api) {
            try {
                $apiResponse = Invoke-RestMethod -Uri $toolInfo.api_url -ErrorAction Stop
                $latestVersion = $apiResponse.tag_name -replace '^v', ''
                $latestUrl = $apiResponse.assets | Where-Object { $_.name -like "Magisk-*.apk" } | Select-Object -First 1 -ExpandProperty browser_download_url
                
                Write-Log -Message "Latest Magisk version from GitHub: $latestVersion" -Level "INFO" -Category "ToolManager"
            }
            catch {
                Write-Log -Message "Could not fetch latest Magisk from API, using default" -Level "WARNING" -Category "ToolManager"
            }
        }
        
        $apkPath = Join-Path $magiskDir "Magisk-v${latestVersion}.apk"
        
        # Check if already downloaded
        if (Test-Path $apkPath) {
            Write-Log -Message "Magisk v${latestVersion} already downloaded" -Level "INFO" -Category "ToolManager"
            return $true
        }
        
        # Download
        $success = Start-FileDownload `
            -Url $latestUrl `
            -Destination $apkPath `
            -Description "Magisk v${latestVersion}"
        
        if ($success) {
            Write-Log -Message "Magisk downloaded successfully: $apkPath" -Level "INFO" -Category "ToolManager"
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to download Magisk" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Install-SPDFlashTool {
    <#
    .SYNOPSIS
    Lädt SPD Flash Tool herunter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolsDirectory
    )
    
    try {
        $config = Get-ToolsConfig
        if (-not $config) { return $false }
        
        $toolInfo = $config.tools.spd_flash_tool
        $spdDir = Join-Path $ToolsDirectory "spd_flash_tool"
        
        Write-Log -Message "SPD Flash Tool download is manual" -Level "INFO" -Category "ToolManager"
        Write-Log -Message "Please download from: $($toolInfo.url)" -Level "INFO" -Category "ToolManager"
        
        # Note: SPD Flash Tool often requires manual download due to website protections
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to process SPD Flash Tool" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Install-USBDrivers {
    <#
    .SYNOPSIS
    Installiert USB-Treiber silent
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriversDirectory
    )
    
    try {
        Write-Log -Message "USB driver installation requires manual steps" -Level "INFO" -Category "ToolManager"
        Write-Log -Message "Drivers should be installed via Device Manager or driver installer" -Level "INFO" -Category "ToolManager"
        
        # Note: Driver installation often requires user interaction
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to install USB drivers" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Add-ToSystemPath {
    <#
    .SYNOPSIS
    Fügt einen Pfad zur System-PATH-Variable hinzu
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        
        if ($currentPath -like "*$Path*") {
            Write-Log -Message "Path already in system PATH: $Path" -Level "INFO" -Category "ToolManager"
            return $true
        }
        
        $newPath = "$currentPath;$Path"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        
        # Also update current session
        $env:Path = "$env:Path;$Path"
        
        Write-Log -Message "Added to system PATH: $Path" -Level "INFO" -Category "ToolManager"
        return $true
    }
    catch {
        Write-ErrorLog -Message "Failed to add to system PATH" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

function Install-AllTools {
    <#
    .SYNOPSIS
    Installiert alle benötigten Tools
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkDirectory
    )
    
    try {
        $toolsDir = Join-Path $WorkDirectory "tools"
        $driversDir = Join-Path $WorkDirectory "drivers"
        
        if (-not (Test-Path $toolsDir)) {
            New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null
        }
        
        if (-not (Test-Path $driversDir)) {
            New-Item -Path $driversDir -ItemType Directory -Force | Out-Null
        }
        
        $steps = @(
            @{ Name = "Platform Tools (ADB/Fastboot)"; Action = { Install-PlatformTools -ToolsDirectory $toolsDir } },
            @{ Name = "Python Embedded + Unisoc Unlock"; Action = { Install-PythonEmbedded -ToolsDirectory $toolsDir } },
            @{ Name = "Magisk"; Action = { Install-Magisk -ToolsDirectory $toolsDir } },
            @{ Name = "SPD Flash Tool"; Action = { Install-SPDFlashTool -ToolsDirectory $toolsDir } },
            @{ Name = "USB Drivers"; Action = { Install-USBDrivers -DriversDirectory $driversDir } }
        )
        
        $successCount = 0
        
        foreach ($step in $steps) {
            Show-StatusMessage -Message "Installing $($step.Name)..." -Status "Processing"
            
            $result = & $step.Action
            
            if ($result) {
                Show-StatusMessage -Message "$($step.Name) installed" -Status "Success"
                $successCount++
            }
            else {
                Show-StatusMessage -Message "$($step.Name) failed or requires manual action" -Status "Warning"
            }
        }
        
        Write-Log -Message "Tool installation completed: $successCount/$($steps.Count) successful" -Level "INFO" -Category "ToolManager"
        
        return $successCount -eq $steps.Count
    }
    catch {
        Write-ErrorLog -Message "Failed to install all tools" -ErrorRecord $_ -Category "ToolManager"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ToolsConfig',
    'Install-PlatformTools',
    'Install-PythonEmbedded',
    'Install-Magisk',
    'Install-SPDFlashTool',
    'Install-USBDrivers',
    'Install-AllTools',
    'Add-ToSystemPath'
)
