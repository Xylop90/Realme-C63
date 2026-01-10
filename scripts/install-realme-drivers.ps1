# Realme C63 Driver Installation Script
# Run as Administrator

Write-Host "=== Realme C63 Driver Installation ===" -ForegroundColor Cyan

# Download Realme USB Drivers
$driverUrl = "https://download.c.realme.com/flash/realme_usb_driver.zip"
$driverZip = "C:\Realme_Drivers.zip"
$extractPath = "C:\Realme_Drivers"

try {
    Write-Host "Downloading Realme USB Drivers..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $driverUrl -OutFile $driverZip
    
    Write-Host "Extracting drivers..." -ForegroundColor Yellow
    Expand-Archive -Path $driverZip -DestinationPath $extractPath -Force
    
    Write-Host "`nManual installation required:" -ForegroundColor Magenta
    Write-Host "1. Open Device Manager (Win + X, then M)" -ForegroundColor White
    Write-Host "2. Find 'Android Device' or unknown device" -ForegroundColor White
    Write-Host "3. Right-click → Update driver" -ForegroundColor White
    Write-Host "4. Browse to: $extractPath" -ForegroundColor White
    Write-Host "5. Select 'Android Bootloader Interface'" -ForegroundColor White
    
    Write-Host "`n✅ Drivers downloaded to $extractPath" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    Write-Host "Download manually: https://www.realme.com/in/support/software-download" -ForegroundColor Yellow
}

# Clean up
if (Test-Path $driverZip) {
    Remove-Item $driverZip -Force
}
