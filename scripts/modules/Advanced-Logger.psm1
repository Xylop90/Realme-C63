<#
.SYNOPSIS
    Advanced-Logger-Modul für strukturiertes Logging

.DESCRIPTION
    Enterprise-Grade Logging mit JSON-Format, Log-Rotation,
    Performance-Tracking und Error-Telemetry

.NOTES
    Author: Xylop90
    Version: 2.0.0
#>

# Global variables
$script:LogFile = $null
$script:SessionId = $null
$script:StartTime = Get-Date
$script:LogLevel = "INFO"
$script:MaxLogSizeMB = 50
$script:LogRetentionDays = 7

function Initialize-Logger {
    <#
    .SYNOPSIS
    Initialisiert den Logger
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "CRITICAL")]
        [string]$MinimumLevel = "INFO"
    )
    
    try {
        # Create log directory if it doesn't exist
        if (-not (Test-Path $LogDirectory)) {
            New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
        }
        
        # Generate session ID
        $script:SessionId = [guid]::NewGuid().ToString()
        
        # Create log file path
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:LogFile = Join-Path $LogDirectory "installer_${timestamp}_${script:SessionId}.log"
        
        # Set log level
        $script:LogLevel = $MinimumLevel
        
        # Write initial log entry
        $initEntry = @{
            timestamp    = (Get-Date).ToString("o")
            level        = "INFO"
            session_id   = $script:SessionId
            message      = "Logger initialized"
            machine_name = $env:COMPUTERNAME
            username     = $env:USERNAME
            ps_version   = $PSVersionTable.PSVersion.ToString()
        }
        
        $initEntry | ConvertTo-Json -Compress | Out-File -FilePath $script:LogFile -Encoding UTF8
        
        # Clean old logs
        Remove-OldLogs -LogDirectory $LogDirectory -RetentionDays $script:LogRetentionDays
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize logger: $_"
        return $false
    }
}

function Write-Log {
    <#
    .SYNOPSIS
    Schreibt einen strukturierten Log-Eintrag
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "CRITICAL")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{}
    )
    
    if (-not $script:LogFile) {
        Write-Warning "Logger not initialized. Call Initialize-Logger first."
        return
    }
    
    # Check log level
    $levels = @{
        "DEBUG"    = 0
        "INFO"     = 1
        "WARN"     = 2
        "ERROR"    = 3
        "CRITICAL" = 4
    }
    
    if ($levels[$Level] -lt $levels[$script:LogLevel]) {
        return
    }
    
    try {
        $logEntry = @{
            timestamp  = (Get-Date).ToString("o")
            level      = $Level
            session_id = $script:SessionId
            category   = $Category
            message    = $Message
        }
        
        # Add additional data if provided
        if ($Data.Count -gt 0) {
            $logEntry["data"] = $Data
        }
        
        # Add stack trace for errors
        if ($Level -in @("ERROR", "CRITICAL")) {
            $logEntry["stack_trace"] = (Get-PSCallStack | Select-Object -Skip 1 | ForEach-Object { $_.Command })
        }
        
        # Write to log file
        $logEntry | ConvertTo-Json -Compress | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
        
        # Also write to console
        $consoleMessage = "[$Level] $Message"
        switch ($Level) {
            "DEBUG" { Write-Verbose $consoleMessage }
            "INFO" { Write-Host $consoleMessage -ForegroundColor Cyan }
            "WARN" { Write-Warning $consoleMessage }
            "ERROR" { Write-Host $consoleMessage -ForegroundColor Red }
            "CRITICAL" { Write-Host $consoleMessage -ForegroundColor Red -BackgroundColor Yellow }
        }
        
        # Check log file size
        $fileSize = (Get-Item $script:LogFile).Length / 1MB
        if ($fileSize -gt $script:MaxLogSizeMB) {
            Rotate-LogFile
        }
    }
    catch {
        Write-Error "Failed to write log entry: $_"
    }
}

function Write-PerformanceLog {
    <#
    .SYNOPSIS
    Schreibt Performance-Metriken in das Log
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        
        [Parameter(Mandatory = $true)]
        [TimeSpan]$Duration,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metrics = @{}
    )
    
    $data = @{
        operation     = $Operation
        duration_ms   = $Duration.TotalMilliseconds
        duration_sec  = $Duration.TotalSeconds
        start_time    = ($script:StartTime).ToString("o")
        execution_time = (Get-Date).ToString("o")
    }
    
    # Merge with additional metrics
    foreach ($key in $Metrics.Keys) {
        $data[$key] = $Metrics[$key]
    }
    
    Write-Log -Message "Performance: $Operation completed in $($Duration.TotalSeconds)s" -Level "INFO" -Category "Performance" -Data $data
}

