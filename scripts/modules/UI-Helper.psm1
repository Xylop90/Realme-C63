#Requires -Version 5.1

<#
.SYNOPSIS
    UI Helper module for ASCII art, progress bars, and interactive menus

.DESCRIPTION
    Provides user interface utilities including ASCII art banners,
    colored progress bars, interactive menus, and status indicators.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

$script:LocalizationStrings = $null

<#
.SYNOPSIS
    Displays the ASCII art banner

.EXAMPLE
    Show-Banner
#>
function Show-Banner {
    [CmdletBinding()]
    param()

    $banner = @"

╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   ██████╗ ███████╗ █████╗ ██╗     ███╗   ███╗███████╗         ║
║   ██╔══██╗██╔════╝██╔══██╗██║     ████╗ ████║██╔════╝         ║
║   ██████╔╝█████╗  ███████║██║     ██╔████╔██║█████╗           ║
║   ██╔══██╗██╔══╝  ██╔══██║██║     ██║╚██╔╝██║██╔══╝           ║
║   ██║  ██║███████╗██║  ██║███████╗██║ ╚═╝ ██║███████╗         ║
║   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝         ║
║                                                                ║
║              C63 (RMX3939) ULTIMATE INSTALLER v2.0            ║
║          Unlock • Root • TWRP • Firmware • Updates            ║
║                                                                ║
║        Xtreme XA-I KI Elektronikx-Center-Matte Cyber ®        ║
║                    By Alexander Mathey                         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

"@

    Write-Host $banner -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Loads localization strings from JSON file

.PARAMETER Language
    Language code (de or en)

.EXAMPLE
    Initialize-Localization -Language "de"
#>
function Initialize-Localization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("de", "en")]
        [string]$Language = "de"
    )

    try {
        $localizationPath = Join-Path $PSScriptRoot "..\..\config\ui-localization.json"
        if (Test-Path $localizationPath) {
            $locData = Get-Content -Path $localizationPath -Raw | ConvertFrom-Json
            $script:LocalizationStrings = $locData.strings.$Language
        }
    }
    catch {
        Write-Warning "Failed to load localization: $_"
    }
}

<#
.SYNOPSIS
    Gets a localized string

.PARAMETER Key
    String key

.PARAMETER Default
    Default value if key not found

.EXAMPLE
    $msg = Get-LocalizedString -Key "welcome" -Default "Welcome"
#>
function Get-LocalizedString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,

        [Parameter(Mandatory=$false)]
        [string]$Default = ""
    )

    if ($script:LocalizationStrings -and $script:LocalizationStrings.$Key) {
        return $script:LocalizationStrings.$Key
    }
    return $Default
}

<#
.SYNOPSIS
    Displays a colored message

.PARAMETER Message
    Message to display

.PARAMETER Type
    Message type (INFO, SUCCESS, WARNING, ERROR)

.EXAMPLE
    Show-Message "Device detected" -Type "SUCCESS"
#>
function Show-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "PROMPT")]
        [string]$Type = "INFO"
    )

    $colors = @{
        INFO    = "Cyan"
        SUCCESS = "Green"
        WARNING = "Yellow"
        ERROR   = "Red"
        PROMPT  = "Magenta"
    }

    $icons = @{
        INFO    = "[i]"
        SUCCESS = "[✓]"
        WARNING = "[!]"
        ERROR   = "[✗]"
        PROMPT  = "[?]"
    }

    $color = $colors[$Type]
    $icon = $icons[$Type]

    Write-Host "$icon $Message" -ForegroundColor $color
}

<#
.SYNOPSIS
    Displays a progress bar

.PARAMETER Activity
    Activity description

.PARAMETER Status
    Current status

.PARAMETER PercentComplete
    Percentage complete (0-100)

.PARAMETER SecondsRemaining
    Estimated seconds remaining

.EXAMPLE
    Show-ProgressBar -Activity "Downloading" -Status "Magisk APK" -PercentComplete 45 -SecondsRemaining 30
