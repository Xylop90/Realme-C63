#Requires -Version 5.1
<#
.SYNOPSIS
    File download helper module for Realme C63 installation scripts

.DESCRIPTION
    Provides file download functionality with retry logic, progress tracking,
    and cache management.

.NOTES
    Author: Realme C63 SPD Flash Tool Automation
    Version: 1.0
#>

function Download-FileWithProgress {
    <#
    .SYNOPSIS
        Download a file with progress indication and retry logic
    
    .PARAMETER Url
        URL to download from
    
    .PARAMETER Destination
        Destination file path
    
    .PARAMETER Description
        Description of the file being downloaded
    
    .PARAMETER MaxRetries
        Maximum number of retry attempts
    
    .PARAMETER UseCache
        Use cached file if it exists
    
    .OUTPUTS
        Boolean indicating success or failure
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "File",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,
        
        [switch]$UseCache
    )
    
    # Check if file already exists in cache
    if ($UseCache -and (Test-Path $Destination)) {
        $fileInfo = Get-Item $Destination
        Write-Log "Using cached file: $Destination ($(Format-FileSize $fileInfo.Length))" "INFO"
        return $true
    }
    
    # Ensure destination directory exists
    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }
    
    $attempt = 0
    $success = $false
    
    while ($attempt -lt $MaxRetries -and -not $success) {
        $attempt++
        
        try {
            Write-Log "Downloading $Description (Attempt $attempt/$MaxRetries)..." "INFO"
            Write-Log "URL: $Url" "DEBUG"
            
            # Use WebClient for better progress tracking
            $webClient = New-Object System.Net.WebClient
            
            # Register progress event
            Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.ProgressChanged -Action {
                $percent = $EventArgs.ProgressPercentage
                $received = Format-FileSize $EventArgs.BytesReceived
                $total = Format-FileSize $EventArgs.TotalBytesToReceive
                Write-Progress -Activity "Downloading $using:Description" -Status "$received / $total" -PercentComplete $percent
            } | Out-Null
            
            # Start download
            $webClient.DownloadFile($Url, $Destination)
            
            # Cleanup event
            Unregister-Event -SourceIdentifier WebClient.ProgressChanged -ErrorAction SilentlyContinue
            $webClient.Dispose()
            
            Write-Progress -Activity "Downloading $Description" -Completed
            
            if (Test-Path $Destination) {
                $fileInfo = Get-Item $Destination
                Write-Log "$Description downloaded successfully: $Destination ($(Format-FileSize $fileInfo.Length))" "SUCCESS"
                $success = $true
            }
            else {
                Write-Log "Download completed but file not found at destination" "ERROR"
            }
        }
        catch {
            Write-Log "Download attempt $attempt failed: $_" "WARN"
            
            # Cleanup on failure
            Unregister-Event -SourceIdentifier WebClient.ProgressChanged -ErrorAction SilentlyContinue
            
            if ($attempt -lt $MaxRetries) {
                $waitTime = $attempt * 2
                Write-Log "Waiting $waitTime seconds before retry..." "INFO"
                Start-Sleep -Seconds $waitTime
            }
            else {
                Write-Log "Download failed after $MaxRetries attempts" "ERROR"
            }
        }
    }
    
    return $success
}

function Download-FileSimple {
    <#
    .SYNOPSIS
        Simple file download using Invoke-WebRequest
    
    .PARAMETER Url
        URL to download from
    
    .PARAMETER Destination
        Destination file path
    
    .PARAMETER UseCache
        Use cached file if it exists
    
    .OUTPUTS
        Boolean indicating success or failure
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [switch]$UseCache
    )
    
    # Check cache
    if ($UseCache -and (Test-Path $Destination)) {
        Write-Log "Using cached file: $Destination" "INFO"
        return $true
    }
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
        $ProgressPreference = 'Continue'
        
        if (Test-Path $Destination) {
            Write-Log "File downloaded: $Destination" "SUCCESS"
            return $true
        }
        
        return $false
    }
    catch {
        Write-Log "Download failed: $_" "ERROR"
        return $false
    }
}

function Test-UrlAccessible {
    <#
    .SYNOPSIS
        Test if a URL is accessible
    
    .PARAMETER Url
        URL to test
    
    .PARAMETER TimeoutSeconds
        Timeout in seconds
    
    .OUTPUTS
        Boolean indicating if URL is accessible
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 10
    )
    
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Timeout = $TimeoutSeconds * 1000
        $request.Method = "HEAD"
        
        $response = $request.GetResponse()
        $statusCode = [int]$response.StatusCode
        $response.Close()
        
        return ($statusCode -ge 200 -and $statusCode -lt 400)
    }
    catch {
        Write-Log "URL not accessible: $Url" "DEBUG"
        return $false
    }
}

function Format-FileSize {
    <#
    .SYNOPSIS
        Format file size in human-readable format
    
    .PARAMETER SizeInBytes
        File size in bytes
    
    .OUTPUTS
        Formatted string (e.g., "1.5 MB")
    #>
    param(
        [Parameter(Mandatory = $true)]
        [long]$SizeInBytes
    )
    
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

function Expand-ArchiveWithProgress {
    <#
    .SYNOPSIS
        Extract archive with progress indication
    
    .PARAMETER ArchivePath
        Path to archive file
    
    .PARAMETER DestinationPath
        Destination directory
    
    .PARAMETER Force
        Overwrite existing files
    
    .OUTPUTS
        Boolean indicating success or failure
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        
        [switch]$Force
    )
    
    try {
        if (-not (Test-Path $ArchivePath)) {
            Write-Log "Archive not found: $ArchivePath" "ERROR"
            return $false
        }
        
        Write-Log "Extracting archive: $ArchivePath" "INFO"
        Write-Log "Destination: $DestinationPath" "DEBUG"
        
        # Ensure destination exists
        if (-not (Test-Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }
        
        # Extract using Expand-Archive
        if ($Force) {
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force -ErrorAction Stop
        }
        else {
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -ErrorAction Stop
        }
        
        Write-Log "Archive extracted successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to extract archive: $_" "ERROR"
        return $false
    }
}

function Get-FileFromCache {
    <#
    .SYNOPSIS
        Get file from cache directory
    
    .PARAMETER FileName
        Name of the file to retrieve
    
    .PARAMETER CacheDirectory
        Cache directory path
    
    .OUTPUTS
        Full path to cached file or $null if not found
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $true)]
        [string]$CacheDirectory
    )
    
    $cachedFile = Join-Path $CacheDirectory $FileName
    
    if (Test-Path $cachedFile) {
        return $cachedFile
    }
    
    return $null
}

# Export functions
Export-ModuleMember -Function @(
    'Download-FileWithProgress',
    'Download-FileSimple',
    'Test-UrlAccessible',
    'Format-FileSize',
    'Expand-ArchiveWithProgress',
    'Get-FileFromCache'
)
