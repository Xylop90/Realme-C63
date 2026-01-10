#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Automatische Treiber-Installation für Realme C63
    
.DESCRIPTION
    Installiert SPD/Unisoc und Realme USB-Treiber vollautomatisch
    mit Silent-Installation und Signatur-Bypass
    
.NOTES
    Author: Elektronikx-Center-Matte by Alexander Mathey
    Version: 1.0
    Date: 2026-01-10
#>

param(
    [string]$WorkingDirectory = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)

# Importiere Module
. "$WorkingDirectory\scripts\lib\logger.ps1"
. "$WorkingDirectory\scripts\lib\downloader.ps1"
. "$WorkingDirectory\scripts\lib\registry-manager.ps1"

# Initialisiere Logger falls nicht bereits initialisiert
if (-not $Script:LogFile) {
    Initialize-Logger -LogDirectory "$WorkingDirectory\logs" -Level "INFO"
}

Write-LogSection "Treiber-Installation gestartet"

# ============================================================================
# KONFIGURATION
# ============================================================================

$Script:DriverConfig = @{
    SPDDriver = @{
        Name = "SPD/Unisoc USB Driver"
        URLs = @(
            "https://dl.spreadtrum.com/tools/drivers/windows/latest.zip",
            "https://androidmtk.com/download/spreadtrum-usb-driver"
        )
        TargetPath = Join-Path $WorkingDirectory "work\spd-driver"
        InfPattern = "*.inf"
    }
    RealmeDriver = @{
        Name = "Realme Universal USB Driver"
        URLs = @(
            "https://www.realme.com/support/driver-download",
            "https://androidmtk.com/download/realme-usb-driver"
        )
        TargetPath = Join-Path $WorkingDirectory "work\realme-driver"
        InfPattern = "*.inf"
    }
}

# ============================================================================
# DEVCON TOOL HERUNTERLADEN
# ============================================================================

function Get-DevconTool {
    <#
    .SYNOPSIS
    Lädt Microsoft devcon.exe herunter
    #>
    
    $devconPath = Join-Path $WorkingDirectory "work\devcon.exe"
    
    if (Test-Path $devconPath) {
        Write-LogDebug "devcon.exe bereits vorhanden"
        return $devconPath
    }
    
    Write-LogInfo "Lade devcon.exe herunter..."
    
    # Devcon ist Teil des Windows Driver Kit
    # Alternative: Verwende PnPUtil (in Windows eingebaut)
    
    Write-LogInfo "Verwende PnPUtil (Windows-integriert) anstelle von devcon"
    return "pnputil"
}

# ============================================================================
# TREIBER INSTALLIEREN
# ============================================================================