function Write-ErrorLog {
    <#
    .SYNOPSIS
    Schreibt einen detaillierten Fehler-Log
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General"
    )
    
    $data = @{}
    
    if ($ErrorRecord) {
        $data["error_message"] = $ErrorRecord.Exception.Message
        $data["error_type"] = $ErrorRecord.Exception.GetType().FullName
        $data["error_category"] = $ErrorRecord.CategoryInfo.Category.ToString()
        $data["error_target"] = $ErrorRecord.TargetObject
        $data["script_line"] = $ErrorRecord.InvocationInfo.ScriptLineNumber
        $data["script_file"] = $ErrorRecord.InvocationInfo.ScriptName
    }
    
    Write-Log -Message $Message -Level "ERROR" -Category $Category -Data $data
}

function Rotate-LogFile {
    <#
    .SYNOPSIS
    Rotiert das aktuelle Log-File
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not (Test-Path $script:LogFile)) {
            return
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $directory = Split-Path $script:LogFile -Parent
        $fileName = Split-Path $script:LogFile -Leaf
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        
        $archiveName = "${baseName}_rotated_${timestamp}.log"
        $archivePath = Join-Path $directory $archiveName
        
        # Copy current log to archive
        Copy-Item -Path $script:LogFile -Destination $archivePath -Force
        
        # Clear current log
        Clear-Content -Path $script:LogFile -Force
        
        Write-Log -Message "Log file rotated to: $archiveName" -Level "INFO" -Category "Logger"
        
        # Compress archive (optional)
        if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
            $zipPath = $archivePath -replace '\.log$', '.zip'
            Compress-Archive -Path $archivePath -DestinationPath $zipPath -Force
            Remove-Item -Path $archivePath -Force
        }
    }
    catch {
        Write-Warning "Failed to rotate log file: $_"
    }
}

function Remove-OldLogs {
    <#
    .SYNOPSIS
    Entfernt alte Log-Dateien basierend auf Retention-Policy
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory,
        
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 7
    )
    
    try {
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        
        Get-ChildItem -Path $LogDirectory -Filter "*.log" -File |
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            Remove-Item -Force
        
        Get-ChildItem -Path $LogDirectory -Filter "*.zip" -File |
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            Remove-Item -Force
    }
    catch {
        Write-Warning "Failed to clean old logs: $_"
    }
}

function Get-LogSummary {
    <#
    .SYNOPSIS
    Gibt eine Zusammenfassung der Log-Einträge zurück
    #>
    [CmdletBinding()]
    param()
    
    if (-not (Test-Path $script:LogFile)) {
        return $null
    }
    
    try {
        $entries = Get-Content $script:LogFile | ForEach-Object { $_ | ConvertFrom-Json }
        
        $summary = @{
            session_id     = $script:SessionId
            log_file       = $script:LogFile
            total_entries  = $entries.Count
            debug_count    = ($entries | Where-Object { $_.level -eq "DEBUG" }).Count
            info_count     = ($entries | Where-Object { $_.level -eq "INFO" }).Count
            warn_count     = ($entries | Where-Object { $_.level -eq "WARN" }).Count
            error_count    = ($entries | Where-Object { $_.level -eq "ERROR" }).Count
            critical_count = ($entries | Where-Object { $_.level -eq "CRITICAL" }).Count
            start_time     = $script:StartTime
            duration       = (Get-Date) - $script:StartTime
        }
        
        return $summary
    }
    catch {
        Write-Error "Failed to get log summary: $_"
        return $null
    }
}

function Export-LogReport {
    <#
    .SYNOPSIS
    Exportiert einen detaillierten Log-Report
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    try {
        $summary = Get-LogSummary
        
        if ($null -eq $summary) {
            return $false
        }
        
        $report = @{
            generated_at = (Get-Date).ToString("o")
            summary      = $summary
        }
        
        # Read all log entries
        $entries = Get-Content $script:LogFile | ForEach-Object { $_ | ConvertFrom-Json }
        $report["entries"] = $entries
        
        # Write report
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Log report exported to: $OutputPath" -Level "INFO" -Category "Logger"
        
        return $true
    }
    catch {
        Write-Error "Failed to export log report: $_"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-Log',
    'Write-PerformanceLog',
    'Write-ErrorLog',
    'Rotate-LogFile',
    'Remove-OldLogs',
    'Get-LogSummary',
    'Export-LogReport'
)
