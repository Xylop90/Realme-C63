#Requires -Version 5.1
<#
.SYNOPSIS
    Hash verification module for Realme C63 installation scripts

.DESCRIPTION
    Provides SHA256 hash calculation and verification functionality
    for downloaded files.

.NOTES
    Author: Realme C63 SPD Flash Tool Automation
    Version: 1.0
#>

function Get-FileSHA256Hash {
    <#
    .SYNOPSIS
        Calculate SHA256 hash of a file
    
    .PARAMETER FilePath
        Path to the file
    
    .OUTPUTS
        SHA256 hash string (uppercase) or $null on error
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Log "File not found for hash calculation: $FilePath" "ERROR"
            return $null
        }
        
        Write-Log "Calculating SHA256 hash for: $(Split-Path -Leaf $FilePath)" "INFO"
        
        $hash = (Get-FileHash -Path $FilePath -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpper()
        
        Write-Log "Hash: $hash" "DEBUG"
        
        return $hash
    }
    catch {
        Write-Log "Failed to calculate hash: $_" "ERROR"
        return $null
    }
}

function Test-FileHash {
    <#
    .SYNOPSIS
        Verify file hash against expected value
    
    .PARAMETER FilePath
        Path to the file to verify
    
    .PARAMETER ExpectedHash
        Expected SHA256 hash (case-insensitive)
    
    .PARAMETER SkipIfEmpty
        Skip verification if expected hash is empty
    
    .OUTPUTS
        Boolean indicating if hash matches
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ExpectedHash,
        
        [switch]$SkipIfEmpty
    )
    
    # Check if expected hash is empty
    if ([string]::IsNullOrWhiteSpace($ExpectedHash)) {
        if ($SkipIfEmpty) {
            Write-Log "No expected hash provided - skipping verification" "WARN"
            $calculatedHash = Get-FileSHA256Hash -FilePath $FilePath
            if ($calculatedHash) {
                Write-Log "Calculated hash (please update config): $calculatedHash" "WARN"
            }
            return $true
        }
        else {
            Write-Log "Expected hash is empty and SkipIfEmpty is not set" "ERROR"
            return $false
        }
    }
    
    # Calculate actual hash
    $actualHash = Get-FileSHA256Hash -FilePath $FilePath
    
    if (-not $actualHash) {
        Write-Log "Failed to calculate file hash" "ERROR"
        return $false
    }
    
    # Compare hashes (case-insensitive)
    $expectedHashUpper = $ExpectedHash.ToUpper()
    $actualHashUpper = $actualHash.ToUpper()
    
    if ($expectedHashUpper -eq $actualHashUpper) {
        Write-Log "Hash verification PASSED" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Hash verification FAILED" "ERROR"
        Write-Log "Expected: $expectedHashUpper" "ERROR"
        Write-Log "Actual:   $actualHashUpper" "ERROR"
        return $false
    }
}

function Compare-FileHashes {
    <#
    .SYNOPSIS
        Compare hashes of two files
    
    .PARAMETER FilePath1
        Path to first file
    
    .PARAMETER FilePath2
        Path to second file
    
    .OUTPUTS
        Boolean indicating if hashes match
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath1,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath2
    )
    
    $hash1 = Get-FileSHA256Hash -FilePath $FilePath1
    $hash2 = Get-FileSHA256Hash -FilePath $FilePath2
    
    if (-not $hash1 -or -not $hash2) {
        Write-Log "Failed to calculate one or both hashes" "ERROR"
        return $false
    }
    
    $match = ($hash1 -eq $hash2)
    
    if ($match) {
        Write-Log "File hashes match" "SUCCESS"
    }
    else {
        Write-Log "File hashes do not match" "ERROR"
    }
    
    return $match
}

