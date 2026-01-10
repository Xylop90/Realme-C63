#Requires -Version 5.1
<#
.SYNOPSIS
    Registry-Management für Realme C63 Installation
    
.DESCRIPTION
    Verwaltet Registry-Einträge für Treiber, USB-Geräte und Sicherheitseinstellungen
    
.NOTES
    Author: Realme C63 Automated Installation System
    Version: 1.0
    Date: 2026-01-10
    Requires: Administrator privileges
#>

# Importiere Logger
. "$PSScriptRoot\logger.ps1"

function Test-RegistryPath {
    <#
    .SYNOPSIS
    Prüft ob Registry-Pfad existiert
    #>
    param([string]$Path)
    
    return Test-Path $Path
}

function New-RegistryPath {
    <#
    .SYNOPSIS
    Erstellt Registry-Pfad wenn nicht vorhanden
    #>
    param([string]$Path)
    
    if (-not (Test-RegistryPath $Path)) {
        try {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            Write-LogDebug "Registry-Pfad erstellt: $Path"
            return $true
        }
        catch {
            Write-LogError "Fehler beim Erstellen des Registry-Pfads: $($_.Exception.Message)"
            return $false
        }
    }
    return $true
}

function Set-RegistryValue {
    <#
    .SYNOPSIS
    Setzt einen Registry-Wert mit Backup
    #>
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "String"
    )
    
    try {
        # Erstelle Backup des alten Werts
        if (Test-Path $Path) {
            $oldValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($oldValue) {
                Write-LogDebug "Backup Registry-Wert: $Path\$Name = $($oldValue.$Name)"
            }
        }
        
        # Erstelle Pfad falls nötig
        New-RegistryPath -Path $Path | Out-Null
        
        # Setze Wert
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-LogDebug "Registry-Wert gesetzt: $Path\$Name = $Value"
        return $true
    }
    catch {
        Write-LogError "Fehler beim Setzen des Registry-Werts: $($_.Exception.Message)"
        return $false
    }
}

function Enable-TestSigning {
    <#
    .SYNOPSIS
    Aktiviert Test-Signing für unsignierte Treiber
    #>
    try {
        Write-LogInfo "Aktiviere Test-Signing-Modus..."
        
        $result = & bcdedit /set testsigning on 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-LogInfo "Test-Signing aktiviert (Neustart erforderlich)"
            return $true
        }
        else {
            Write-LogWarning "Test-Signing konnte nicht aktiviert werden: $result"
            return $false
        }
    }
    catch {
        Write-LogError "Fehler beim Aktivieren von Test-Signing: $($_.Exception.Message)"
        return $false
    }
}

function Disable-TestSigning {
    <#
    .SYNOPSIS
    Deaktiviert Test-Signing
    #>
    try {
        Write-LogInfo "Deaktiviere Test-Signing-Modus..."
        
        $result = & bcdedit /set testsigning off 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-LogInfo "Test-Signing deaktiviert"
            return $true
        }
        else {
            Write-LogWarning "Test-Signing konnte nicht deaktiviert werden: $result"
            return $false
        }
    }
    catch {
        Write-LogError "Fehler beim Deaktivieren von Test-Signing: $($_.Exception.Message)"
        return $false
    }
}

function Set-RealmUSBRegistry {
    <#
    .SYNOPSIS
    Setzt Registry-Einträge für Realme USB-Geräte
    #>
    $registryPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_2207&PID_0006",
        "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_2207&PID_0010",
        "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_1782&PID_4D00"
    )
    
    foreach ($path in $registryPaths) {
        if (New-RegistryPath -Path $path) {
            Write-LogDebug "Realme USB Registry-Pfad vorbereitet: $path"
        }
    }
}

function Add-WindowsDefenderExclusion {
    <#
    .SYNOPSIS
    Fügt Windows Defender Ausnahmen hinzu
    #>
    param([string]$Path)
    
    try {
        Write-LogInfo "Füge Windows Defender Ausnahme hinzu: $Path"
        Add-MpPreference -ExclusionPath $Path -ErrorAction Stop
        Write-LogInfo "Defender-Ausnahme hinzugefügt"
        return $true
    }
    catch {
        Write-LogWarning "Konnte Defender-Ausnahme nicht hinzufügen: $($_.Exception.Message)"
        return $false
    }
}

function Remove-WindowsDefenderExclusion {
    <#
    .SYNOPSIS
    Entfernt Windows Defender Ausnahmen
    #>
    param([string]$Path)
    
    try {
        Write-LogInfo "Entferne Windows Defender Ausnahme: $Path"
        Remove-MpPreference -ExclusionPath $Path -ErrorAction Stop
        Write-LogInfo "Defender-Ausnahme entfernt"
        return $true
    }
    catch {
        Write-LogWarning "Konnte Defender-Ausnahme nicht entfernen: $($_.Exception.Message)"
        return $false
    }
}

function Enable-DeveloperMode {
    <#
    .SYNOPSIS
    Aktiviert Windows Developer Mode
    #>
    try {
        Write-LogInfo "Aktiviere Windows Developer Mode..."
        
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        New-RegistryPath -Path $regPath | Out-Null
        
        Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord
        Set-ItemProperty -Path $regPath -Name "AllowAllTrustedApps" -Value 1 -Type DWord
        
        Write-LogInfo "Developer Mode aktiviert"
        return $true
    }
    catch {
        Write-LogError "Fehler beim Aktivieren des Developer Mode: $($_.Exception.Message)"
        return $false
    }
}

function Add-FirewallRule {
    <#
    .SYNOPSIS
    Fügt Firewall-Regel hinzu
    #>
    param(
        [string]$Name,
        [string]$Program,
        [string]$Direction = "Inbound",
        [string]$Action = "Allow"
    )
    
    try {
        # Prüfe ob Regel bereits existiert
        $existingRule = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
        if ($existingRule) {
            Write-LogDebug "Firewall-Regel existiert bereits: $Name"
            return $true
        }
        
        Write-LogInfo "Erstelle Firewall-Regel: $Name"
        New-NetFirewallRule -DisplayName $Name -Direction $Direction -Program $Program -Action $Action -ErrorAction Stop | Out-Null
        Write-LogInfo "Firewall-Regel erstellt"
        return $true
    }
    catch {
        Write-LogWarning "Konnte Firewall-Regel nicht erstellen: $($_.Exception.Message)"
        return $false
    }
}

function Remove-FirewallRule {
    <#
    .SYNOPSIS
    Entfernt Firewall-Regel
    #>
    param([string]$Name)
    
    try {
        Write-LogInfo "Entferne Firewall-Regel: $Name"
        Remove-NetFirewallRule -DisplayName $Name -ErrorAction Stop
        Write-LogInfo "Firewall-Regel entfernt"
        return $true
    }
    catch {
        Write-LogWarning "Konnte Firewall-Regel nicht entfernen: $($_.Exception.Message)"
        return $false
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Test-RegistryPath',
    'New-RegistryPath',
    'Set-RegistryValue',
    'Enable-TestSigning',
    'Disable-TestSigning',
    'Set-RealmUSBRegistry',
    'Add-WindowsDefenderExclusion',
    'Remove-WindowsDefenderExclusion',
    'Enable-DeveloperMode',
    'Add-FirewallRule',
    'Remove-FirewallRule'
)
