<#
.SYNOPSIS
    Firmware Manager Module for Realme C63 Installer
.DESCRIPTION
    Handles firmware discovery, download, and verification from multiple sources
    with web scraping and automatic version detection.
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
$firmwareConfig = Get-Content "$PSScriptRoot\..\..\config\firmware-sources.json" | ConvertFrom-Json

<#
.SYNOPSIS
    Searches for firmware from configured sources
.DESCRIPTION
    Scrapes multiple firmware sources to find available firmware for RMX3939
.OUTPUTS
    Array of firmware information objects
#>
function Find-AvailableFirmware {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogMessage "Searching for RMX3939 firmware from multiple sources..." "INFO"
        
        $availableFirmware = @()
        
        foreach ($source in $firmwareConfig.sources) {
            try {
                Write-LogMessage "Checking source: $($source.name)" "INFO"
                
                # Attempt to scrape firmware information
                $response = Invoke-WebRequest -Uri $source.url -UseBasicParsing -TimeoutSec 30
                
                if ($response.StatusCode -eq 200) {
                    # Parse based on source type
                    $firmware = Parse-FirmwareSource -SourceName $source.name `
                                                     -Html $response.Content `
                                                     -Selectors $source.scraping.selectors
                    
                    if ($firmware) {
                        $firmware | ForEach-Object {
                            $_ | Add-Member -NotePropertyName "Source" -NotePropertyValue $source.name
                            $availableFirmware += $_
                        }
                        Write-LogMessage "Found firmware on $($source.name)" "OK"
                    }
                }
            }
            catch {
                Write-LogMessage "Error checking $($source.name): $_" "WARN"
            }
        }
        
        if ($availableFirmware.Count -eq 0) {
            Write-LogMessage "No firmware found from online sources" "WARN"
        } else {
            Write-LogMessage "Found $($availableFirmware.Count) firmware version(s)" "OK"
        }
        
        return $availableFirmware
    }
    catch {
        Write-LogMessage "Error searching for firmware: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Parses firmware information from HTML
.DESCRIPTION
    Extracts firmware download links and version information from HTML content
.PARAMETER SourceName
    Name of the firmware source
.PARAMETER Html
    HTML content to parse
.PARAMETER Selectors
    CSS selectors for parsing
#>
function Parse-FirmwareSource {
    [CmdletBinding()]
    param(
        [string]$SourceName,
        [string]$Html,
        [object]$Selectors
    )
    
    try {
        $firmwareList = @()
        
        # Simple pattern matching for common firmware naming
        $patterns = @(
            'RMX3939.*?\.zip',
            'RMX3939.*?\.pac',
            'realme.*?c63.*?\.zip',
            'export_14_A\.\d+.*?\.zip'
        )
        
        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($Html, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            foreach ($match in $matches) {
                $filename = $match.Value
                
                # Try to extract version
                $versionMatch = [regex]::Match($filename, 'A\.(\d+)')
                $version = if ($versionMatch.Success) { "A.$($versionMatch.Groups[1].Value)" } else { "Unknown" }
                
                $firmwareList += [PSCustomObject]@{
                    Filename = $filename
                    Version = $version
                    Size = "Unknown"
                    DownloadUrl = ""  # Would need more sophisticated parsing
                }
            }
        }
        
        return $firmwareList
    }
    catch {
        Write-LogMessage "Error parsing firmware source: $_" "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Downloads firmware file
.DESCRIPTION
    Downloads firmware from specified URL with progress tracking
.PARAMETER Url
    Firmware download URL
.PARAMETER OutputPath
    Path to save firmware file
.PARAMETER ExpectedHash
    Expected SHA256 hash for verification
#>
function Get-Firmware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [string]$ExpectedHash
    )
    
    try {
        Write-LogMessage "Downloading firmware from: $Url" "INFO"
        
        # Use download manager with resume capability
        $downloaded = Get-FileWithResume -Url $Url -OutputPath $OutputPath
        
        if ($downloaded) {
            Write-LogMessage "Firmware downloaded successfully" "OK"
            
            # Verify hash if provided
            if ($ExpectedHash) {
                $verified = Test-FileHash -FilePath $OutputPath -ExpectedHash $ExpectedHash
                if ($verified) {
                    Write-LogMessage "Firmware hash verified" "OK"
                } else {
                    Write-LogMessage "Firmware hash verification failed!" "ERROR"
                    return $false
                }
            }
            
            return $true
        }
        
        return $false
    }
    catch {
        Write-LogMessage "Error downloading firmware: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Extracts boot.img from firmware
.DESCRIPTION
    Extracts boot.img file from firmware package for Magisk patching
.PARAMETER FirmwarePath
    Path to firmware file (ZIP/PAC)
.PARAMETER OutputPath
    Path to extract boot.img
#>
function Extract-BootImageFromFirmware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FirmwarePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    try {
        Write-LogMessage "Extracting boot.img from: $FirmwarePath" "INFO"
        
        if (-not (Test-Path $FirmwarePath)) {
            throw "Firmware file not found: $FirmwarePath"
        }
        
        $extension = [System.IO.Path]::GetExtension($FirmwarePath).ToLower()
        
        if ($extension -eq ".zip") {
            # Extract from ZIP
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zip = [System.IO.Compression.ZipFile]::OpenRead($FirmwarePath)
            
            try {
                $bootEntry = $zip.Entries | Where-Object { $_.Name -like "*boot*.img" } | Select-Object -First 1
                
                if ($bootEntry) {
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($bootEntry, $OutputPath, $true)
                    Write-LogMessage "boot.img extracted successfully" "OK"
                    return $true
                } else {
                    Write-LogMessage "boot.img not found in firmware package" "ERROR"
                    return $false
                }
            }
            finally {
                $zip.Dispose()
            }
        }
        elseif ($extension -eq ".pac") {
            Write-LogMessage "PAC format requires SPD Research Tool for extraction" "WARN"
            Write-LogMessage "Please extract boot.img manually using SPD Research Tool" "INFO"
            return $false
        }
        else {
            throw "Unsupported firmware format: $extension"
        }
    }
    catch {
        Write-LogMessage "Error extracting boot.img: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Displays firmware information menu
.DESCRIPTION
    Shows interactive menu of available firmware with download options
#>
function Show-FirmwareMenu {
    [CmdletBinding()]
    param()
    
    try {
        Write-ColoredMessage "`n=== Firmware Discovery ===" "Cyan"
        Write-ColoredMessage "Searching for RMX3939 firmware..." "Yellow"
        
        $firmware = Find-AvailableFirmware
        
        if ($firmware.Count -eq 0) {
            Write-ColoredMessage "`nNo firmware found from automatic sources." "Yellow"
            Write-ColoredMessage "Please download firmware manually from:" "White"
            
            foreach ($source in $firmwareConfig.sources) {
                Write-ColoredMessage "  - $($source.name): $($source.url)" "Cyan"
            }
            
            Write-Host "`n"
            $manualPath = Read-Host "Enter path to firmware file (or press Enter to skip)"
            
            if ($manualPath -and (Test-Path $manualPath)) {
                return $manualPath
            }
            
            return $null
        }
        
        # Display found firmware
        Write-ColoredMessage "`nAvailable Firmware:" "Green"
        for ($i = 0; $i -lt $firmware.Count; $i++) {
            Write-Host "  [$($i + 1)] " -NoNewline -ForegroundColor Yellow
            Write-Host "$($firmware[$i].Filename) " -NoNewline -ForegroundColor White
            Write-Host "($($firmware[$i].Version))" -ForegroundColor Cyan
            Write-Host "       Source: $($firmware[$i].Source)" -ForegroundColor Gray
        }
        
        Write-Host "  [0] Enter manual path" -ForegroundColor Yellow
        Write-Host ""
        
        $choice = Read-Host "Select firmware to download [0-$($firmware.Count)]"
        
        if ($choice -eq "0") {
            $manualPath = Read-Host "Enter path to firmware file"
            if ($manualPath -and (Test-Path $manualPath)) {
                return $manualPath
            }
            return $null
        }
        elseif ($choice -ge 1 -and $choice -le $firmware.Count) {
            $selected = $firmware[$choice - 1]
            Write-ColoredMessage "Selected: $($selected.Filename)" "Green"
            
            # Would download here if URL was available
            Write-ColoredMessage "Automatic download not fully implemented" "WARN"
            Write-ColoredMessage "Please download from: $($firmwareConfig.sources[$choice-1].url)" "Yellow"
            
            $manualPath = Read-Host "Enter path to downloaded firmware"
            if ($manualPath -and (Test-Path $manualPath)) {
                return $manualPath
            }
        }
        
        return $null
    }
    catch {
        Write-LogMessage "Error in firmware menu: $_" "ERROR"
        throw
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Find-AvailableFirmware',
    'Parse-FirmwareSource',
    'Get-Firmware',
    'Extract-BootImageFromFirmware',
    'Show-FirmwareMenu'
)
