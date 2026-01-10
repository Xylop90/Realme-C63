<#
.SYNOPSIS
    Download-Manager mit BITS-Transfer, Resume-Support und Mirror-Fallback

.DESCRIPTION
    Dieses Modul bietet intelligente Download-Funktionen:
    - BITS (Background Intelligent Transfer Service) fuer grosse Dateien
    - Automatisches Resume bei Unterbrechung
    - Mirror/Fallback-URLs
    - SHA256-Verifikation
    - Progress-Reporting mit ETA
    - Retry-Logik

.NOTES
    Author: Elektronikx-Center-Matte
    Version: 1.0.0
#>

# Lade Logger-Modul
$modulePath = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $modulePath "modules\Logger.psm1") -Force -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Download einer Datei mit intelligenten Fallback-Mechanismen

.PARAMETER Url
    Haupt-Download-URL

.PARAMETER Destination
    Ziel-Dateipfad

.PARAMETER FallbackUrls
    Optional: Alternative Download-URLs

.PARAMETER UseBITS
    Verwende BITS-Transfer (Standard: $true)

.PARAMETER MaxRetries
    Maximale Anzahl der Wiederholungsversuche (Standard: 3)

.PARAMETER SHA256Hash
    Optional: Erwarteter SHA256-Hash zur Verifikation

.EXAMPLE
    Invoke-SmartDownload -Url "https://example.com/file.zip" -Destination "C:\Downloads\file.zip"
#>
function Invoke-SmartDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [string[]]$FallbackUrls = @(),

        [Parameter(Mandatory = $false)]
        [bool]$UseBITS = $true,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [string]$SHA256Hash = "",

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300
    )

    $allUrls = @($Url) + $FallbackUrls
    $retryCount = 0
    $downloaded = $false

    # Erstelle Zielverzeichnis
    $destDir = Split-Path -Path $Destination -Parent
    if (-not (Test-Path -Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }

    foreach ($downloadUrl in $allUrls) {
        $retryCount = 0
        
        while ($retryCount -lt $MaxRetries -and -not $downloaded) {
            try {
                Write-InfoLog "Download-Versuch $($retryCount + 1)/$MaxRetries von: $downloadUrl"

                if ($UseBITS -and (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue)) {
                    $downloaded = Invoke-BITSDownload -Url $downloadUrl -Destination $Destination -TimeoutSeconds $TimeoutSeconds
                }
                else {
                    $downloaded = Invoke-WebClientDownload -Url $downloadUrl -Destination $Destination -TimeoutSeconds $TimeoutSeconds
                }

                if ($downloaded) {
                    # Verifiziere Download
                    if ($SHA256Hash) {
                        if (Test-FileHash -FilePath $Destination -ExpectedHash $SHA256Hash) {
                            Write-SuccessLog "Download erfolgreich und verifiziert: $Destination"
                            return $true
                        }
                        else {
                            Write-WarnLog "SHA256-Hash stimmt nicht ueberein, versuche erneut..."
                            Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
                            $downloaded = $false
                        }
                    }
                    else {
                        Write-SuccessLog "Download erfolgreich: $Destination"
                        return $true
                    }
                }
            }
            catch {
                Write-ErrorLog "Download fehlgeschlagen: $_" -Exception $_.Exception
                Start-Sleep -Seconds (2 * ($retryCount + 1))
            }

            $retryCount++
        }

        if ($downloaded) {
            break
        }
    }

    if (-not $downloaded) {
        Write-ErrorLog "Alle Download-Versuche fehlgeschlagen fuer: $Url"
        return $false
    }

    return $true
}

<#
.SYNOPSIS
    Download mit BITS (Background Intelligent Transfer Service)

.DESCRIPTION
    Nutzt Windows BITS fuer effizienten, wieder aufnehmbaren Download
#>
function Invoke-BITSDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300
    )

    try {
        Write-InfoLog "Starte BITS-Transfer..."

        # Loesche existierende BITS-Jobs fuer diese Datei
        Get-BitsTransfer | Where-Object { $_.FileList.LocalName -eq $Destination } | Remove-BitsTransfer -ErrorAction SilentlyContinue

        # Starte BITS-Transfer
        $bitsJob = Start-BitsTransfer -Source $Url -Destination $Destination `
            -DisplayName "Realme C63 Installer Download" `
            -Description "Downloading: $(Split-Path -Path $Destination -Leaf)" `
            -Asynchronous `
            -Priority Foreground

        # Warte auf Abschluss mit Progress
        $startTime = Get-Date
        $lastProgress = -1

        while ($bitsJob.JobState -eq "Transferring" -or $bitsJob.JobState -eq "Connecting") {
            Start-Sleep -Milliseconds 500
            
            $bitsJob = Get-BitsTransfer -JobId $bitsJob.JobId
            
            if ($bitsJob.BytesTotal -gt 0) {
                $progress = [int](($bitsJob.BytesTransferred / $bitsJob.BytesTotal) * 100)
                
                if ($progress -ne $lastProgress) {
                    $downloaded = [math]::Round($bitsJob.BytesTransferred / 1MB, 2)
                    $total = [math]::Round($bitsJob.BytesTotal / 1MB, 2)
                    
                    # Berechne ETA
                    $elapsed = (Get-Date) - $startTime
                    if ($bitsJob.BytesTransferred -gt 0) {
                        $speed = $bitsJob.BytesTransferred / $elapsed.TotalSeconds
                        $remaining = ($bitsJob.BytesTotal - $bitsJob.BytesTransferred) / $speed
                        $eta = [TimeSpan]::FromSeconds($remaining)
                        $etaString = $eta.ToString("mm\:ss")
                    }
                    else {
                        $etaString = "--:--"
                    }

                    Write-Host "`r[DOWNLOAD] $progress% ($downloaded MB / $total MB) - ETA: $etaString" -NoNewline -ForegroundColor Cyan
                    $lastProgress = $progress
                }
            }

            # Timeout-Pruefung
            if (((Get-Date) - $startTime).TotalSeconds -gt $TimeoutSeconds) {
                Write-WarnLog "BITS-Transfer Timeout nach $TimeoutSeconds Sekunden"
                Remove-BitsTransfer -BitsJob $bitsJob -ErrorAction SilentlyContinue
                return $false
            }
        }

        Write-Host ""  # Neue Zeile nach Progress

        # Pruefe Status
        if ($bitsJob.JobState -eq "Transferred") {
            Complete-BitsTransfer -BitsJob $bitsJob
            Write-SuccessLog "BITS-Download abgeschlossen"
            return $true
        }
        else {
            Write-ErrorLog "BITS-Transfer fehlgeschlagen: $($bitsJob.JobState)"
            Remove-BitsTransfer -BitsJob $bitsJob -ErrorAction SilentlyContinue
            return $false
        }
    }
    catch {
        Write-ErrorLog "BITS-Download Fehler: $_" -Exception $_.Exception
        return $false
    }
}

