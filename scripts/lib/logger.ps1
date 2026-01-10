#Requires -Version 5.1
<#
.SYNOPSIS
    Logging-Framework für Realme C63 Installation
    
.DESCRIPTION
    Bietet strukturiertes Logging mit verschiedenen Log-Leveln,
    automatischer Log-Rotation und deutscher Sprachunterstützung
    
.NOTES
    Author: Realme C63 Automated Installation System
    Version: 1.0
    Date: 2026-01-10
#>

# Globale Log-Konfiguration
$Script:LogDirectory = "$PSScriptRoot\..\..\logs"
$Script:LogFile = $null
$Script:LogLevel = "INFO"
$Script:LogLevels = @{
    "DEBUG" = 0
    "INFO" = 1
    "WARN" = 2
    "ERROR" = 3
}

function Initialize-Logger {
    <#
    .SYNOPSIS
    Initialisiert das Logging-System
    #>
    param(
        [string]$LogDirectory = "$PSScriptRoot\..\..\logs",
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $Script:LogDirectory = $LogDirectory
    $Script:LogLevel = $Level
    
    # Erstelle Log-Verzeichnis
    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Erstelle Log-Datei mit Timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Script:LogFile = Join-Path $LogDirectory "install-$timestamp.log"
    
    Write-LogMessage "INFO" "=== Logging-System initialisiert ===" -NoConsole
    Write-LogMessage "INFO" "Log-Datei: $Script:LogFile" -NoConsole
    Write-LogMessage "INFO" "Log-Level: $Level" -NoConsole
}

function Write-LogMessage {
    <#
    .SYNOPSIS
    Schreibt eine Log-Nachricht
    #>
    param(
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level,
        [string]$Message,
        [switch]$NoConsole
    )
    
    # Prüfe ob Log-Level erreicht ist
    if ($Script:LogLevels[$Level] -lt $Script:LogLevels[$Script:LogLevel]) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Schreibe in Datei
    if ($Script:LogFile) {
        Add-Content -Path $Script:LogFile -Value $logEntry -Force
    }
    
    # Schreibe auf Konsole mit Farben
    if (-not $NoConsole) {
        $color = switch ($Level) {
            "DEBUG" { "Gray" }
            "INFO" { "Cyan" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
}

function Write-LogDebug {
    param([string]$Message)
    Write-LogMessage -Level "DEBUG" -Message $Message
}

function Write-LogInfo {
    param([string]$Message)
    Write-LogMessage -Level "INFO" -Message $Message
}

function Write-LogWarning {
    param([string]$Message)
    Write-LogMessage -Level "WARN" -Message $Message
}

function Write-LogError {
    param([string]$Message)
    Write-LogMessage -Level "ERROR" -Message $Message
}

function Write-LogSection {
    <#
    .SYNOPSIS
    Schreibt eine Abschnitts-Überschrift
    #>
    param([string]$Title)
    
    $separator = "=" * 80
    Write-LogInfo $separator
    Write-LogInfo $Title
    Write-LogInfo $separator
}

function Export-LogSummary {
    <#
    .SYNOPSIS
    Exportiert eine Log-Zusammenfassung als Markdown
    #>
    param(
        [string]$OutputPath,
        [hashtable]$Summary
    )
    
    $markdown = @"
# Installation Log Summary
**Datum:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Log-Datei:** $Script:LogFile

## Zusammenfassung
"@
    
    foreach ($key in $Summary.Keys) {
        $markdown += "`n- **${key}:** $($Summary[$key])"
    }
    
    $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-LogInfo "Log-Zusammenfassung exportiert: $OutputPath"
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-LogMessage',
    'Write-LogDebug',
    'Write-LogInfo',
    'Write-LogWarning',
    'Write-LogError',
    'Write-LogSection',
    'Export-LogSummary'
)
