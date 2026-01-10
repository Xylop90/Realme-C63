<#
.SYNOPSIS
    UI-Helper-Modul für erweiterte Console-Ausgaben

.DESCRIPTION
    Bietet Funktionen für professionelle Console-UI mit ASCII-Art,
    Progress-Bars, Color-Coding und interaktiven Menüs

.NOTES
    Author: Xylop90
    Version: 2.0.0
#>

# Farb-Definitions
$script:Colors = @{
    Header    = "Cyan"
    Success   = "Green"
    Warning   = "Yellow"
    Error     = "Red"
    Important = "Magenta"
    Info      = "White"
    Progress  = "Blue"
}

function Write-ColoredOutput {
    <#
    .SYNOPSIS
    Schreibt farbige Ausgaben in die Console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Header", "Success", "Warning", "Error", "Important", "Info", "Progress")]
        [string]$Type = "Info",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNewline
    )
    
    $color = $script:Colors[$Type]
    
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $color -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $color
    }
}

function Show-ASCIIBanner {
    <#
    .SYNOPSIS
    Zeigt den Haupt-Banner an
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-ColoredOutput -Message "" -Type Header
    Write-ColoredOutput -Message "╔═══════════════════════════════════════════════════════════════════════╗" -Type Header
    Write-ColoredOutput -Message "║                                                                       ║" -Type Header
    Write-ColoredOutput -Message "║     🚀 REALME C63 ULTIMATE AUTO-INSTALLER v2.0 🚀                    ║" -Type Header
    Write-ColoredOutput -Message "║                                                                       ║" -Type Header
    Write-ColoredOutput -Message "║     KI-gestützter Vollautomatischer Installations-Assistent          ║" -Type Header
    Write-ColoredOutput -Message "║                                                                       ║" -Type Header
    Write-ColoredOutput -Message "╚═══════════════════════════════════════════════════════════════════════╝" -Type Header
    Write-ColoredOutput -Message "" -Type Header
}

function Show-StepBanner {
    <#
    .SYNOPSIS
    Zeigt einen Schritt-Banner an
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Step,
        
        [Parameter(Mandatory = $true)]
        [string]$Description
    )
    
    Write-Host ""
    Write-ColoredOutput -Message "╔═══════════════════════════════════════════════════════════════════════╗" -Type Header
    Write-ColoredOutput -Message "║  $Step" -Type Header
    Write-ColoredOutput -Message "║  $Description" -Type Info
    Write-ColoredOutput -Message "╚═══════════════════════════════════════════════════════════════════════╝" -Type Header
    Write-Host ""
}

function Show-ProgressBar {
    <#
    .SYNOPSIS
    Zeigt eine Progress-Bar mit Prozentsatz und ETA an
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Percent,
        
        [Parameter(Mandatory = $false)]
        [string]$Status = "",
        
        [Parameter(Mandatory = $false)]
        [int]$BarLength = 50
    )
    
    $filled = [Math]::Floor($BarLength * $Percent / 100)
    $empty = $BarLength - $filled
    
    $bar = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    
    Write-Host "`r$bar $Percent% $Status" -NoNewline -ForegroundColor Cyan
    
    if ($Percent -ge 100) {
        Write-Host ""
    }
}

function Show-Menu {
    <#
    .SYNOPSIS
    Zeigt ein interaktives Menü an und gibt die Auswahl zurück
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Options,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Bitte wählen Sie eine Option:",
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultIndex = 0
    )
    
    Write-Host ""
    Write-ColoredOutput -Message $Title -Type Header
    Write-Host ""
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $prefix = "  $($i + 1)."
        if ($i -eq $DefaultIndex) {
            Write-ColoredOutput -Message "$prefix $($Options[$i]) (Standard)" -Type Important
        }
        else {
            Write-ColoredOutput -Message "$prefix $($Options[$i])" -Type Info
        }
    }
    
    Write-Host ""
    
    do {
        $selection = Read-Host "Ihre Auswahl (1-$($Options.Count))"
        
        if ([string]::IsNullOrWhiteSpace($selection)) {
            return $DefaultIndex
        }
        
        $index = $selection -as [int]
        
        if ($index -ge 1 -and $index -le $Options.Count) {
            return ($index - 1)
        }
        
        Write-ColoredOutput -Message "Ungültige Auswahl. Bitte versuchen Sie es erneut." -Type Warning
    } while ($true)
}

function Show-Confirmation {
    <#
    .SYNOPSIS
    Zeigt eine Bestätigungs-Abfrage an
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [bool]$DefaultYes = $false
    )
    
    $defaultOption = if ($DefaultYes) { "[J/n]" } else { "[j/N]" }
    
    Write-Host ""
    $response = Read-Host "$Message $defaultOption"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    
    return $response -match '^[jJyY]'
}