#>
function Show-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Activity,

        [Parameter(Mandatory=$true)]
        [string]$Status,

        [Parameter(Mandatory=$true)]
        [ValidateRange(0, 100)]
        [int]$PercentComplete,

        [Parameter(Mandatory=$false)]
        [int]$SecondsRemaining = -1
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete -SecondsRemaining $SecondsRemaining
}

<#
.SYNOPSIS
    Clears the progress bar

.EXAMPLE
    Clear-ProgressBar
#>
function Clear-ProgressBar {
    [CmdletBinding()]
    param()

    Write-Progress -Activity "Completed" -Completed
}

<#
.SYNOPSIS
    Displays an interactive menu and returns the selected option

.PARAMETER Title
    Menu title

.PARAMETER Options
    Array of menu options

.PARAMETER AllowCancel
    Allow cancel option

.EXAMPLE
    $choice = Show-Menu -Title "Select Action" -Options @("Unlock Bootloader", "Root Device", "Flash Firmware")
#>
function Show-Menu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string[]]$Options,

        [Parameter(Mandatory=$false)]
        [switch]$AllowCancel
    )

    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Title" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Options[$i])" -ForegroundColor White
    }

    if ($AllowCancel) {
        Write-Host "  [0] Cancel / Exit" -ForegroundColor Yellow
    }

    Write-Host ""
    
    do {
        $selection = Read-Host "Select option"
        $valid = $false

        if ($selection -match '^\d+$') {
            $num = [int]$selection
            if ($AllowCancel -and $num -eq 0) {
                return -1
            }
            if ($num -ge 1 -and $num -le $Options.Count) {
                $valid = $true
                return $num - 1
            }
        }

        if (-not $valid) {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        }
    } while (-not $valid)
}

<#
.SYNOPSIS
    Prompts for confirmation

.PARAMETER Message
    Confirmation message

.PARAMETER DefaultYes
    Default to Yes if user presses Enter

.EXAMPLE
    $confirmed = Show-Confirmation "Proceed with unlock?" -DefaultYes
#>
function Show-Confirmation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [switch]$DefaultYes
    )

    $prompt = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    
    Write-Host "$Message $prompt " -ForegroundColor Magenta -NoNewline
    $response = Read-Host

    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes.IsPresent
    }

    return $response -match '^[yY]'
}

<#
.SYNOPSIS
    Displays a separator line

.PARAMETER Character
    Character to use for separator

.PARAMETER Length
    Length of separator

.PARAMETER Color
    Color of separator

.EXAMPLE
    Show-Separator
    Show-Separator -Character "=" -Length 80 -Color "Yellow"
#>
function Show-Separator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Character = "─",

        [Parameter(Mandatory=$false)]
        [int]$Length = 64,

        [Parameter(Mandatory=$false)]
        [string]$Color = "Cyan"
    )

    Write-Host ($Character * $Length) -ForegroundColor $Color
}

<#
.SYNOPSIS
    Displays a box around text

.PARAMETER Text
    Text to display in box

.PARAMETER Color
    Box color

.EXAMPLE
    Show-Box "Important Message"
#>
function Show-Box {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,

        [Parameter(Mandatory=$false)]
        [string]$Color = "Yellow"
    )

    $length = $Text.Length + 4
    $border = "═" * $length

    Write-Host "╔$border╗" -ForegroundColor $Color
    Write-Host "║  $Text  ║" -ForegroundColor $Color
    Write-Host "╚$border╝" -ForegroundColor $Color
}

<#
.SYNOPSIS
    Waits for user to press any key

.PARAMETER Message
    Message to display

.EXAMPLE
    Wait-ForKeyPress
#>
function Wait-ForKeyPress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Message = "Press any key to continue..."
    )

    Write-Host "`n$Message" -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Export module functions
Export-ModuleMember -Function @(
    'Show-Banner',
    'Initialize-Localization',
    'Get-LocalizedString',
    'Show-Message',
    'Show-ProgressBar',
    'Clear-ProgressBar',
    'Show-Menu',
    'Show-Confirmation',
    'Show-Separator',
    'Show-Box',
    'Wait-ForKeyPress'
)
