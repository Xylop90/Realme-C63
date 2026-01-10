#Requires -Version 5.1

<#
.SYNOPSIS
    Python Manager for Python 3.11 Embedded integration

.DESCRIPTION
    Provides Python 3.11 Embedded installation, management, and package installation
    specifically for unisoc-unlock and other Python-based tools.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

$script:PythonPath = $null
$script:PipPath = $null

<#
.SYNOPSIS
    Installs Python 3.11 Embedded

.PARAMETER InstallPath
    Installation directory

.PARAMETER DownloadUrl
    Python download URL

.EXAMPLE
    Install-PythonEmbedded -InstallPath "work/python311"
#>
function Install-PythonEmbedded {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$InstallPath = "work/python311",

        [Parameter(Mandatory=$false)]
        [string]$DownloadUrl = "https://www.python.org/ftp/python/3.11.8/python-3.11.8-embed-amd64.zip"
    )

    try {
        Write-Host "Installing Python 3.11 Embedded..." -ForegroundColor Cyan

        # Create install directory
        if (-not (Test-Path $InstallPath)) {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        }

        # Check if already installed
        $pythonExe = Join-Path $InstallPath "python.exe"
        if (Test-Path $pythonExe) {
            Write-Host "Python already installed at: $InstallPath" -ForegroundColor Green
            $script:PythonPath = $InstallPath
            return @{
                Success = $true
                PythonPath = $InstallPath
                AlreadyInstalled = $true
            }
        }

        # Download Python embedded
        $downloadPath = Join-Path (Split-Path $InstallPath -Parent) "python311.zip"
        Write-Host "Downloading Python 3.11.8 Embedded..." -ForegroundColor Cyan
        
        $downloadResult = Get-RemoteFile -Url $DownloadUrl -Destination $downloadPath

        if (-not $downloadResult.Success) {
            throw "Failed to download Python"
        }

        # Extract
        Write-Host "Extracting Python..." -ForegroundColor Cyan
        Expand-Archive -Path $downloadPath -DestinationPath $InstallPath -Force

        # Cleanup download
        Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue

        # Configure Python
        Initialize-PythonEnvironment -PythonPath $InstallPath

        $script:PythonPath = $InstallPath

        Write-Host "Python 3.11 Embedded installed successfully" -ForegroundColor Green
        return @{
            Success = $true
            PythonPath = $InstallPath
        }
    }
    catch {
        Write-Error "Failed to install Python: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Initializes Python environment for package installation

.PARAMETER PythonPath
    Python installation path

.EXAMPLE
    Initialize-PythonEnvironment -PythonPath "work/python311"
#>
function Initialize-PythonEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PythonPath
    )

    try {
        # Enable site-packages by modifying python311._pth
        $pthFile = Get-ChildItem -Path $PythonPath -Filter "python*._pth" | Select-Object -First 1
        
        if ($pthFile) {
            $content = Get-Content -Path $pthFile.FullName
            $newContent = $content -replace '#import site', 'import site'
            $newContent | Out-File -FilePath $pthFile.FullName -Encoding ASCII
            Write-Verbose "Enabled site-packages in $($pthFile.Name)"
        }

        # Install pip
        $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
        $getPipPath = Join-Path $PythonPath "get-pip.py"
        
        Write-Host "Downloading get-pip.py..." -ForegroundColor Cyan
        $downloadResult = Get-RemoteFile -Url $getPipUrl -Destination $getPipPath

        if ($downloadResult.Success) {
            Write-Host "Installing pip..." -ForegroundColor Cyan
            $pythonExe = Join-Path $PythonPath "python.exe"
            & $pythonExe $getPipPath --no-warn-script-location 2>&1 | Out-Null
            
            Remove-Item -Path $getPipPath -Force -ErrorAction SilentlyContinue

            # Set pip path
            $script:PipPath = Join-Path $PythonPath "Scripts\pip.exe"
            
            Write-Host "pip installed successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to initialize Python environment: $_"
    }
}

<#
.SYNOPSIS
    Installs a Python package via pip

.PARAMETER PackageName
    Package name

.PARAMETER PythonPath
    Python installation path

.EXAMPLE
    Install-PythonPackage -PackageName "unisoc-unlock"