function Install-DriverFromInf {
    <#
    .SYNOPSIS
    Installiert Treiber aus INF-Datei
    #>
    param(
        [string]$InfPath,
        [string]$DriverName
    )
    
    try {
        Write-LogInfo "Installiere Treiber: $DriverName"
        Write-LogDebug "INF-Pfad: $InfPath"
        
        # Verwende pnputil für Silent-Installation
        $output = & pnputil.exe /add-driver "$InfPath" /install /subdirs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogInfo "Treiber erfolgreich installiert: $DriverName"
            return $true
        }
        else {
            Write-LogWarning "Treiber-Installation mit Warnung: $output"
            
            # Versuche Alternative Installation
            Write-LogInfo "Versuche alternative Installation..."
            $output = & pnputil.exe /add-driver "$InfPath" /subdirs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-LogInfo "Treiber hinzugefügt (manuelle Installation im Geräte-Manager möglich)"
                return $true
            }
        }
        
        return $false
    }
    catch {
        Write-LogError "Fehler beim Installieren des Treibers: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# SPD TREIBER INSTALLIEREN
# ============================================================================

function Install-SPDDriver {
    Write-LogSection "SPD/Unisoc Treiber-Installation"
    
    $driverConfig = $Script:DriverConfig.SPDDriver
    $targetPath = $driverConfig.TargetPath
    
    # Erstelle Zielverzeichnis
    if (-not (Test-Path $targetPath)) {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }
    
    # Download Treiber
    $downloaded = $false
    $driverZip = Join-Path $targetPath "spd-driver.zip"
    
    foreach ($url in $driverConfig.URLs) {
        Write-LogInfo "Versuche Download von: $url"
        
        if (Invoke-DownloadWithRetry -Url $url -Destination $driverZip -MaxRetries 3) {
            $downloaded = $true
            break
        }
    }
    
    if (-not $downloaded) {
        Write-LogWarning "SPD-Treiber-Download fehlgeschlagen - bitte manuell installieren"
        Write-LogInfo "Download-Link: https://androidmtk.com/download/spreadtrum-usb-driver"
        return $false
    }
    
    # Entpacke Treiber
    if (-not (Expand-ArchiveWithProgress -ArchivePath $driverZip -DestinationPath $targetPath -Force)) {
        Write-LogError "Fehler beim Entpacken der SPD-Treiber"
        return $false
    }
    
    # Finde INF-Dateien
    $infFiles = Get-ChildItem -Path $targetPath -Filter "*.inf" -Recurse
    
    if ($infFiles.Count -eq 0) {
        Write-LogWarning "Keine INF-Dateien in SPD-Treiber gefunden"
        return $false
    }
    
    # Installiere alle gefundenen Treiber
    $successCount = 0
    foreach ($inf in $infFiles) {
        if (Install-DriverFromInf -InfPath $inf.FullName -DriverName "SPD USB Driver ($($inf.Name))") {
            $successCount++
        }
    }
    
    Write-LogInfo "SPD-Treiber-Installation abgeschlossen: $successCount/$($infFiles.Count) erfolgreich"
    return ($successCount -gt 0)
}

# ============================================================================
# REALME TREIBER INSTALLIEREN
# ============================================================================

function Install-RealmeDriver {
    Write-LogSection "Realme USB-Treiber-Installation"
    
    $driverConfig = $Script:DriverConfig.RealmeDriver
    $targetPath = $driverConfig.TargetPath
    
    # Erstelle Zielverzeichnis
    if (-not (Test-Path $targetPath)) {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }
    
    # Download Treiber
    $downloaded = $false
    $driverZip = Join-Path $targetPath "realme-driver.zip"
    
    foreach ($url in $driverConfig.URLs) {
        Write-LogInfo "Versuche Download von: $url"
        
        if (Invoke-DownloadWithRetry -Url $url -Destination $driverZip -MaxRetries 3) {
            $downloaded = $true
            break
        }
    }
    
    if (-not $downloaded) {
        Write-LogWarning "Realme-Treiber-Download fehlgeschlagen - bitte manuell installieren"
        Write-LogInfo "Download-Link: https://www.realme.com/support/driver-download"
        return $false
    }
    
    # Entpacke Treiber
    if (-not (Expand-ArchiveWithProgress -ArchivePath $driverZip -DestinationPath $targetPath -Force)) {
        Write-LogError "Fehler beim Entpacken der Realme-Treiber"
        return $false
    }
    
    # Finde INF-Dateien
    $infFiles = Get-ChildItem -Path $targetPath -Filter "*.inf" -Recurse
    
    if ($infFiles.Count -eq 0) {
        Write-LogWarning "Keine INF-Dateien in Realme-Treiber gefunden"
        
        # Suche nach EXE-Installer
        $exeInstaller = Get-ChildItem -Path $targetPath -Filter "*.exe" -Recurse | Select-Object -First 1
        
        if ($exeInstaller) {
            Write-LogInfo "Gefunden: Installer $($exeInstaller.Name)"
            Write-LogInfo "Versuche Silent-Installation..."
            
            try {
                & $exeInstaller.FullName /S /quiet /norestart 2>&1 | Out-Null
                Start-Sleep -Seconds 10
                
                Write-LogInfo "Installer ausgeführt"
                return $true
            }
            catch {
                Write-LogWarning "Installer fehlgeschlagen: $($_.Exception.Message)"
                return $false
            }
        }
        
        return $false
    }
    
    # Installiere alle gefundenen Treiber
    $successCount = 0
    foreach ($inf in $infFiles) {
        if (Install-DriverFromInf -InfPath $inf.FullName -DriverName "Realme USB Driver ($($inf.Name))") {
            $successCount++
        }
    }
    
    Write-LogInfo "Realme-Treiber-Installation abgeschlossen: $successCount/$($infFiles.Count) erfolgreich"
    return ($successCount -gt 0)
}

# ============================================================================
# TREIBER-VERIFIZIERUNG
# ============================================================================

function Test-DriversInstalled {
    Write-LogSection "Treiber-Verifizierung"
    
    # Prüfe installierte Treiber
    $drivers = Get-WindowsDriver -Online | Where-Object {
        $_.ProviderName -like "*Spreadtrum*" -or 
        $_.ProviderName -like "*Realme*" -or
        $_.ProviderName -like "*Unisoc*"
    }
    
    if ($drivers) {
        Write-LogInfo "Gefundene Treiber:"
        foreach ($driver in $drivers) {
            Write-LogInfo "  - $($driver.ProviderName): $($driver.ClassName)"
        }
        return $true
    }
    else {
        Write-LogWarning "Keine Realme/SPD-Treiber im System gefunden"
        return $false
    }
}

# ============================================================================
# HAUPTAUSFÜHRUNG
# ============================================================================

function Start-DriverInstallation {
    try {
        Write-LogInfo "Arbeitsverzeichnis: $WorkingDirectory"
        
        # Test-Signing aktivieren
        Write-LogInfo "Aktiviere Test-Signing für unsignierte Treiber..."
        Enable-TestSigning | Out-Null
        
        # SPD-Treiber installieren
        $spdSuccess = Install-SPDDriver
        
        # Realme-Treiber installieren
        $realmeSuccess = Install-RealmeDriver
        
        # Verifiziere Installation
        Test-DriversInstalled | Out-Null
        
        if ($spdSuccess -or $realmeSuccess) {
            Write-LogSection "Treiber-Installation erfolgreich"
            Write-LogWarning "HINWEIS: Neustart kann erforderlich sein"
            return $true
        }
        else {
            Write-LogWarning "Treiber-Installation mit Problemen abgeschlossen"
            Write-LogInfo "Bitte prüfen Sie die Logs für Details"
            return $false
        }
    }
    catch {
        Write-LogError "Fehler bei Treiber-Installation: $($_.Exception.Message)"
        Write-LogError $_.ScriptStackTrace
        return $false
    }
}

# Führe Installation aus
$result = Start-DriverInstallation
exit $(if ($result) { 0 } else { 1 })
