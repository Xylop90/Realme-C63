#Requires -Version 5.1
<#
.SYNOPSIS
    Logging utility module for Realme C63 installation scripts

.DESCRIPTION
    Provides centralized logging functionality with color-coded output,
    timestamp support, and file logging capabilities.

.NOTES
    Author: Realme C63 SPD Flash Tool Automation
    Version: 1.0
#>

# Global log file path (will be set by caller)
$Script:LogFilePath = $null

# Color mapping for different log levels
$Script:LogColors = @{
    "INFO"    = "Cyan"
    "SUCCESS" = "Green"
    "WARN"    = "Yellow"
    "ERROR"   = "Red"
    "DEBUG"   = "Gray"
}

function Initialize-Logger {
    <#
    .SYNOPSIS
        Initialize the logger with a log file path
    
    .PARAMETER LogPath
        Full path to the log file
    
    .PARAMETER CreateDirectory
        Create the directory if it doesn't exist
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath,
        
        [switch]$CreateDirectory
    )
    
    $Script:LogFilePath = $LogPath
    
    if ($CreateDirectory) {
        $logDir = Split-Path -Parent $LogPath
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
    }
    
    # Write initial log entry
    Write-Log "=== Log initialized at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" "INFO"
}

function Write-Log {
    <#
    .SYNOPSIS
        Write a log message with timestamp and level
    
    .PARAMETER Message
        The message to log
    
    .PARAMETER Level
        Log level (INFO, SUCCESS, WARN, ERROR, DEBUG)
    
    .PARAMETER NoConsole
        Don't write to console, only to file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color coding
    if (-not $NoConsole) {
        $color = $Script:LogColors[$Level]
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # Write to log file if path is set
    if ($Script:LogFilePath) {
        try {
            Add-Content -Path $Script:LogFilePath -Value $logEntry -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Failed to write to log file: $_"
        }
    }
}

function Write-LogSection {
    <#
    .SYNOPSIS
        Write a section header to the log
    
    .PARAMETER Title
        Section title
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )
    
    $separator = "=" * 60
    Write-Log $separator "INFO"
    Write-Log $Title "INFO"
    Write-Log $separator "INFO"
}

function Write-LogSubSection {
    <#
    .SYNOPSIS
        Write a subsection header to the log
    
    .PARAMETER Title
        Subsection title
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )
    
    Write-Log "" "INFO"
    Write-Log "--- $Title ---" "INFO"
}

function Write-LogError {
    <#
    .SYNOPSIS
        Write an error message with optional exception details
    
    .PARAMETER Message
        Error message
    
    .PARAMETER Exception
        Exception object to log
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception
    )
    
    Write-Log $Message "ERROR"
    
    if ($Exception) {
        Write-Log "Exception: $($Exception.Message)" "ERROR"
        if ($Exception.StackTrace) {
            Write-Log "Stack Trace: $($Exception.StackTrace)" "DEBUG"
        }
    }
}

function Write-LogProgress {
    <#
    .SYNOPSIS
        Write a progress message with percentage
    
    .PARAMETER Activity
        Activity description
    
    .PARAMETER Status
        Current status
    
    .PARAMETER PercentComplete
        Completion percentage (0-100)
    #>
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    Write-Log "$Activity - $Status ($PercentComplete%)" "INFO" -NoConsole
}

function Get-LogFilePath {
    <#
    .SYNOPSIS
        Get the current log file path
    
    .OUTPUTS
        String containing the log file path
    #>
    return $Script:LogFilePath
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-Log',
    'Write-LogSection',
    'Write-LogSubSection',
    'Write-LogError',
    'Write-LogProgress',
    'Get-LogFilePath'
)
