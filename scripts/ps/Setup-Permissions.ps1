<#
.SYNOPSIS
    Setup-Permissions - Verwaltet Berechtigungen und Sicherheitseinstellungen

.DESCRIPTION
    Funktionen für:
    - UAC-Elevation
    - ExecutionPolicy temporär setzen
    - Windows Defender Ausnahmen
    - Firewall-Regeln (temporär)

.EXAMPLE
    .\Setup-Permissions.ps1

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
    Requires: Administrator
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$AddDefenderExclusion,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveDefenderExclusion,

    [Parameter(Mandatory = $false)]
    [string]$ExclusionPath = ""
)

# ============================================================================
# ADMINISTRATOR-RECHTE PRÜFEN
# ============================================================================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "[FEHLER] Dieses Skript erfordert Administrator-Rechte!" -ForegroundColor Red
    Write-Host "[INFO] Bitte als Administrator ausführen" -ForegroundColor Yellow
    exit 1
}

# ============================================================================
# EXECUTIONPOLICY MANAGEMENT
# ============================================================================

function Set-TemporaryExecutionPolicy {
    [CmdletBinding()]
    param()

    try {
        $currentPolicy = Get-ExecutionPolicy -Scope Process
        Write-Host "[INFO] Aktuelle ExecutionPolicy (Process): $currentPolicy" -ForegroundColor Cyan

        if ($currentPolicy -ne "Bypass" -and $currentPolicy -ne "Unrestricted") {
            Write-Host "[*] Setze temporäre ExecutionPolicy auf Bypass..." -ForegroundColor Cyan
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
            Write-Host "[OK] ExecutionPolicy temporär auf Bypass gesetzt" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[OK] ExecutionPolicy bereits ausreichend permissiv" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "[FEHLER] Konnte ExecutionPolicy nicht setzen: $_" -ForegroundColor Red
        return $false
    }
}

function Get-CurrentExecutionPolicy {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "ExecutionPolicy Status:" -ForegroundColor Cyan
    Write-Host "  MachinePolicy: $(Get-ExecutionPolicy -Scope MachinePolicy)" -ForegroundColor Gray
    Write-Host "  UserPolicy:    $(Get-ExecutionPolicy -Scope UserPolicy)" -ForegroundColor Gray
    Write-Host "  Process:       $(Get-ExecutionPolicy -Scope Process)" -ForegroundColor Gray
    Write-Host "  CurrentUser:   $(Get-ExecutionPolicy -Scope CurrentUser)" -ForegroundColor Gray
    Write-Host "  LocalMachine:  $(Get-ExecutionPolicy -Scope LocalMachine)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# WINDOWS DEFENDER AUSNAHMEN
# ============================================================================

function Add-DefenderExclusion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        Write-Host "[*] Füge Windows Defender Ausnahme hinzu: $Path" -ForegroundColor Cyan

        # Prüfe ob Windows Defender läuft
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if (-not $defenderStatus) {
            Write-Host "[INFO] Windows Defender nicht verfügbar oder deaktiviert" -ForegroundColor Yellow
            return $true
        }

        # Füge Ausnahme hinzu
        Add-MpPreference -ExclusionPath $Path -ErrorAction Stop
        Write-Host "[OK] Windows Defender Ausnahme hinzugefügt" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[WARNUNG] Konnte Windows Defender Ausnahme nicht hinzufügen: $_" -ForegroundColor Yellow
        return $false
    }
}

function Remove-DefenderExclusion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        Write-Host "[*] Entferne Windows Defender Ausnahme: $Path" -ForegroundColor Cyan

        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if (-not $defenderStatus) {
            Write-Host "[INFO] Windows Defender nicht verfügbar oder deaktiviert" -ForegroundColor Yellow
            return $true
        }

        Remove-MpPreference -ExclusionPath $Path -ErrorAction Stop
        Write-Host "[OK] Windows Defender Ausnahme entfernt" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[WARNUNG] Konnte Windows Defender Ausnahme nicht entfernen: $_" -ForegroundColor Yellow
        return $false
    }
}

