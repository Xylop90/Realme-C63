#Requires -Version 5.1

<#
.SYNOPSIS
    Logger module for structured logging (JSON + Console)

.DESCRIPTION
    Provides comprehensive logging capabilities with JSON structured logging,
    colored console output, and multiple log levels.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

# Module-level variables
$script:LogFile = $null
$script:JsonLogFile = $null
$script:LogLevel = "INFO"
$script:ConsoleColors = @{
    DEBUG   = "Gray"
    INFO    = "Cyan"
    OK      = "Green"
    SUCCESS = "Green"
    WARN    = "Yellow"
    WARNING = "Yellow"
    ERROR   = "Red"
    FATAL   = "Magenta"
}

<#
.SYNOPSIS
    Initializes the logging system

.PARAMETER LogDirectory
    Directory where log files will be stored

.PARAMETER LogLevel
    Minimum log level to record (DEBUG, INFO, WARN, ERROR, FATAL)

.EXAMPLE
    Initialize-Logger -LogDirectory "work/logs" -LogLevel "INFO"
#>
function Initialize-Logger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogDirectory,

        [Parameter(Mandatory=$false)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$LogLevel = "INFO"
    )

    try {
        # Create log directory if it doesn't exist
        if (-not (Test-Path $LogDirectory)) {
            New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        }

        # Generate log file names with timestamp
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:LogFile = Join-Path $LogDirectory "installer_$timestamp.log"
        $script:JsonLogFile = Join-Path $LogDirectory "installer_$timestamp.json"
        $script:LogLevel = $LogLevel

        # Initialize JSON log file
        @{
            version = "1.0"
            started = (Get-Date -Format "o")
            entries = @()
        } | ConvertTo-Json | Out-File -FilePath $script:JsonLogFile -Encoding UTF8

        Write-LogEntry -Level "INFO" -Message "Logger initialized" -Data @{
            LogFile = $script:LogFile
            JsonLogFile = $script:JsonLogFile
            LogLevel = $script:LogLevel
        }
    }
    catch {
        Write-Host "[ERROR] Failed to initialize logger: $_" -ForegroundColor Red
        throw
    }
}

<#
.SYNOPSIS
    Writes a log entry

.PARAMETER Level
    Log level (DEBUG, INFO, OK, SUCCESS, WARN, WARNING, ERROR, FATAL)

.PARAMETER Message
    Log message

.PARAMETER Data
    Additional structured data (hashtable)

.EXAMPLE
    Write-LogEntry -Level "INFO" -Message "Device detected" -Data @{Model="RMX3939"}
#>
function Write-LogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("DEBUG", "INFO", "OK", "SUCCESS", "WARN", "WARNING", "ERROR", "FATAL")]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [hashtable]$Data = @{}
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $isoTimestamp = Get-Date -Format "o"

        # Normalize level
        $normalizedLevel = $Level.ToUpper()
        if ($normalizedLevel -eq "OK") { $normalizedLevel = "SUCCESS" }
        if ($normalizedLevel -eq "WARNING") { $normalizedLevel = "WARN" }

        # Check if we should log this level
        $levelPriority = @{
            DEBUG = 0
            INFO = 1
            WARN = 2
            ERROR = 3
            FATAL = 4
        }

        $currentPriority = $levelPriority[$normalizedLevel]
        $minPriority = $levelPriority[$script:LogLevel]

        if ($currentPriority -lt $minPriority) {
            return
        }

        # Console output with color
        $color = $script:ConsoleColors[$Level]
        if (-not $color) { $color = "White" }
        
        $consoleMessage = "[$timestamp] [$Level] $Message"
        Write-Host $consoleMessage -ForegroundColor $color

        # File output
        if ($script:LogFile) {
            $logLine = "[$timestamp] [$normalizedLevel] $Message"
            if ($Data.Count -gt 0) {
                $dataStr = ($Data.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
                $logLine += " | $dataStr"
            }
            Add-Content -Path $script:LogFile -Value $logLine -Encoding UTF8
        }

        # JSON output
        if ($script:JsonLogFile) {
            $jsonEntry = @{
                timestamp = $isoTimestamp
                level = $normalizedLevel
                message = $Message
                data = $Data
            }

            # Append to JSON log
            $logContent = Get-Content -Path $script:JsonLogFile -Raw | ConvertFrom-Json
            $logContent.entries += $jsonEntry
            $logContent | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:JsonLogFile -Encoding UTF8 -Force
        }
    }
    catch {
        Write-Host "[ERROR] Failed to write log entry: $_" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Convenience function for writing log entries

.PARAMETER Message
    Log message

.PARAMETER Level
    Log level (default: INFO)

.PARAMETER Data
    Additional structured data

.EXAMPLE
    Write-Log "Device detected" -Level "INFO"
    Write-Log "Download failed" -Level "ERROR" -Data @{Url="https://example.com"}
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateSet("DEBUG", "INFO", "OK", "SUCCESS", "WARN", "WARNING", "ERROR", "FATAL")]
        [string]$Level = "INFO",

        [Parameter(Mandatory=$false)]
        [hashtable]$Data = @{}
    )

    Write-LogEntry -Level $Level -Message $Message -Data $Data
}

<#
.SYNOPSIS
    Gets the current log file path

.EXAMPLE
    $logPath = Get-LogFilePath
#>
function Get-LogFilePath {
    [CmdletBinding()]
    param()

    return $script:LogFile
}

<#
.SYNOPSIS
    Gets the current JSON log file path

.EXAMPLE
    $jsonLogPath = Get-JsonLogFilePath
#>
function Get-JsonLogFilePath {
    [CmdletBinding()]
    param()

    return $script:JsonLogFile
}

<#
.SYNOPSIS
    Finalizes the logging session

.EXAMPLE
    Close-Logger
#>
function Close-Logger {
    [CmdletBinding()]
    param()

    try {
        Write-LogEntry -Level "INFO" -Message "Logger closing"

        if ($script:JsonLogFile) {
            $logContent = Get-Content -Path $script:JsonLogFile -Raw | ConvertFrom-Json
            $logContent | Add-Member -MemberType NoteProperty -Name "ended" -Value (Get-Date -Format "o") -Force
            $logContent | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:JsonLogFile -Encoding UTF8 -Force
        }
    }
    catch {
        Write-Host "[ERROR] Failed to close logger: $_" -ForegroundColor Red
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-LogEntry',
    'Write-Log',
    'Get-LogFilePath',
    'Get-JsonLogFilePath',
    'Close-Logger'
)