function Save-HashToFile {
    <#
    .SYNOPSIS
        Save file hash to a .sha256 file
    
    .PARAMETER FilePath
        Path to the file
    
    .PARAMETER HashFilePath
        Optional path to hash file (defaults to FilePath.sha256)
    
    .OUTPUTS
        Boolean indicating success
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$HashFilePath
    )
    
    if (-not $HashFilePath) {
        $HashFilePath = "$FilePath.sha256"
    }
    
    $hash = Get-FileSHA256Hash -FilePath $FilePath
    
    if (-not $hash) {
        Write-Log "Failed to calculate hash for saving" "ERROR"
        return $false
    }
    
    try {
        $fileName = Split-Path -Leaf $FilePath
        $hashContent = "$hash  $fileName"
        
        Set-Content -Path $HashFilePath -Value $hashContent -Force
        
        Write-Log "Hash saved to: $HashFilePath" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to save hash file: $_" "ERROR"
        return $false
    }
}

function Read-HashFromFile {
    <#
    .SYNOPSIS
        Read hash from a .sha256 file
    
    .PARAMETER HashFilePath
        Path to the hash file
    
    .OUTPUTS
        Hash string or $null if not found
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$HashFilePath
    )
    
    try {
        if (-not (Test-Path $HashFilePath)) {
            Write-Log "Hash file not found: $HashFilePath" "DEBUG"
            return $null
        }
        
        $content = Get-Content -Path $HashFilePath -Raw
        
        # Extract hash (first 64 characters)
        if ($content -match '^([A-Fa-f0-9]{64})') {
            return $Matches[1].ToUpper()
        }
        
        Write-Log "Invalid hash file format: $HashFilePath" "WARN"
        return $null
    }
    catch {
        Write-Log "Failed to read hash file: $_" "ERROR"
        return $null
    }
}

function Verify-DownloadIntegrity {
    <#
    .SYNOPSIS
        Verify integrity of a downloaded file
    
    .PARAMETER FilePath
        Path to the downloaded file
    
    .PARAMETER ExpectedHash
        Expected SHA256 hash
    
    .PARAMETER AllowAutoCalculate
        Allow auto-calculation if hash is empty
    
    .OUTPUTS
        Boolean indicating if file is valid
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$ExpectedHash,
        
        [switch]$AllowAutoCalculate
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "File not found for integrity check: $FilePath" "ERROR"
        return $false
    }
    
    # Check if file is empty
    $fileInfo = Get-Item $FilePath
    if ($fileInfo.Length -eq 0) {
        Write-Log "File is empty: $FilePath" "ERROR"
        return $false
    }
    
    Write-Log "File size: $(Format-FileSize $fileInfo.Length)" "INFO"
    
    # Verify hash if provided
    if ([string]::IsNullOrWhiteSpace($ExpectedHash)) {
        if ($AllowAutoCalculate) {
            Write-Log "No expected hash provided - calculating for reference" "WARN"
            $hash = Get-FileSHA256Hash -FilePath $FilePath
            if ($hash) {
                Write-Log "Calculated SHA256: $hash" "WARN"
                Write-Log "Please update configuration file with this hash" "WARN"
            }
            return $true
        }
        else {
            Write-Log "No expected hash provided and auto-calculate not allowed" "WARN"
            return $true
        }
    }
    
    return Test-FileHash -FilePath $FilePath -ExpectedHash $ExpectedHash -SkipIfEmpty:$AllowAutoCalculate
}

# Helper function for file size formatting (if not already imported from download-helper)
function Format-FileSize {
    param([long]$SizeInBytes)
    
    if ($SizeInBytes -ge 1GB) {
        return "{0:N2} GB" -f ($SizeInBytes / 1GB)
    }
    elseif ($SizeInBytes -ge 1MB) {
        return "{0:N2} MB" -f ($SizeInBytes / 1MB)
    }
    elseif ($SizeInBytes -ge 1KB) {
        return "{0:N2} KB" -f ($SizeInBytes / 1KB)
    }
    else {
        return "$SizeInBytes Bytes"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-FileSHA256Hash',
    'Test-FileHash',
    'Compare-FileHashes',
    'Save-HashToFile',
    'Read-HashFromFile',
    'Verify-DownloadIntegrity'
)