function Get-DefenderExclusions {
    [CmdletBinding()]
    param()

    try {
        $preferences = Get-MpPreference -ErrorAction SilentlyContinue
        
        if ($preferences) {
            Write-Host ""
            Write-Host "Windows Defender Ausnahmen:" -ForegroundColor Cyan
            
            if ($preferences.ExclusionPath) {
                foreach ($path in $preferences.ExclusionPath) {
                    Write-Host "  - $path" -ForegroundColor Gray
                }
            }
            else {
                Write-Host "  Keine Pfad-Ausnahmen konfiguriert" -ForegroundColor Gray
            }
            Write-Host ""
        }
    }
    catch {
        Write-Host "[INFO] Konnte Windows Defender Einstellungen nicht abrufen" -ForegroundColor Yellow
    }
}

# ============================================================================
# DRIVER SIGNING POLICY
# ============================================================================

function Get-DriverSigningPolicy {
    [CmdletBinding()]
    param()

    try {
        Write-Host ""
        Write-Host "Driver Signing Policy:" -ForegroundColor Cyan

        # Lese Registry-Wert
        $policyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        if (Test-Path $policyPath) {
            $policy = Get-ItemProperty -Path $policyPath -ErrorAction SilentlyContinue
            
            if ($policy) {
                Write-Host "  UpgradedSystem: $($policy.UpgradedSystem)" -ForegroundColor Gray
                Write-Host "  VerifiedAndReputablePolicyState: $($policy.VerifiedAndReputablePolicyState)" -ForegroundColor Gray
            }
        }

        # Test Mode Status
        $testMode = bcdedit /enum | Select-String "testsigning"
        if ($testMode) {
            Write-Host "  Test Signing: $testMode" -ForegroundColor Gray
        }
        else {
            Write-Host "  Test Signing: Nicht aktiviert" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    catch {
        Write-Host "[INFO] Konnte Driver Signing Policy nicht abrufen" -ForegroundColor Yellow
    }
}

# ============================================================================
# SYSTEM-INFORMATIONEN
# ============================================================================

function Show-SystemInfo {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "                    System-Informationen                                    " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Windows-Version
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Host "Windows:" -ForegroundColor Yellow
    Write-Host "  Version: $($os.Caption)" -ForegroundColor White
    Write-Host "  Build: $($os.BuildNumber)" -ForegroundColor White
    Write-Host "  Architektur: $($os.OSArchitecture)" -ForegroundColor White
    Write-Host ""

    # PowerShell-Version
    Write-Host "PowerShell:" -ForegroundColor Yellow
    Write-Host "  Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "  Edition: $($PSVersionTable.PSEdition)" -ForegroundColor White
    Write-Host ""

    # Benutzer
    Write-Host "Benutzer:" -ForegroundColor Yellow
    Write-Host "  Name: $env:USERNAME" -ForegroundColor White
    Write-Host "  Computer: $env:COMPUTERNAME" -ForegroundColor White
    Write-Host "  Administrator: $(Test-Administrator)" -ForegroundColor White
    Write-Host ""

    # ExecutionPolicy
    Get-CurrentExecutionPolicy

    # Defender Exclusions
    Get-DefenderExclusions

    # Driver Signing
    Get-DriverSigningPolicy

    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# HAUPTFUNKTION
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "              Setup-Permissions - Berechtigungs-Manager                     " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    # System-Info anzeigen
    Show-SystemInfo

    # ExecutionPolicy setzen
    Set-TemporaryExecutionPolicy | Out-Null

    # Windows Defender Ausnahme
    if ($AddDefenderExclusion -and $ExclusionPath) {
        Add-DefenderExclusion -Path $ExclusionPath | Out-Null
    }

    if ($RemoveDefenderExclusion -and $ExclusionPath) {
        Remove-DefenderExclusion -Path $ExclusionPath | Out-Null
    }

    Write-Host ""
    Write-Host "[OK] Setup-Permissions abgeschlossen" -ForegroundColor Green
    Write-Host ""
}

Main