function Show-StatusMessage {
    <#
    .SYNOPSIS
    Zeigt eine Status-Nachricht mit Icon an
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Processing", "Success", "Error", "Warning", "Info", "Complete")]
        [string]$Status = "Info"
    )
    
    $icons = @{
        Processing = "⏳"
        Success    = "✓"
        Error      = "✗"
        Warning    = "⚠"
        Info       = "ℹ"
        Complete   = "✓"
    }
    
    $types = @{
        Processing = "Progress"
        Success    = "Success"
        Error      = "Error"
        Warning    = "Warning"
        Info       = "Info"
        Complete   = "Success"
    }
    
    $icon = $icons[$Status]
    $type = $types[$Status]
    
    Write-ColoredOutput -Message "[$icon] $Message" -Type $type
}

function Show-InstallationProgress {
    <#
    .SYNOPSIS
    Zeigt einen Installations-Fortschritts-Bildschirm an
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Steps
    )
    
    Write-Host ""
    Write-ColoredOutput -Message "╔═══════════════════════════════════════════════════════════════════════╗" -Type Header
    Write-ColoredOutput -Message "║                    INSTALLATIONS-FORTSCHRITT                          ║" -Type Header
    Write-ColoredOutput -Message "╠═══════════════════════════════════════════════════════════════════════╣" -Type Header
    
    foreach ($step in $Steps.GetEnumerator() | Sort-Object Name) {
        $status = $step.Value
        $name = $step.Key
        
        $icon = switch ($status) {
            "Complete" { "✓"; Break }
            "InProgress" { "⏳"; Break }
            "Pending" { " "; Break }
            "Skipped" { "⊘"; Break }
            default { " " }
        }
        
        $color = switch ($status) {
            "Complete" { "Success"; Break }
            "InProgress" { "Progress"; Break }
            "Pending" { "Info"; Break }
            "Skipped" { "Warning"; Break }
            default { "Info" }
        }
        
        $line = "║  [$icon] $name"
        $padding = 70 - $line.Length
        $line += (" " * $padding) + "║"
        
        Write-ColoredOutput -Message $line -Type $color
    }
    
    Write-ColoredOutput -Message "╚═══════════════════════════════════════════════════════════════════════╝" -Type Header
    Write-Host ""
}

function Show-ErrorBox {
    <#
    .SYNOPSIS
    Zeigt eine Fehler-Box an
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Details
    )
    
    Write-Host ""
    Write-ColoredOutput -Message "╔═══════════════════════════════════════════════════════════════════════╗" -Type Error
    Write-ColoredOutput -Message "║  ❌ $Title" -Type Error
    Write-ColoredOutput -Message "╠═══════════════════════════════════════════════════════════════════════╣" -Type Error
    Write-ColoredOutput -Message "║  $Message" -Type Error
    
    if ($Details) {
        Write-ColoredOutput -Message "║" -Type Error
        foreach ($detail in $Details) {
            Write-ColoredOutput -Message "║  • $detail" -Type Warning
        }
    }
    
    Write-ColoredOutput -Message "╚═══════════════════════════════════════════════════════════════════════╝" -Type Error
    Write-Host ""
}

function Show-WarningBox {
    <#
    .SYNOPSIS
    Zeigt eine Warn-Box an
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Warnings
    )
    
    Write-Host ""
    Write-ColoredOutput -Message "╔═══════════════════════════════════════════════════════════════════════╗" -Type Warning
    Write-ColoredOutput -Message "║  ⚠️  $Title" -Type Warning
    Write-ColoredOutput -Message "╠═══════════════════════════════════════════════════════════════════════╣" -Type Warning
    
    foreach ($warning in $Warnings) {
        Write-ColoredOutput -Message "║  • $warning" -Type Warning
    }
    
    Write-ColoredOutput -Message "╚═══════════════════════════════════════════════════════════════════════╝" -Type Warning
    Write-Host ""
}

function Start-Countdown {
    <#
    .SYNOPSIS
    Startet einen Countdown
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Seconds,
        
        [Parameter(Mandatory = $false)]
        [string]$Message = "Fortfahren in"
    )
    
    for ($i = $Seconds; $i -gt 0; $i--) {
        Write-Host "`r$Message $i Sekunden... " -NoNewline -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    Write-Host "`r$(' ' * 80)`r" -NoNewline
}

# Export functions
Export-ModuleMember -Function @(
    'Write-ColoredOutput',
    'Show-ASCIIBanner',
    'Show-StepBanner',
    'Show-ProgressBar',
    'Show-Menu',
    'Show-Confirmation',
    'Show-StatusMessage',
    'Show-InstallationProgress',
    'Show-ErrorBox',
    'Show-WarningBox',
    'Start-Countdown'
)
