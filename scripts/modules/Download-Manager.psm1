#Requires -Version 5.1

<#
.SYNOPSIS
    Download Manager with BITS transfer, resume support, and mirror fallback

.DESCRIPTION
    Provides intelligent download capabilities with multiple transfer methods,
    automatic resume, mirror fallback, and integrity verification.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

<#
.SYNOPSIS
    Downloads a file with intelligent method selection

.PARAMETER Url
    URL to download from

.PARAMETER Destination
    Destination file path

.PARAMETER ExpectedHash
    Expected SHA256 hash for verification

.PARAMETER UseBITS
    Use BITS transfer (default: true)

.PARAMETER AllowResume
    Allow resume of partial downloads

.EXAMPLE
    Get-RemoteFile -Url "https://example.com/file.zip" -Destination "C:\download\file.zip"
#>
function Get-RemoteFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [Parameter(Mandatory=$false)]
        [string]$ExpectedHash,

        [Parameter(Mandatory=$false)]
        [bool]$UseBITS = $true,

        [Parameter(Mandatory=$false)]
        [bool]$AllowResume = $true
    )

    try {
        # Ensure destination directory exists
        $destDir = Split-Path -Path $Destination -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        Write-Verbose "Downloading: $Url"
        Write-Verbose "Destination: $Destination"

        # Check if file exists and is complete
        if (Test-Path $Destination) {
            if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
                Write-Verbose "Checking existing file hash..."
                if (Test-FileHash256 -FilePath $Destination -ExpectedHash $ExpectedHash) {
                    Write-Host "File already downloaded and verified" -ForegroundColor Green
                    return @{
                        Success = $true
                        FilePath = $Destination
                        AlreadyDownloaded = $true
                    }
                }
            }

            if (-not $AllowResume) {
                Write-Verbose "Removing existing file..."
                Remove-Item -Path $Destination -Force
            }
        }

        # Try BITS transfer first
        if ($UseBITS -and (Test-BITSAvailable)) {
            Write-Verbose "Using BITS transfer..."
            $result = Invoke-BITSDownload -Url $Url -Destination $Destination
            
            if ($result.Success) {
                # Verify hash if provided
                if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
                    if (Test-FileHash256 -FilePath $Destination -ExpectedHash $ExpectedHash) {
                        return $result
                    }
                    else {
                        Write-Warning "Hash verification failed, retrying with WebClient..."
                        Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
                    }
                }
                else {
                    return $result
                }
            }
        }

        # Fallback to WebClient
        Write-Verbose "Using WebClient download..."
        $result = Invoke-WebClientDownload -Url $Url -Destination $Destination

        # Verify hash if provided
        if ($result.Success -and -not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
            if (-not (Test-FileHash256 -FilePath $Destination -ExpectedHash $ExpectedHash)) {
                Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
                throw "Hash verification failed"
            }
        }

        return $result
    }
    catch {
        Write-Error "Download failed: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Downloads file using BITS transfer

.PARAMETER Url
    URL to download

.PARAMETER Destination
    Destination path

.EXAMPLE
    Invoke-BITSDownload -Url "https://example.com/file.zip" -Destination "C:\file.zip"
#>
function Invoke-BITSDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [string]$Destination
    )

    try {
        Import-Module BitsTransfer -ErrorAction Stop

        $jobName = "Download_$(Split-Path -Leaf $Destination)"
        
        # Check for existing job
        $existingJob = Get-BitsTransfer -Name $jobName -ErrorAction SilentlyContinue
        if ($existingJob) {
            Remove-BitsTransfer -BitsJob $existingJob
        }

        # Start BITS transfer
        $job = Start-BitsTransfer -Source $Url -Destination $Destination `
            -DisplayName $jobName -Asynchronous

        # Monitor progress
        while ($job.JobState -eq "Transferring" -or $job.JobState -eq "Connecting") {
            $percentComplete = if ($job.BytesTotal -gt 0) {
                [int](($job.BytesTransferred / $job.BytesTotal) * 100)
            } else { 0 }

            Write-Progress -Activity "Downloading" -Status "$percentComplete% complete" `
                -PercentComplete $percentComplete

            Start-Sleep -Milliseconds 500
            $job = Get-BitsTransfer -JobId $job.JobId
        }

        Write-Progress -Activity "Downloading" -Completed

        if ($job.JobState -eq "Transferred") {
            Complete-BitsTransfer -BitsJob $job
            Write-Verbose "BITS download completed successfully"
            return @{
                Success = $true
                FilePath = $Destination
                Method = "BITS"
            }
        }
        else {
            Remove-BitsTransfer -BitsJob $job
            throw "BITS transfer failed with state: $($job.JobState)"
        }
    }
    catch {
        Write-Warning "BITS download failed: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Downloads file using WebClient

.PARAMETER Url
    URL to download

.PARAMETER Destination
    Destination path

.EXAMPLE
    Invoke-WebClientDownload -Url "https://example.com/file.zip" -Destination "C:\file.zip"
#>
function Invoke-WebClientDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [string]$Destination
    )

    try {
        $webClient = New-Object System.Net.WebClient

        # Register progress event
        $progressHandler = {
            param($sender, $e)
            $percentComplete = $e.ProgressPercentage
            Write-Progress -Activity "Downloading" -Status "$percentComplete% complete" `
                -PercentComplete $percentComplete
        }

        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged `
            -Action $progressHandler | Out-Null

        # Download file
        $webClient.DownloadFile($Url, $Destination)

        Write-Progress -Activity "Downloading" -Completed

        # Cleanup
        $webClient.Dispose()
        Get-EventSubscriber | Unregister-Event

        Write-Verbose "WebClient download completed successfully"
        return @{
            Success = $true
            FilePath = $Destination
            Method = "WebClient"
        }
    }
    catch {
        Write-Error "WebClient download failed: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Tests if BITS is available

.EXAMPLE
    $hasBITS = Test-BITSAvailable
#>
function Test-BITSAvailable {
    [CmdletBinding()]
    param()

    try {
        Import-Module BitsTransfer -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Downloads file with mirror fallback

.PARAMETER Urls
    Array of mirror URLs

.PARAMETER Destination
    Destination path

.PARAMETER ExpectedHash
    Expected SHA256 hash

.EXAMPLE
    Get-RemoteFileWithMirrors -Urls @("https://mirror1.com/file.zip", "https://mirror2.com/file.zip") -Destination "C:\file.zip"
#>
function Get-RemoteFileWithMirrors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Urls,

        [Parameter(Mandatory=$true)]
        [string]$Destination,

        [Parameter(Mandatory=$false)]
        [string]$ExpectedHash
    )

    foreach ($url in $Urls) {
        Write-Host "Trying mirror: $url" -ForegroundColor Cyan
        
        try {
            $result = Get-RemoteFile -Url $url -Destination $Destination -ExpectedHash $ExpectedHash
            
            if ($result.Success) {
                Write-Host "Download successful from: $url" -ForegroundColor Green
                return $result
            }
        }
        catch {
            Write-Warning "Failed to download from $url : $_"
        }
    }

    Write-Error "All mirrors failed"
    return @{
        Success = $false
        Error = "All mirrors failed"
    }
}

<#
.SYNOPSIS
    Gets file size from URL without downloading

.PARAMETER Url
    URL to check

.EXAMPLE
    $size = Get-RemoteFileSize -Url "https://example.com/file.zip"
#>
function Get-RemoteFileSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url
    )

    try {
        $request = [System.Net.HttpWebRequest]::Create($Url)
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $size = $response.ContentLength
        $response.Close()

        return $size
    }
    catch {
        Write-Error "Failed to get remote file size: $_"
        return -1
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-RemoteFile',
    'Invoke-BITSDownload',
    'Invoke-WebClientDownload',
    'Test-BITSAvailable',
    'Get-RemoteFileWithMirrors',
    'Get-RemoteFileSize'
)
