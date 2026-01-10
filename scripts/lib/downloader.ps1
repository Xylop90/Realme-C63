#Requires -Version 5.1
<#
.SYNOPSIS
    Download-Manager mit Resume-Funktion und Hash-Verifizierung
    
.DESCRIPTION
    Bietet robuste Download-Funktionen mit automatischen Retries,
    Resume-Support, Hash-Checks und Mirror-Fallback
    
.NOTES
    Author: Realme C63 Automated Installation System
    Version: 1.0
    Date: 2026-01-10
#>

# Importiere Logger
. "$PSScriptRoot\logger.ps1"

function Test-InternetConnection {
    <#
    .SYNOPSIS
    Prüft Internet-Verbindung
    #>
    try {
        $null = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-FileHash256 {
    <#
    .SYNOPSIS
    Berechnet SHA256-Hash einer Datei
    #>
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash
    }
    catch {
        return $null
    }
}

function Invoke-DownloadWithRetry {
    <#
    .SYNOPSIS
    Lädt eine Datei mit automatischen Retries herunter
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        
        [string]$ExpectedHash,
        
        [int]$MaxRetries = 5,
        
        [int]$TimeoutSeconds = 300,
        
        [string[]]$MirrorUrls = @()
    )
    
    $allUrls = @($Url) + $MirrorUrls
    $retryCount = 0
    $success = $false
    
    # Prüfe Internet-Verbindung
    if (-not (Test-InternetConnection)) {
        Write-LogError "Keine Internet-Verbindung verfügbar"
        return $false
    }
    
    # Erstelle Zielverzeichnis
    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }
    
    foreach ($currentUrl in $allUrls) {
        $retryCount = 0
        
        while ($retryCount -lt $MaxRetries -and -not $success) {
            try {
                Write-LogInfo "Download-Versuch $($retryCount + 1)/$MaxRetries von: $currentUrl"
                
                # Download mit BITS Transfer für Resume-Support
                if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
                    Start-BitsTransfer -Source $currentUrl -Destination $Destination -ErrorAction Stop
                }
                else {
                    # Fallback zu WebClient
                    $webClient = New-Object System.Net.WebClient
                    $webClient.DownloadFile($currentUrl, $Destination)
                }
                
                # Prüfe ob Datei existiert
                if (Test-Path $Destination) {
                    $fileSize = (Get-Item $Destination).Length
                    Write-LogInfo "Download abgeschlossen: $([math]::Round($fileSize / 1MB, 2)) MB"
                    
                    # Hash-Verifizierung
                    if ($ExpectedHash) {
                        Write-LogInfo "Verifiziere Hash..."
                        $actualHash = Get-FileHash256 -FilePath $Destination
                        
                        if ($actualHash -eq $ExpectedHash) {
                            Write-LogInfo "Hash-Verifizierung erfolgreich"
                            $success = $true
                            break
                        }
                        else {
                            Write-LogWarning "Hash stimmt nicht überein. Erwartet: $ExpectedHash, Erhalten: $actualHash"
                            Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
                            $retryCount++
                        }
                    }
                    else {
                        $success = $true
                        break
                    }
                }
            }
            catch {
                Write-LogWarning "Download fehlgeschlagen: $($_.Exception.Message)"
                $retryCount++
                
                if ($retryCount -lt $MaxRetries) {
                    $waitTime = [math]::Pow(2, $retryCount) # Exponential Backoff
                    Write-LogInfo "Warte ${waitTime} Sekunden vor erneutem Versuch..."
                    Start-Sleep -Seconds $waitTime
                }
            }
        }
        
        if ($success) {
            break
        }
    }
    
    if ($success) {
        Write-LogInfo "Download erfolgreich: $Destination"
        return $true
    }
    else {
        Write-LogError "Download nach $MaxRetries Versuchen fehlgeschlagen"
        return $false
    }
}

function Expand-ArchiveWithProgress {
    <#
    .SYNOPSIS
    Entpackt Archive mit Fortschrittsanzeige
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ArchivePath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,
        
        [switch]$Force
    )
    
    if (-not (Test-Path $ArchivePath)) {
        Write-LogError "Archiv nicht gefunden: $ArchivePath"
        return $false
    }
    
    try {
        Write-LogInfo "Entpacke Archiv: $ArchivePath"
        
        # Erstelle Zielverzeichnis
        if (-not (Test-Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }
        
        # Versuche mit Expand-Archive (native PowerShell)
        if ($Force) {
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force
        }
        else {
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath
        }
        
        Write-LogInfo "Archiv erfolgreich entpackt nach: $DestinationPath"
        return $true
    }
    catch {
        Write-LogError "Fehler beim Entpacken: $($_.Exception.Message)"
        
        # Fallback zu 7-Zip falls vorhanden
        $7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
        if (Test-Path $7zipPath) {
            Write-LogInfo "Versuche Entpacken mit 7-Zip..."
            try {
                & $7zipPath x "$ArchivePath" -o"$DestinationPath" -y
                Write-LogInfo "Archiv erfolgreich mit 7-Zip entpackt"
                return $true
            }
            catch {
                Write-LogError "Auch 7-Zip fehlgeschlagen: $($_.Exception.Message)"
                return $false
            }
        }
        
        return $false
    }
}

function Get-Download7Zip {
    <#
    .SYNOPSIS
    Lädt 7-Zip CLI herunter falls benötigt
    #>
    param([string]$TargetPath)
    
    $7zipUrl = "https://www.7-zip.org/a/7zr.exe"
    $7zipPath = Join-Path $TargetPath "7za.exe"
    
    if (Test-Path $7zipPath) {
        Write-LogDebug "7-Zip bereits vorhanden: $7zipPath"
        return $7zipPath
    }
    
    Write-LogInfo "Lade 7-Zip CLI herunter..."
    if (Invoke-DownloadWithRetry -Url $7zipUrl -Destination $7zipPath) {
        return $7zipPath
    }
    
    return $null
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Test-InternetConnection',
    'Get-FileHash256',
    'Invoke-DownloadWithRetry',
    'Expand-ArchiveWithProgress',
    'Get-Download7Zip'
)