#>
function Install-PythonPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName,

        [Parameter(Mandatory=$false)]
        [string]$PythonPath = $script:PythonPath
    )

    try {
        if ([string]::IsNullOrWhiteSpace($PythonPath)) {
            throw "Python not initialized. Run Install-PythonEmbedded first."
        }

        $pythonExe = Join-Path $PythonPath "python.exe"
        
        if (-not (Test-Path $pythonExe)) {
            throw "Python executable not found at: $pythonExe"
        }

        Write-Host "Installing Python package: $PackageName..." -ForegroundColor Cyan

        # Install package
        $result = & $pythonExe -m pip install $PackageName --no-warn-script-location 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Package $PackageName installed successfully" -ForegroundColor Green
            return @{
                Success = $true
                Package = $PackageName
            }
        }
        else {
            throw "pip install failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Failed to install package $PackageName : $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Installs unisoc-unlock package

.PARAMETER PythonPath
    Python installation path

.EXAMPLE
    Install-UnisocUnlock
#>
function Install-UnisocUnlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$PythonPath = $script:PythonPath
    )

    try {
        Write-Host "Installing unisoc-unlock..." -ForegroundColor Cyan
        
        $result = Install-PythonPackage -PackageName "unisoc-unlock" -PythonPath $PythonPath

        if ($result.Success) {
            Write-Host "unisoc-unlock installed successfully" -ForegroundColor Green
            Write-Host "GitHub: https://github.com/patrislav1/unisoc-unlock" -ForegroundColor Gray
            Write-Host "PyPI: https://pypi.org/project/unisoc-unlock/" -ForegroundColor Gray
        }

        return $result
    }
    catch {
        Write-Error "Failed to install unisoc-unlock: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Tests if Python is available

.PARAMETER PythonPath
    Python installation path

.EXAMPLE
    $hasPython = Test-PythonAvailable
#>
function Test-PythonAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$PythonPath = $script:PythonPath
    )

    try {
        if ([string]::IsNullOrWhiteSpace($PythonPath)) {
            return $false
        }

        $pythonExe = Join-Path $PythonPath "python.exe"
        
        if (-not (Test-Path $pythonExe)) {
            return $false
        }

        $result = & $pythonExe --version 2>&1
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Gets Python version

.PARAMETER PythonPath
    Python installation path

.EXAMPLE
    $version = Get-PythonVersion
#>
function Get-PythonVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$PythonPath = $script:PythonPath
    )

    try {
        $pythonExe = Join-Path $PythonPath "python.exe"
        $version = & $pythonExe --version 2>&1
        return $version -replace "Python ", ""
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    Lists installed Python packages

.PARAMETER PythonPath
    Python installation path

.EXAMPLE
    $packages = Get-PythonPackages
#>
function Get-PythonPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$PythonPath = $script:PythonPath
    )

    try {
        $pythonExe = Join-Path $PythonPath "python.exe"
        $packages = & $pythonExe -m pip list --format=json 2>&1 | ConvertFrom-Json
        return $packages
    }
    catch {
        Write-Error "Failed to list packages: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Runs a Python module

.PARAMETER Module
    Module name

.PARAMETER Arguments
    Module arguments

.PARAMETER PythonPath
    Python installation path

.EXAMPLE
    Invoke-PythonModule -Module "unisoc_unlock" -Arguments @("unlock")
#>
function Invoke-PythonModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Module,

        [Parameter(Mandatory=$false)]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory=$false)]
        [string]$PythonPath = $script:PythonPath
    )

    try {
        $pythonExe = Join-Path $PythonPath "python.exe"
        
        $cmdArgs = @("-m", $Module) + $Arguments
        
        Write-Verbose "Executing: $pythonExe $cmdArgs"
        
        & $pythonExe $cmdArgs

        return @{
            Success = ($LASTEXITCODE -eq 0)
            ExitCode = $LASTEXITCODE
        }
    }
    catch {
        Write-Error "Failed to run Python module: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Install-PythonEmbedded',
    'Initialize-PythonEnvironment',
    'Install-PythonPackage',
    'Install-UnisocUnlock',
    'Test-PythonAvailable',
    'Get-PythonVersion',
    'Get-PythonPackages',
    'Invoke-PythonModule'
)
