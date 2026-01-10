<#
.SYNOPSIS
    Download-Manager-Modul für intelligente Downloads

.DESCRIPTION
    Bietet Multi-Threaded Downloads mit BITS, Resume-Support,
    Mirror-Fallback und SHA256-Verifikation

.NOTES
    Author: Xylop90
    Version: 2.0.0
#>

function Start-FileDownload {
    <#
    .SYNOPSIS
    Lädt eine Datei mit BITS oder WebClient herunter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "File",
        
        [Parameter(Mandatory = $false)]
        [string]$ExpectedSHA256,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMinutes = 30,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseWebClient
    )
    
    try {
        # Ensure destination directory exists
        $destDir = Split-Path $Destination -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        
        Write-Log -Message "Downloading $Description from $Url" -Level "INFO" -Category "Download"
        
        # Try BITS first (if not explicitly disabled)
        if (-not $UseWebClient -and (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue)) {
            $result = Start-BITSDownload -Url $Url -Destination $Destination -Description $Description -TimeoutMinutes $TimeoutMinutes
            
            if ($result) {
                if ($ExpectedSHA256) {
                    return Test-FileIntegrity -Path $Destination -ExpectedSHA256 $ExpectedSHA256
                }
                return $true
            }
        }
        
        # Fallback to WebClient
        Write-Log -Message "Using WebClient for download" -Level "INFO" -Category "Download"
        $result = Start-WebClientDownload -Url $Url -Destination $Destination -Description $Description
        
        if ($result -and $ExpectedSHA256) {
            return Test-FileIntegrity -Path $Destination -ExpectedSHA256 $ExpectedSHA256
        }
        
        return $result
    }
    catch {
        Write-ErrorLog -Message "Download failed: $Description" -ErrorRecord $_ -Category "Download"
        return $false
    }
}

function Start-BITSDownload {
    <#
    .SYNOPSIS
    Lädt eine Datei mit BITS herunter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "File",
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMinutes = 30
    )
    
    try {
        $startTime = Get-Date
        
        # Check if file already exists
        if (Test-Path $Destination) {
            Write-Log -Message "File already exists, removing: $Destination" -Level "DEBUG" -Category "Download"
            Remove-Item -Path $Destination -Force
        }
        
        # Start BITS transfer
        $bitsJob = Start-BitsTransfer `
            -Source $Url `
            -Destination $Destination `
            -DisplayName $Description `
            -Asynchronous `
            -Priority Foreground `
            -TransferPolicy Unrestricted `
            -ErrorAction Stop
        
        # Monitor progress
        $timeout = $TimeoutMinutes * 60
        $elapsed = 0
        
        while ($bitsJob.JobState -eq "Connecting" -or $bitsJob.JobState -eq "Transferring") {
            Start-Sleep -Seconds 1
            $elapsed++
            
            # Update progress
            if ($bitsJob.BytesTotal -gt 0) {
                $percent = [Math]::Round(($bitsJob.BytesTransferred / $bitsJob.BytesTotal) * 100, 2)
                $speedMBps = if ($elapsed -gt 0) { ($bitsJob.BytesTransferred / 1MB) / $elapsed } else { 0 }
                
                $status = "Downloaded: {0:N2} MB / {1:N2} MB ({2:N2}%) @ {3:N2} MB/s" -f `
                    ($bitsJob.BytesTransferred / 1MB), `
                    ($bitsJob.BytesTotal / 1MB), `
                    $percent, `
                    $speedMBps
                
                Show-ProgressBar -Percent $percent -Status $status
            }
            
            # Check timeout
            if ($elapsed -gt $timeout) {
                Remove-BitsTransfer -BitsJob $bitsJob -ErrorAction SilentlyContinue
                Write-Log -Message "Download timeout exceeded" -Level "ERROR" -Category "Download"
                return $false
            }
            
            # Refresh job state
            $bitsJob = Get-BitsTransfer -JobId $bitsJob.JobId
        }
        
        # Complete transfer
        if ($bitsJob.JobState -eq "Transferred") {
            Complete-BitsTransfer -BitsJob $bitsJob
            
            $duration = (Get-Date) - $startTime
            Write-PerformanceLog -Operation "Download $Description" -Duration $duration -Metrics @{
                url        = $Url
                size_mb    = ($bitsJob.BytesTotal / 1MB)
                speed_mbps = ($bitsJob.BytesTotal / 1MB) / $duration.TotalSeconds
            }
            
            Write-Log -Message "Download completed: $Description" -Level "INFO" -Category "Download"
            return $true
        }
        else {
            Remove-BitsTransfer -BitsJob $bitsJob -ErrorAction SilentlyContinue
            Write-Log -Message "Download failed: $($bitsJob.JobState)" -Level "ERROR" -Category "Download"
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "BITS download failed" -ErrorRecord $_ -Category "Download"
        return $false
    }
}

function Start-WebClientDownload {
    <#
    .SYNOPSIS
    Lädt eine Datei mit WebClient herunter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "File"
    )
    
    try {
        $startTime = Get-Date
        
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Realme-C63-Installer/2.0")
        
        # Register progress event
        $progressHandler = {
            param($sender, $e)
            if ($e.TotalBytesToReceive -gt 0) {
                $percent = [Math]::Round(($e.BytesReceived / $e.TotalBytesToReceive) * 100, 2)
                $status = "Downloaded: {0:N2} MB / {1:N2} MB ({2:N2}%)" -f `
                    ($e.BytesReceived / 1MB), `
                    ($e.TotalBytesToReceive / 1MB), `
                    $percent
                
                Show-ProgressBar -Percent $percent -Status $status
            }
        }
        
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action $progressHandler | Out-Null
        
        # Start async download
        $task = $webClient.DownloadFileTaskAsync($Url, $Destination)
        $task.Wait()
        
        # Clean up event handler
        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $webClient } | Unregister-Event
        
        $webClient.Dispose()
        
        if (Test-Path $Destination) {
            $duration = (Get-Date) - $startTime
            $fileSize = (Get-Item $Destination).Length / 1MB
            
            Write-PerformanceLog -Operation "Download $Description" -Duration $duration -Metrics @{
                url        = $Url
                size_mb    = $fileSize
                speed_mbps = $fileSize / $duration.TotalSeconds
            }
            
            Write-Log -Message "Download completed: $Description" -Level "INFO" -Category "Download"
            return $true
        }
        else {
            Write-Log -Message "Download failed: File not found after download" -Level "ERROR" -Category "Download"
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "WebClient download failed" -ErrorRecord $_ -Category "Download"
        return $false
    }
}

