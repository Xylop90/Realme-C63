<#
.SYNOPSIS
    Verify-Installation - Überprüft Installation nach Abschluss

.DESCRIPTION
    Post-Installation Check mit:
    - Verzeichnisstruktur-Verifikation
    - Tool-Verfügbarkeit-Check
    - Treiber-Status
    - Log-Analyse

.EXAMPLE
    .\Verify-Installation.ps1

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

[CmdletBinding()]
param()

# Setze Pfade
$script:RootDir = Split-Path -Path $PSScriptRoot -Parent
$script:RootDir = Split-Path -Path $script:RootDir -Parent

$script:Paths = @{
    Root        = $script:RootDir
    Config      = Join-Path $script:RootDir "config"
    Scripts     = Join-Path $script:RootDir "scripts"
    Modules     = Join-Path $script:RootDir "scripts\modules"
    Work        = Join-Path $script:RootDir "work"
    Downloads   = Join-Path $script:RootDir "work\downloads"
    Logs        = Join-Path $script:RootDir "work\logs"
}

# ============================================================================
# VERZEICHNISSTRUKTUR PRÜFEN
# ============================================================================

function Test-DirectoryStructure {
    Write-Host ""
    Write-Host "Verzeichnisstruktur:" -ForegroundColor Yellow
    
    $allExist = $true
    foreach ($path in $script:Paths.GetEnumerator()) {
        $exists = Test-Path -Path $path.Value
        $status = if ($exists) { "[✓]" } else { "[✗]"; $allExist = $false }
        $color = if ($exists) { "Green" } else { "Red" }
        
        Write-Host "  $status $($path.Key): $($path.Value)" -ForegroundColor $color
    }
    
    Write-Host ""
    return $allExist
}

# ============================================================================
# KONFIGURATIONSDATEIEN PRÜFEN
# ============================================================================

function Test-ConfigFiles {
    Write-Host "Konfigurationsdateien:" -ForegroundColor Yellow
    
    $configFiles = @(
        "installer-config.json",
        "firmware-sources.json",
        "driver-signatures.json",
        "tool-versions.json"
    )
    
    $allExist = $true
    foreach ($file in $configFiles) {
        $path = Join-Path $script:Paths.Config $file
        $exists = Test-Path -Path $path
        $status = if ($exists) { "[✓]" } else { "[✗]"; $allExist = $false }
        $color = if ($exists) { "Green" } else { "Red" }
        
        Write-Host "  $status $file" -ForegroundColor $color
        
        # Validiere JSON
        if ($exists) {
            try {
                Get-Content -Path $path -Raw | ConvertFrom-Json | Out-Null
                Write-Host "      JSON valide" -ForegroundColor Gray
            }
            catch {
                Write-Host "      JSON INVALID: $_" -ForegroundColor Red
                $allExist = $false
            }
        }
    }
    
    Write-Host ""
    return $allExist
}

# ============================================================================
# MODULE PRÜFEN
# ============================================================================

function Test-Modules {
    Write-Host "PowerShell-Module:" -ForegroundColor Yellow
    
    $modules = @(
        "Logger.psm1",
        "Download-Manager.psm1",
        "Driver-Manager.psm1",
        "Device-Manager.psm1",
        "Firmware-Manager.psm1",
        "SPD-Automation.psm1",
        "UI-Helper.psm1"
    )
    
    $allExist = $true
    foreach ($module in $modules) {
        $path = Join-Path $script:Paths.Modules $module
        $exists = Test-Path -Path $path
        $status = if ($exists) { "[✓]" } else { "[✗]"; $allExist = $false }
        $color = if ($exists) { "Green" } else { "Red" }
        
        Write-Host "  $status $module" -ForegroundColor $color
        
        # Versuche Modul zu laden
        if ($exists) {
            try {
                Import-Module $path -Force -ErrorAction Stop
                Write-Host "      Modul ladbar" -ForegroundColor Gray
            }
            catch {
                Write-Host "      FEHLER beim Laden: $_" -ForegroundColor Red
                $allExist = $false
            }
        }
    }
    
    Write-Host ""
    return $allExist
}

# ============================================================================
# SKRIPTE PRÜFEN
# ============================================================================

function Test-Scripts {
    Write-Host "PowerShell-Skripte:" -ForegroundColor Yellow
    
    $scripts = @(
        "Install-RealmeC63.ps1",
        "Generate-Documentation.ps1",
        "Setup-Permissions.ps1",
        "Update-Configuration.ps1",
        "Verify-Installation.ps1"
    )
    
    $allExist = $true
    $scriptsPath = Join-Path $script:Paths.Scripts "ps"
    
    foreach ($script in $scripts) {
        $path = Join-Path $scriptsPath $script
        $exists = Test-Path -Path $path
        $status = if ($exists) { "[✓]" } else { "[✗]"; $allExist = $false }
        $color = if ($exists) { "Green" } else { "Red" }
        
        Write-Host "  $status $script" -ForegroundColor $color
    }
    
    Write-Host ""
    return $allExist
}

