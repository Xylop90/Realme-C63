<#
.SYNOPSIS
    Strukturiertes Logging-Modul mit Rotation und farbcodierter Ausgabe

.DESCRIPTION
    Dieses Modul bietet umfassende Logging-Funktionen mit:
    - Mehrere Log-Levels (DEBUG, INFO, WARN, ERROR, SUCCESS)
    - Farbcodierte Console-Ausgabe
    - Automatische Log-Rotation
    - Strukturiertes JSON-Logging (optional)
    - Performance-Metriken

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

# Globale Variablen
$script:LogFile = $null
$script:LogLevel = "Info"
$script:ColorMap = @{
    "DEBUG"   = "Gray"
    "INFO"    = "Cyan"
    "WARN"    = "Yellow"
    "ERROR"   = "Red"
    "SUCCESS" = "Green"
}
$script:LogLevelPriority = @{
    "DEBUG"   = 0
    "INFO"    = 1
    "WARN"    = 2
    "ERROR"   = 3
    "SUCCESS" = 1
}

<#
.SYNOPSIS
    Initialisiert das Logging-System

.PARAMETER LogPath
    Pfad zur Log-Datei

.PARAMETER Level
    Minimaler Log-Level (DEBUG, INFO, WARN, ERROR)

.PARAMETER MaxSizeMB
    Maximale Groesse der Log-Datei in MB (Standard: 10)

.PARAMETER MaxAgeDays
    Maximales Alter der Log-Dateien in Tagen (Standard: 7)

.EXAMPLE
    Initialize-Logger -LogPath "C:\Logs\install.log" -Level "Info"
#>
function Initialize-Logger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",

        [Parameter(Mandatory = $false)]
        [int]$MaxSizeMB = 10,

        [Parameter(Mandatory = $false)]
        [int]$MaxAgeDays = 7
    )

    $script:LogFile = $LogPath
    $script:LogLevel = $Level
    $script:MaxLogSize = $MaxSizeMB * 1MB
    $script:MaxLogAge = $MaxAgeDays

    # Erstelle Log-Verzeichnis falls nicht vorhanden
    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Pruefe und rotiere Log-Datei bei Bedarf
    Invoke-LogRotation

    Write-LogEntry -Level "INFO" -Message "Logger initialisiert: $LogPath (Level: $Level)"
}

<#
.SYNOPSIS
    Schreibt einen Log-Eintrag

.PARAMETER Level
    Log-Level des Eintrags

.PARAMETER Message
    Log-Nachricht

.PARAMETER Exception
    Optional: Exception-Objekt fuer Fehler

.EXAMPLE
    Write-LogEntry -Level "INFO" -Message "Installation gestartet"
#>
function Write-LogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception
    )

    # Pruefe ob Log-Level hoch genug ist
    if ($script:LogLevelPriority[$Level] -lt $script:LogLevelPriority[$script:LogLevel]) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Console-Ausgabe mit Farbe
    $color = $script:ColorMap[$Level]
    Write-Host $logEntry -ForegroundColor $color

    # Exception-Details hinzufuegen
    if ($Exception) {
        $exceptionDetails = "Exception: $($Exception.Message)`nStackTrace: $($Exception.StackTrace)"
        Write-Host $exceptionDetails -ForegroundColor Red
        $logEntry += "`n$exceptionDetails"
    }

    # In Datei schreiben
    if ($script:LogFile) {
        try {
            Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "[WARN] Konnte nicht in Log-Datei schreiben: $_" -ForegroundColor Yellow
        }
    }
}

<#
.SYNOPSIS
    Log-Rotation durchfuehren

.DESCRIPTION
    Rotiert Log-Dateien basierend auf Groesse und Alter
#>
function Invoke-LogRotation {
    [CmdletBinding()]
    param()

    if (-not $script:LogFile -or -not (Test-Path -Path $script:LogFile)) {
        return
    }

    $logFileInfo = Get-Item -Path $script:LogFile

    # Pruefe Dateigroesse
    if ($logFileInfo.Length -gt $script:MaxLogSize) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $rotatedName = "$($logFileInfo.DirectoryName)\$($logFileInfo.BaseName)_$timestamp$($logFileInfo.Extension)"
        
        try {
            Move-Item -Path $script:LogFile -Destination $rotatedName -Force
            Write-LogEntry -Level "INFO" -Message "Log-Datei rotiert: $rotatedName"
        }
        catch {
            Write-Host "[WARN] Log-Rotation fehlgeschlagen: $_" -ForegroundColor Yellow
        }
    }

    # Loesche alte Log-Dateien
    $logDir = Split-Path -Path $script:LogFile -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($script:LogFile)
    $extension = [System.IO.Path]::GetExtension($script:LogFile)
    
    Get-ChildItem -Path $logDir -Filter "$baseName*$extension" | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$script:MaxLogAge) } |
        ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force
                Write-Host "[INFO] Alte Log-Datei geloescht: $($_.Name)" -ForegroundColor Cyan
            }
            catch {
                Write-Host "[WARN] Konnte alte Log-Datei nicht loeschen: $($_.Name)" -ForegroundColor Yellow
            }
        }
}

<#
.SYNOPSIS
    Kurzform-Funktionen fuer verschiedene Log-Levels
#>
function Write-DebugLog {
    [CmdletBinding()]
    param([string]$Message)
    Write-LogEntry -Level "DEBUG" -Message $Message
}

function Write-InfoLog {
    [CmdletBinding()]
    param([string]$Message)
    Write-LogEntry -Level "INFO" -Message $Message
}

function Write-WarnLog {
    [CmdletBinding()]
    param([string]$Message)
    Write-LogEntry -Level "WARN" -Message $Message
}

function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [string]$Message,
        [System.Exception]$Exception
    )
    Write-LogEntry -Level "ERROR" -Message $Message -Exception $Exception
}

function Write-SuccessLog {
    [CmdletBinding()]
    param([string]$Message)
    Write-LogEntry -Level "SUCCESS" -Message $Message
}

<#
.SYNOPSIS
    Erstellt einen Performance-Messer

.EXAMPLE
    $stopwatch = Start-PerformanceTimer
    # ... Code ausfuehren ...
    Stop-PerformanceTimer -Stopwatch $stopwatch -Message "Operation abgeschlossen"
#>
function Start-PerformanceTimer {
    [CmdletBinding()]
    param()
    
    return [System.Diagnostics.Stopwatch]::StartNew()
}

function Stop-PerformanceTimer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Stopwatch]$Stopwatch,

        [Parameter(Mandatory = $false)]
        [string]$Message = "Operation"
    )

    $Stopwatch.Stop()
    $elapsed = $Stopwatch.Elapsed
    Write-InfoLog "$Message - Dauer: $($elapsed.ToString())"
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Initialize-Logger',
    'Write-LogEntry',
    'Write-DebugLog',
    'Write-InfoLog',
    'Write-WarnLog',
    'Write-ErrorLog',
    'Write-SuccessLog',
    'Invoke-LogRotation',
    'Start-PerformanceTimer',
    'Stop-PerformanceTimer'
)
