<#
.SYNOPSIS
    UI-Helper Modul fuer ASCII-Art und Progress-Anzeigen

.DESCRIPTION
    Stellt UI-Funktionen bereit:
    - ASCII-Art Banner
    - Progress-Bars
    - Farbcodierte Ausgaben
    - Formatierte Tabellen

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

<#
.SYNOPSIS
    Zeigt einen formatierten Progress-Bar an

.PARAMETER Current
    Aktueller Wert

.PARAMETER Total
    Gesamt-Wert

.PARAMETER Label
    Beschreibungs-Label

.EXAMPLE
    Show-ProgressBar -Current 50 -Total 100 -Label "Download"
#>
function Show-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Current,

        [Parameter(Mandatory = $true)]
        [int]$Total,

        [Parameter(Mandatory = $false)]
        [string]$Label = "Progress"
    )

    $percent = [math]::Round(($Current / $Total) * 100, 0)
    $barLength = 50
    $filledLength = [math]::Round(($percent / 100) * $barLength)
    
    $bar = "[" + ("=" * $filledLength) + (" " * ($barLength - $filledLength)) + "]"
    
    Write-Host "`r$Label $bar $percent% ($Current/$Total)" -NoNewline -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Zeigt einen Spinner fuer laufende Operationen

.PARAMETER Message
    Nachricht die angezeigt werden soll

.EXAMPLE
    Show-Spinner -Message "Verarbeite Daten..."
#>
function Show-Spinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Message = "Verarbeite..."
    )

    $spinChars = @('|', '/', '-', '\')
    $index = (Get-Date).Millisecond % 4
    Write-Host "`r$Message $($spinChars[$index])" -NoNewline -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Zeigt eine formatierte Box mit Text

.PARAMETER Text
    Text innerhalb der Box

.PARAMETER Type
    Box-Typ (Info, Success, Warning, Error)

.EXAMPLE
    Show-TextBox -Text "Installation erfolgreich!" -Type Success
#>
function Show-TextBox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )

    $colorMap = @{
        "Info"    = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error"   = "Red"
    }

    $color = $colorMap[$Type]
    $width = $Text.Length + 4
    $border = "=" * $width

    Write-Host ""
    Write-Host $border -ForegroundColor $color
    Write-Host "  $Text  " -ForegroundColor $color
    Write-Host $border -ForegroundColor $color
    Write-Host ""
}

<#
.SYNOPSIS
    Zeigt eine formatierte Liste mit Checkboxen

.PARAMETER Items
    Array von Items mit Name und Status (Completed)

.EXAMPLE
    $items = @(
        @{Name="Download"; Completed=$true},
        @{Name="Installation"; Completed=$false}
    )
    Show-CheckList -Items $items
#>
function Show-CheckList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Items
    )

    Write-Host ""
    foreach ($item in $Items) {
        $checkbox = if ($item.Completed) { "[X]" } else { "[ ]" }
        $color = if ($item.Completed) { "Green" } else { "Gray" }
        Write-Host "$checkbox $($item.Name)" -ForegroundColor $color
    }
    Write-Host ""
}

<#
.SYNOPSIS
    ASCII-Art Logo

.EXAMPLE
    Show-Logo
#>
function Show-Logo {
    Write-Host ""
    Write-Host "   ____            _                    ____ __________  " -ForegroundColor Cyan
    Write-Host "  / __ \___  ___ _/ /_ _  ___   ___   / __// /__  / _ ) " -ForegroundColor Cyan
    Write-Host " / /_/ / -_)/ _ ``/ /  ' \/ -_) / __/ / /_ / _ \/ _ / _ \ " -ForegroundColor Cyan
    Write-Host " \____/\__/ \_,_/_/_/_/_/\__/  \__/  \__//_//_/____/___/ " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "         Vollautomatische Installation fuer Realme C63  " -ForegroundColor White
    Write-Host ""
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Show-ProgressBar',
    'Show-Spinner',
    'Show-TextBox',
    'Show-CheckList',
    'Show-Logo'
)