# ============================================================================
# TOOLS PRÜFEN
# ============================================================================

function Test-Tools {
    Write-Host "Installierte Tools:" -ForegroundColor Yellow
    
    # Platform Tools (ADB/Fastboot)
    $platformToolsPath = Join-Path $script:Paths.Work "extracted\platform-tools"
    $adbPath = Join-Path $platformToolsPath "adb.exe"
    $fastbootPath = Join-Path $platformToolsPath "fastboot.exe"
    
    $adbExists = Test-Path -Path $adbPath
    $fastbootExists = Test-Path -Path $fastbootPath
    
    $adbStatus = if ($adbExists) { "[✓]" } else { "[○]" }
    $fastbootStatus = if ($fastbootExists) { "[✓]" } else { "[○]" }
    
    $adbColor = if ($adbExists) { "Green" } else { "Yellow" }
    $fastbootColor = if ($fastbootExists) { "Green" } else { "Yellow" }
    
    Write-Host "  $adbStatus ADB (Platform Tools)" -ForegroundColor $adbColor
    Write-Host "  $fastbootStatus Fastboot (Platform Tools)" -ForegroundColor $fastbootColor
    
    # SPD Flash Tool
    $spdPaths = @(
        "C:\Program Files\SPD Flash Tool\SPD_Upgrade_Tool.exe",
        "C:\Program Files (x86)\SPD Flash Tool\SPD_Upgrade_Tool.exe",
        "C:\SPD Flash Tool\SPD_Upgrade_Tool.exe"
    )
    
    $spdFound = $false
    foreach ($path in $spdPaths) {
        if (Test-Path -Path $path) {
            $spdFound = $true
            Write-Host "  [✓] SPD Flash Tool: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $spdFound) {
        Write-Host "  [○] SPD Flash Tool (nicht installiert)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================================
# LOG-DATEIEN ANALYSIEREN
# ============================================================================

function Get-LogSummary {
    Write-Host "Log-Dateien:" -ForegroundColor Yellow
    
    if (Test-Path -Path $script:Paths.Logs) {
        $logFiles = Get-ChildItem -Path $script:Paths.Logs -Filter "*.log" -ErrorAction SilentlyContinue
        
        if ($logFiles) {
            Write-Host "  Anzahl Log-Dateien: $($logFiles.Count)" -ForegroundColor White
            
            # Neueste Log-Datei analysieren
            $latestLog = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            Write-Host "  Neueste Log-Datei: $($latestLog.Name)" -ForegroundColor White
            Write-Host "  Erstellt: $($latestLog.LastWriteTime)" -ForegroundColor Gray
            
            # Zähle Fehler in neuester Log-Datei
            $content = Get-Content -Path $latestLog.FullName -ErrorAction SilentlyContinue
            $errors = ($content | Select-String -Pattern "\[ERROR\]").Count
            $warnings = ($content | Select-String -Pattern "\[WARN\]").Count
            
            Write-Host "  Fehler: $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Red" })
            Write-Host "  Warnungen: $warnings" -ForegroundColor $(if ($warnings -eq 0) { "Green" } else { "Yellow" })
        }
        else {
            Write-Host "  Keine Log-Dateien gefunden" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  Log-Verzeichnis existiert nicht" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================================
# GESAMTSTATUS
# ============================================================================

function Get-OverallStatus {
    param(
        [bool]$DirCheck,
        [bool]$ConfigCheck,
        [bool]$ModuleCheck,
        [bool]$ScriptCheck
    )
    
    Write-Host "============================================================================" -ForegroundColor Cyan
    
    $allPassed = $DirCheck -and $ConfigCheck -and $ModuleCheck -and $ScriptCheck
    
    if ($allPassed) {
        Write-Host "                 ✓ INSTALLATION ERFOLGREICH                                " -ForegroundColor Green
        Write-Host ""
        Write-Host "Alle Komponenten wurden erfolgreich installiert und verifiziert." -ForegroundColor Green
    }
    else {
        Write-Host "                 ⚠ INSTALLATION UNVOLLSTÄNDIG                             " -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Einige Komponenten fehlen oder sind fehlerhaft." -ForegroundColor Yellow
        Write-Host "Bitte prüfen Sie die Ausgabe oben für Details." -ForegroundColor Yellow
    }
    
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    return $allPassed
}

# ============================================================================
# HAUPTFUNKTION
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "            Verify-Installation - Post-Installation Check                   " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Führe alle Checks durch
    $dirCheck = Test-DirectoryStructure
    $configCheck = Test-ConfigFiles
    $moduleCheck = Test-Modules
    $scriptCheck = Test-Scripts
    Test-Tools
    Get-LogSummary
    
    # Gesamtstatus
    $success = Get-OverallStatus -DirCheck $dirCheck -ConfigCheck $configCheck -ModuleCheck $moduleCheck -ScriptCheck $scriptCheck
    
    if ($success) {
        exit 0
    }
    else {
        exit 1
    }
}

Main
