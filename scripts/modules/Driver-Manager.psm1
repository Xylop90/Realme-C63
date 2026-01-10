<#
.SYNOPSIS
    Driver-Manager fuer Silent-Installation von USB-Treibern

.DESCRIPTION
    Funktionen fuer:
    - Silent-Installation verschiedener Driver-Formate
    - PNPUtil-Integration
    - Driver-Verification
    - Rollback-Funktionen

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

# Lade Logger wenn verfuegbar
$modulePath = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $modulePath "modules\Logger.psm1") -Force -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Installiert Treiber im Silent-Modus

.PARAMETER DriverPath
    Pfad zum Treiber (.inf, .exe, .msi)

.PARAMETER Silent
    Silent-Installation aktivieren

.EXAMPLE
    Install-Driver -DriverPath "C:\Drivers\driver.inf" -Silent
#>
function Install-Driver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriverPath,

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    if (-not (Test-Path -Path $DriverPath)) {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Treiber-Datei nicht gefunden: $DriverPath"
        }
        return $false
    }

    $extension = [System.IO.Path]::GetExtension($DriverPath).ToLower()

    try {
        switch ($extension) {
            ".inf" {
                return Install-INFDriver -DriverPath $DriverPath
            }
            ".exe" {
                return Install-EXEDriver -DriverPath $DriverPath -Silent:$Silent
            }
            ".msi" {
                return Install-MSIDriver -DriverPath $DriverPath -Silent:$Silent
            }
            default {
                if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
                    Write-ErrorLog "Nicht unterstuetztes Treiber-Format: $extension"
                }
                return $false
            }
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei Treiber-Installation: $_" -Exception $_.Exception
        }
        return $false
    }
}

<#
.SYNOPSIS
    Installiert INF-Treiber mit PNPUtil

.PARAMETER DriverPath
    Pfad zur .inf-Datei

.EXAMPLE
    Install-INFDriver -DriverPath "C:\Drivers\driver.inf"
#>
function Install-INFDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriverPath
    )

    try {
        if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
            Write-InfoLog "Installiere INF-Treiber: $(Split-Path -Path $DriverPath -Leaf)"
        }

        # Verwende pnputil.exe fuer Installation
        $result = & pnputil.exe /add-driver $DriverPath /install 2>&1

        if ($LASTEXITCODE -eq 0) {
            if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                Write-SuccessLog "Treiber erfolgreich installiert"
            }
            return $true
        }
        else {
            if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
                Write-ErrorLog "pnputil.exe fehlgeschlagen (Exit: $LASTEXITCODE): $result"
            }
            return $false
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei INF-Treiber-Installation: $_" -Exception $_.Exception
        }
        return $false
    }
}

<#
.SYNOPSIS
    Installiert EXE-Treiber im Silent-Modus

.PARAMETER DriverPath
    Pfad zur .exe-Datei

.PARAMETER Silent
    Silent-Installation

.EXAMPLE
    Install-EXEDriver -DriverPath "C:\Drivers\setup.exe" -Silent
#>
function Install-EXEDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriverPath,

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    try {
        if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
            Write-InfoLog "Installiere EXE-Treiber: $(Split-Path -Path $DriverPath -Leaf)"
        }

        # Versuche verschiedene Silent-Parameter
        $silentArgs = @("/S", "/silent", "/quiet", "/qn")
        
        if ($Silent) {
            foreach ($arg in $silentArgs) {
                try {
                    $process = Start-Process -FilePath $DriverPath -ArgumentList $arg -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -eq 0) {
                        if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                            Write-SuccessLog "Treiber erfolgreich installiert (Silent: $arg)"
                        }
                        return $true
                    }
                }
                catch {
                    # Versuche naechsten Parameter
                    continue
                }
            }
        }
        else {
            $process = Start-Process -FilePath $DriverPath -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                    Write-SuccessLog "Treiber erfolgreich installiert"
                }
                return $true
            }
        }

        if (Get-Command Write-WarnLog -ErrorAction SilentlyContinue) {
            Write-WarnLog "Treiber-Installation eventuell fehlgeschlagen"
        }
        return $false
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei EXE-Treiber-Installation: $_" -Exception $_.Exception
        }
        return $false
    }
}

<#
.SYNOPSIS
    Installiert MSI-Treiber im Silent-Modus

.PARAMETER DriverPath
    Pfad zur .msi-Datei

.PARAMETER Silent
    Silent-Installation

.EXAMPLE
    Install-MSIDriver -DriverPath "C:\Drivers\driver.msi" -Silent
#>
function Install-MSIDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriverPath,

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    try {
        if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
            Write-InfoLog "Installiere MSI-Treiber: $(Split-Path -Path $DriverPath -Leaf)"
        }

        $arguments = "/i `"$DriverPath`""
        
        if ($Silent) {
            $arguments += " /qn /norestart"
        }

        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            if (Get-Command Write-SuccessLog -ErrorAction SilentlyContinue) {
                Write-SuccessLog "Treiber erfolgreich installiert"
            }
            return $true
        }
        else {
            if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
                Write-ErrorLog "msiexec fehlgeschlagen (Exit: $($process.ExitCode))"
            }
            return $false
        }
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei MSI-Treiber-Installation: $_" -Exception $_.Exception
        }
        return $false
    }
}

<#
.SYNOPSIS
    Sucht nach .inf-Dateien in einem Verzeichnis

.PARAMETER Path
    Suchpfad

.EXAMPLE
    Find-DriverFiles -Path "C:\Drivers"
#>
function Find-DriverFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $infFiles = Get-ChildItem -Path $Path -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue
        return $infFiles
    }
    catch {
        if (Get-Command Write-ErrorLog -ErrorAction SilentlyContinue) {
            Write-ErrorLog "Fehler bei Treiber-Suche: $_" -Exception $_.Exception
        }
        return @()
    }
}

<#
.SYNOPSIS
    Installiert alle INF-Treiber in einem Verzeichnis

.PARAMETER Path
    Verzeichnispfad

.EXAMPLE
    Install-DriverFolder -Path "C:\Drivers"
#>
function Install-DriverFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $driverFiles = Find-DriverFiles -Path $Path
    $installed = 0
    $failed = 0

    foreach ($driver in $driverFiles) {
        if (Install-INFDriver -DriverPath $driver.FullName) {
            $installed++
        }
        else {
            $failed++
        }
    }

    if (Get-Command Write-InfoLog -ErrorAction SilentlyContinue) {
        Write-InfoLog "Treiber-Installation abgeschlossen: $installed erfolgreich, $failed fehlgeschlagen"
    }

    return $installed -gt 0
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Install-Driver',
    'Install-INFDriver',
    'Install-EXEDriver',
    'Install-MSIDriver',
    'Find-DriverFiles',
    'Install-DriverFolder'
)
