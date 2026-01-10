#Requires -Version 5.1

<#
.SYNOPSIS
    Hash verification module for SHA256 validation

.DESCRIPTION
    Provides SHA256 hash calculation and verification for downloaded files
    to ensure integrity and security.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

<#
.SYNOPSIS
    Calculates SHA256 hash of a file

.PARAMETER FilePath
    Path to the file

.EXAMPLE
    $hash = Get-FileHash256 -FilePath "C:\download\file.zip"
#>
function Get-FileHash256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]$FilePath
    )

    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash
    }
    catch {
        Write-Error "Failed to calculate hash for $FilePath : $_"
        return $null
    }
}

<#
.SYNOPSIS
    Verifies file hash against expected hash

.PARAMETER FilePath
    Path to the file

.PARAMETER ExpectedHash
    Expected SHA256 hash

.EXAMPLE
    $valid = Test-FileHash256 -FilePath "C:\download\file.zip" -ExpectedHash "ABC123..."
#>
function Test-FileHash256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExpectedHash
    )

    try {
        $actualHash = Get-FileHash256 -FilePath $FilePath
        
        if ($null -eq $actualHash) {
            return $false
        }

        $match = $actualHash -eq $ExpectedHash

        if ($match) {
            Write-Verbose "Hash verification successful for $FilePath"
        }
        else {
            Write-Warning "Hash mismatch for $FilePath"
            Write-Warning "Expected: $ExpectedHash"
            Write-Warning "Actual:   $actualHash"
        }

        return $match
    }
    catch {
        Write-Error "Failed to verify hash: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Verifies file hash with automatic hash retrieval

.PARAMETER FilePath
    Path to the file

.PARAMETER HashUrl
    URL to retrieve expected hash from

.EXAMPLE
    $valid = Test-FileHashAuto -FilePath "C:\download\file.zip" -HashUrl "https://example.com/file.zip.sha256"
#>
function Test-FileHashAuto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$HashUrl
    )

    try {
        # Download hash file
        $hashContent = Invoke-WebRequest -Uri $HashUrl -UseBasicParsing | Select-Object -ExpandProperty Content

        # Extract hash (handle various formats)
        $hash = $null
        if ($hashContent -match '([A-Fa-f0-9]{64})') {
            $hash = $Matches[1]
        }

        if ($null -eq $hash) {
            Write-Error "Could not extract hash from $HashUrl"
            return $false
        }

        return Test-FileHash256 -FilePath $FilePath -ExpectedHash $hash
    }
    catch {
        Write-Error "Failed to auto-verify hash: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Saves file hash to a .sha256 file

.PARAMETER FilePath
    Path to the file

.EXAMPLE
    Save-FileHash256 -FilePath "C:\download\file.zip"
    # Creates C:\download\file.zip.sha256
#>
function Save-FileHash256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]$FilePath
    )

    try {
        $hash = Get-FileHash256 -FilePath $FilePath
        
        if ($null -eq $hash) {
            return $false
        }

        $hashFilePath = "$FilePath.sha256"
        $fileName = Split-Path -Leaf $FilePath
        
        "$hash  $fileName" | Out-File -FilePath $hashFilePath -Encoding ASCII

        Write-Verbose "Hash saved to $hashFilePath"
        return $true
    }
    catch {
        Write-Error "Failed to save hash: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Loads expected hash from .sha256 file

.PARAMETER FilePath
    Path to the file (hash file should be FilePath.sha256)

.EXAMPLE
    $hash = Get-SavedHash256 -FilePath "C:\download\file.zip"
#>
function Get-SavedHash256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    try {
        $hashFilePath = "$FilePath.sha256"
        
        if (-not (Test-Path $hashFilePath)) {
            Write-Verbose "No hash file found at $hashFilePath"
            return $null
        }

        $content = Get-Content -Path $hashFilePath -Raw
        
        if ($content -match '([A-Fa-f0-9]{64})') {
            return $Matches[1]
        }

        return $null
    }
    catch {
        Write-Error "Failed to load saved hash: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Verifies file against saved hash

.PARAMETER FilePath
    Path to the file

.EXAMPLE
    $valid = Test-SavedHash256 -FilePath "C:\download\file.zip"
#>
function Test-SavedHash256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]$FilePath
    )

    try {
        $savedHash = Get-SavedHash256 -FilePath $FilePath
        
        if ($null -eq $savedHash) {
            Write-Warning "No saved hash found for $FilePath"
            return $false
        }

        return Test-FileHash256 -FilePath $FilePath -ExpectedHash $savedHash
    }
    catch {
        Write-Error "Failed to verify saved hash: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Generates hash report for multiple files

.PARAMETER FileList
    Array of file paths

.PARAMETER OutputPath
    Path to save report

.EXAMPLE
    New-HashReport -FileList @("file1.zip", "file2.zip") -OutputPath "hashes.txt"
#>
function New-HashReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$FileList,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    try {
        $report = @()
        $report += "SHA256 Hash Report"
        $report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $report += "="*80
        $report += ""

        foreach ($file in $FileList) {
            if (Test-Path $file) {
                $hash = Get-FileHash256 -FilePath $file
                $fileName = Split-Path -Leaf $file
                $report += "$hash  $fileName"
            }
            else {
                $report += "FILE NOT FOUND: $file"
            }
        }

        $report | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Verbose "Hash report saved to $OutputPath"
        return $true
    }
    catch {
        Write-Error "Failed to create hash report: $_"
        return $false
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-FileHash256',
    'Test-FileHash256',
    'Test-FileHashAuto',
    'Save-FileHash256',
    'Get-SavedHash256',
    'Test-SavedHash256',
    'New-HashReport'
)
