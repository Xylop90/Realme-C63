<#
.SYNOPSIS
    Driver Manager Module for Realme C63 Installer
.DESCRIPTION
    Handles silent installation of SPD/Unisoc and Realme USB drivers
    with automatic download, verification, and installation.
.NOTES
    Part of Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Copyright © 2026
#>

# Import required modules
Import-Module "$PSScriptRoot\Logger.psm1" -Force
Import-Module "$PSScriptRoot\Download-Manager.psm1" -Force
Import-Module "$PSScriptRoot\Hash-Verifier.psm1" -Force
Import-Module "$PSScriptRoot\UI-Helper.psm1" -Force

# Load configuration
$driverConfig = Get-Content "$PSScriptRoot\..\..\config\driver-signatures.json" | ConvertFrom-Json
$toolVersions = Get-Content "$PSScriptRoot\..\..\config\tool-versions.json" | ConvertFrom-Json

<#
.SYNOPSIS
    Tests if drivers are installed
.DESCRIPTION
    Checks if SPD/Unisoc and Realme USB drivers are installed on the system
.OUTPUTS
    PSCustomObject with driver installation status
#>
function Test-DriversInstalled {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Checking driver installation status..." "INFO"
        
        $spdDriverInstalled = $false
        $realmeDriverInstalled = $false
        
        # Check for SPD/Unisoc drivers
        $spdDrivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object {
            $_.DeviceName -like "*Spreadtrum*" -or 
            $_.DeviceName -like "*Unisoc*" -or
            $_.DeviceName -like "*SPD*"
        }
        
        if ($spdDrivers) {
            $spdDriverInstalled = $true
            Write-LogMessage "SPD/Unisoc drivers detected" "OK"
        }
        
        # Check for Realme USB drivers
        $realmeDrivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object {
            $_.DeviceName -like "*Realme*" -or 
            $_.DeviceName -like "*OPPO*" -or
            $_.Manufacturer -like "*OPPO*"
        }
        
        if ($realmeDrivers) {
            $realmeDriverInstalled = $true
            Write-LogMessage "Realme USB drivers detected" "OK"
        }
        
        return [PSCustomObject]@{
            SPDDriverInstalled = $spdDriverInstalled
            RealmeDriverInstalled = $realmeDriverInstalled
            AllDriversInstalled = ($spdDriverInstalled -and $realmeDriverInstalled)
        }
    }
    catch {
        Write-LogMessage "Error checking driver status: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Downloads driver packages
.DESCRIPTION
    Downloads SPD/Unisoc and Realme USB driver packages with mirror fallback
.PARAMETER DriverType
    Type of driver to download: SPD or Realme
.PARAMETER OutputPath
    Path to save downloaded driver package
#>
function Get-DriverPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("SPD", "Realme")]
        [string]$DriverType,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    try {
        $driverInfo = if ($DriverType -eq "SPD") {
            $toolVersions.tools | Where-Object { $_.name -eq "spd_drivers" }
        } else {
            $toolVersions.tools | Where-Object { $_.name -eq "realme_usb_drivers" }
        }
        
        if (-not $driverInfo) {
            throw "Driver configuration not found for $DriverType"
        }
        
        Write-LogMessage "Downloading $DriverType drivers from $($driverInfo.download_url)" "INFO"
        
        # Try primary URL
        $downloaded = Get-FileWithMirrors -Url $driverInfo.download_url `
                                          -OutputPath $OutputPath `
                                          -MirrorUrls $driverInfo.mirror_urls
        
        if ($downloaded) {
            Write-LogMessage "$DriverType drivers downloaded successfully" "OK"
            
            # Verify hash if available
            if ($driverConfig.$DriverType.expected_hash) {
                $verified = Test-FileHash -FilePath $OutputPath `
                                         -ExpectedHash $driverConfig.$DriverType.expected_hash
                if (-not $verified) {
                    Write-LogMessage "Hash verification failed for $DriverType drivers" "WARN"
                }
            }
            
            return $true
        }
        
        return $false
    }
    catch {
        Write-LogMessage "Error downloading $DriverType drivers: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Extracts driver package
.DESCRIPTION
    Extracts driver package to specified directory
.PARAMETER PackagePath
    Path to driver package (ZIP/EXE)
.PARAMETER ExtractPath
    Path to extract driver files
#>
function Expand-DriverPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ExtractPath
    )
    
    try {
        Write-LogMessage "Extracting driver package: $PackagePath" "INFO"
        
        if (-not (Test-Path $PackagePath)) {
            throw "Driver package not found: $PackagePath"
        }
        
        # Create extract directory
        if (-not (Test-Path $ExtractPath)) {
            New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null
        }
        
        # Extract based on file type
        $extension = [System.IO.Path]::GetExtension($PackagePath).ToLower()
        
        if ($extension -eq ".zip") {
            Expand-Archive -Path $PackagePath -DestinationPath $ExtractPath -Force
            Write-LogMessage "ZIP package extracted successfully" "OK"
        }
        elseif ($extension -eq ".exe") {
            # Try silent extraction
            $extractArgs = @("/S", "/D=$ExtractPath")
            $process = Start-Process -FilePath $PackagePath -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                Write-LogMessage "EXE package extracted successfully" "OK"
            } else {
                Write-LogMessage "Silent extraction failed, package may need manual extraction" "WARN"
            }
        }
        else {
            throw "Unsupported package format: $extension"
        }
        
        return $true
    }
    catch {
        Write-LogMessage "Error extracting driver package: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Installs driver silently
.DESCRIPTION
    Installs driver package using dpinst or pnputil
.PARAMETER DriverPath
    Path to driver INF file or directory
.PARAMETER DriverType
    Type of driver being installed
#>
function Install-DriverSilent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriverPath,
        
        [Parameter(Mandatory = $true)]
        [string]$DriverType
    )
    
    try {
        Write-LogMessage "Installing $DriverType drivers from: $DriverPath" "INFO"
        
        # Check if path is directory or INF file
        if (Test-Path $DriverPath -PathType Container) {
            # Find INF files in directory
            $infFiles = Get-ChildItem -Path $DriverPath -Filter "*.inf" -Recurse
            
            if ($infFiles.Count -eq 0) {
                throw "No INF files found in: $DriverPath"
            }
            
            Write-LogMessage "Found $($infFiles.Count) INF file(s)" "INFO"
            
            # Install each INF file
            foreach ($inf in $infFiles) {
                Write-LogMessage "Installing: $($inf.Name)" "INFO"
                
                # Use pnputil for installation
                $result = & pnputil.exe /add-driver $inf.FullName /install
                
                if ($LASTEXITCODE -eq 0) {
                    Write-LogMessage "Driver installed: $($inf.Name)" "OK"
                } else {
                    Write-LogMessage "Driver installation warning: $($inf.Name)" "WARN"
                }
            }
        }
        elseif ((Test-Path $DriverPath) -and ($DriverPath -like "*.inf")) {
            # Single INF file
            $result = & pnputil.exe /add-driver $DriverPath /install
            
            if ($LASTEXITCODE -eq 0) {
                Write-LogMessage "Driver installed successfully" "OK"
            } else {
                Write-LogMessage "Driver installation completed with warnings" "WARN"
            }
        }
        else {
            throw "Invalid driver path: $DriverPath"
        }
        
        return $true
    }
    catch {
        Write-LogMessage "Error installing driver: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Installs all required drivers
.DESCRIPTION
    Downloads and installs SPD/Unisoc and Realme USB drivers
.PARAMETER Force
    Force reinstallation even if drivers are already installed
#>
function Install-AllDrivers {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    try {
        Write-ColoredMessage "=== Driver Installation ===" "Cyan"
        
        # Check current status
        $status = Test-DriversInstalled
        
        if ($status.AllDriversInstalled -and -not $Force) {
            Write-ColoredMessage "All drivers already installed" "Green"
            return $true
        }
        
        $workPath = "$PSScriptRoot\..\..\work\drivers"
        if (-not (Test-Path $workPath)) {
            New-Item -Path $workPath -ItemType Directory -Force | Out-Null
        }
        
        # Install SPD drivers if needed
        if (-not $status.SPDDriverInstalled -or $Force) {
            Write-ColoredMessage "Installing SPD/Unisoc drivers..." "Yellow"
            
            $spdPackage = Join-Path $workPath "spd_drivers.zip"
            $spdExtract = Join-Path $workPath "spd_drivers"
            
            # Download
            if (Get-DriverPackage -DriverType "SPD" -OutputPath $spdPackage) {
                # Extract
                Expand-DriverPackage -PackagePath $spdPackage -ExtractPath $spdExtract
                
                # Install
                Install-DriverSilent -DriverPath $spdExtract -DriverType "SPD"
            }
        }
        
        # Install Realme drivers if needed
        if (-not $status.RealmeDriverInstalled -or $Force) {
            Write-ColoredMessage "Installing Realme USB drivers..." "Yellow"
            
            $realmePackage = Join-Path $workPath "realme_drivers.zip"
            $realmeExtract = Join-Path $workPath "realme_drivers"
            
            # Download
            if (Get-DriverPackage -DriverType "Realme" -OutputPath $realmePackage) {
                # Extract
                Expand-DriverPackage -PackagePath $realmePackage -ExtractPath $realmeExtract
                
                # Install
                Install-DriverSilent -DriverPath $realmeExtract -DriverType "Realme"
            }
        }
        
        Write-ColoredMessage "Driver installation completed" "Green"
        Write-ColoredMessage "Note: You may need to reconnect your device" "Yellow"
        
        return $true
    }
    catch {
        Write-LogMessage "Error during driver installation: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Shows driver installation status
.DESCRIPTION
    Displays detailed information about installed drivers
#>
function Show-DriverStatus {
    [CmdletBinding()]
    param()
    
    try {
        Write-ColoredMessage "`n=== Driver Status ===" "Cyan"
        
        $status = Test-DriversInstalled
        
        # SPD Drivers
        $spdStatus = if ($status.SPDDriverInstalled) { "✓ Installed" } else { "✗ Not Installed" }
        $spdColor = if ($status.SPDDriverInstalled) { "Green" } else { "Red" }
        Write-Host "SPD/Unisoc Drivers: " -NoNewline
        Write-ColoredMessage $spdStatus $spdColor
        
        # Realme Drivers
        $realmeStatus = if ($status.RealmeDriverInstalled) { "✓ Installed" } else { "✗ Not Installed" }
        $realmeColor = if ($status.RealmeDriverInstalled) { "Green" } else { "Red" }
        Write-Host "Realme USB Drivers: " -NoNewline
        Write-ColoredMessage $realmeStatus $realmeColor
        
        # Overall status
        Write-Host "`nOverall Status: " -NoNewline
        if ($status.AllDriversInstalled) {
            Write-ColoredMessage "✓ All drivers installed" "Green"
        } else {
            Write-ColoredMessage "⚠ Missing drivers" "Yellow"
        }
        
        return $status
    }
    catch {
        Write-LogMessage "Error showing driver status: $_" "ERROR"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-DriversInstalled',
    'Get-DriverPackage',
    'Expand-DriverPackage',
    'Install-DriverSilent',
    'Install-AllDrivers',
    'Show-DriverStatus'
)