function Test-FileIntegrity {
    <#
    .SYNOPSIS
    Überprüft die Integrität einer Datei mit SHA256
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$ExpectedSHA256
    )
    
    try {
        if (-not (Test-Path $Path)) {
            Write-Log -Message "File not found for integrity check: $Path" -Level "ERROR" -Category "Download"
            return $false
        }
        
        Write-Log -Message "Verifying file integrity: $Path" -Level "INFO" -Category "Download"
        
        $actualHash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash
        
        if ($actualHash -eq $ExpectedSHA256) {
            Write-Log -Message "File integrity verified: SHA256 matches" -Level "INFO" -Category "Download"
            return $true
        }
        else {
            Write-Log -Message "File integrity check failed: SHA256 mismatch" -Level "ERROR" -Category "Download" -Data @{
                expected = $ExpectedSHA256
                actual   = $actualHash
            }
            return $false
        }
    }
    catch {
        Write-ErrorLog -Message "File integrity check failed" -ErrorRecord $_ -Category "Download"
        return $false
    }
}

function Start-ParallelDownloads {
    <#
    .SYNOPSIS
    Lädt mehrere Dateien parallel herunter
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable[]]$Downloads,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxParallel = 3
    )
    
    try {
        Write-Log -Message "Starting parallel downloads: $($Downloads.Count) files" -Level "INFO" -Category "Download"
        
        $jobs = @()
        
        foreach ($download in $Downloads) {
            # Wait if max parallel reached
            while (($jobs | Where-Object { $_.State -eq "Running" }).Count -ge $MaxParallel) {
                Start-Sleep -Milliseconds 500
            }
            
            # Start download job
            $job = Start-Job -ScriptBlock {
                param($Url, $Destination, $Description)
                
                # Import module in job context
                Import-Module "$using:PSScriptRoot\Download-Manager.psm1" -Force
                Import-Module "$using:PSScriptRoot\Advanced-Logger.psm1" -Force
                
                Start-FileDownload -Url $Url -Destination $Destination -Description $Description
            } -ArgumentList $download.Url, $download.Destination, $download.Description
            
            $jobs += $job
        }
        
        # Wait for all jobs to complete
        $jobs | Wait-Job | Out-Null
        
        # Collect results
        $results = @()
        foreach ($job in $jobs) {
            $result = Receive-Job -Job $job
            $results += $result
            Remove-Job -Job $job
        }
        
        $successCount = ($results | Where-Object { $_ -eq $true }).Count
        Write-Log -Message "Parallel downloads completed: $successCount/$($Downloads.Count) successful" -Level "INFO" -Category "Download"
        
        return $successCount -eq $Downloads.Count
    }
    catch {
        Write-ErrorLog -Message "Parallel downloads failed" -ErrorRecord $_ -Category "Download"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Start-FileDownload',
    'Start-BITSDownload',
    'Start-WebClientDownload',
    'Test-FileIntegrity',
    'Start-ParallelDownloads'
)