<#
.SYNOPSIS
    Download mit WebClient (Fallback wenn BITS nicht verfuegbar)
#>
function Invoke-WebClientDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300
    )

    try {
        Write-InfoLog "Starte WebClient-Download..."

        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Realme-C63-Installer/1.0")

        # Progress-Event registrieren
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClientProgress -Action {
            $progress = $EventArgs.ProgressPercentage
            $downloaded = [math]::Round($EventArgs.BytesReceived / 1MB, 2)
            $total = [math]::Round($EventArgs.TotalBytesToReceive / 1MB, 2)
            Write-Host "`r[DOWNLOAD] $progress% ($downloaded MB / $total MB)" -NoNewline -ForegroundColor Cyan
        } | Out-Null

        # Starte Download
        $webClient.DownloadFileAsync($Url, $Destination)

        # Warte auf Abschluss mit Timeout
        $startTime = Get-Date
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 500
            
            if (((Get-Date) - $startTime).TotalSeconds -gt $TimeoutSeconds) {
                $webClient.CancelAsync()
                Write-WarnLog "WebClient-Download Timeout nach $TimeoutSeconds Sekunden"
                return $false
            }
        }

        Write-Host ""  # Neue Zeile nach Progress

        # Cleanup
        Unregister-Event -SourceIdentifier WebClientProgress -ErrorAction SilentlyContinue
        $webClient.Dispose()

        if (Test-Path -Path $Destination) {
            Write-SuccessLog "WebClient-Download abgeschlossen"
            return $true
        }
        else {
            Write-ErrorLog "Download-Datei nicht gefunden nach WebClient-Download"
            return $false
        }
    }
    catch {
        Write-ErrorLog "WebClient-Download Fehler: $_" -Exception $_.Exception
        Unregister-Event -SourceIdentifier WebClientProgress -ErrorAction SilentlyContinue
        return $false
    }
}

<#
.SYNOPSIS
    Verifiziert SHA256-Hash einer Datei

.PARAMETER FilePath
    Pfad zur zu pruefenden Datei

.PARAMETER ExpectedHash
    Erwarteter SHA256-Hash

.EXAMPLE
    Test-FileHash -FilePath "C:\file.zip" -ExpectedHash "abc123..."
#>
function Test-FileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedHash
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-ErrorLog "Datei nicht gefunden fuer Hash-Verifikation: $FilePath"
        return $false
    }

    try {
        Write-InfoLog "Verifiziere SHA256-Hash..."
        $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash

        if ($actualHash -eq $ExpectedHash) {
            Write-SuccessLog "SHA256-Hash verifiziert"
            return $true
        }
        else {
            Write-ErrorLog "SHA256-Hash stimmt nicht ueberein!`nErwartet: $ExpectedHash`nErhalten: $actualHash"
            return $false
        }
    }
    catch {
        Write-ErrorLog "Hash-Verifikation fehlgeschlagen: $_" -Exception $_.Exception
        return $false
    }
}

<#
.SYNOPSIS
    Extrahiert ZIP-Archive

.PARAMETER ZipPath
    Pfad zum ZIP-Archiv

.PARAMETER Destination
    Zielverzeichnis fuer Extraktion

.EXAMPLE
    Expand-ZipArchive -ZipPath "C:\file.zip" -Destination "C:\extracted"
#>
function Expand-ZipArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ZipPath,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -Path $ZipPath)) {
        Write-ErrorLog "ZIP-Datei nicht gefunden: $ZipPath"
        return $false
    }

    try {
        Write-InfoLog "Extrahiere ZIP-Archiv: $(Split-Path -Path $ZipPath -Leaf)"

        # Erstelle Zielverzeichnis
        if (-not (Test-Path -Path $Destination)) {
            New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        }

        # Extrahiere mit .NET
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $Destination)

        Write-SuccessLog "Extraktion abgeschlossen: $Destination"
        return $true
    }
    catch {
        Write-ErrorLog "Extraktion fehlgeschlagen: $_" -Exception $_.Exception
        return $false
    }
}

# Exportiere Funktionen
Export-ModuleMember -Function @(
    'Invoke-SmartDownload',
    'Test-FileHash',
    'Expand-ZipArchive'
)
