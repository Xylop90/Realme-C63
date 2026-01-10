<#
.SYNOPSIS
    Generate comprehensive installation documentation.

.DESCRIPTION
    Auto-generates complete documentation suite including installation guides,
    troubleshooting, FAQ, and API documentation.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputDir
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "..\modules"
Import-Module (Join-Path $modulePath "Doc-Generator.psm1") -Force
Import-Module (Join-Path $modulePath "UI-Helper.psm1") -Force

# Main execution
Show-Banner

if (-not $OutputDir) {
    $OutputDir = Join-Path $PSScriptRoot "..\..\docs"
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-ColoredMessage "Generating Documentation Suite..." "Cyan"
Write-ColoredMessage "Output Directory: $OutputDir" "White"

# Generate main installation guide
Write-ColoredMessage "`nGenerating Installation Guide..." "Cyan"
$installGuide = New-InstallationGuide
$installGuide | Out-File (Join-Path $OutputDir "INSTALLATION-GUIDE.md") -Encoding UTF8

# Generate device configuration
Write-ColoredMessage "Generating Device Configuration..." "Cyan"
$deviceConfig = New-DeviceConfig
$deviceConfig | Out-File (Join-Path $OutputDir "DEVICE-CONFIG.md") -Encoding UTF8

# Generate complete suite
Write-ColoredMessage "Generating Complete Documentation Suite..." "Cyan"
New-DocumentationSuite -OutputPath $OutputDir

# Generate troubleshooting guide
Write-ColoredMessage "Generating Troubleshooting Guide..." "Cyan"
$troubleshooting = @"
# Troubleshooting Guide

## Common Issues

### Device Not Detected
1. Check USB cable connection
2. Enable USB Debugging in Developer Options
3. Install USB drivers (Run Setup-Permissions.ps1)
4. Try different USB port

### Bootloader Unlock Failed
1. Ensure OEM unlock is enabled
2. Try alternative unlock method
3. Check device connection
4. Verify device is in fastboot mode

### Root Installation Failed
1. Ensure bootloader is unlocked
2. Check Magisk APK installation
3. Verify boot.img patching
4. Try re-downloading firmware

### Driver Installation Issues
1. Run as Administrator
2. Disable antivirus temporarily
3. Check Windows Update
4. Manually install drivers from work/drivers/

## Error Codes

- **Error 001**: Device not found - Check USB connection
- **Error 002**: Bootloader locked - Unlock bootloader first
- **Error 003**: No root access - Install Magisk
- **Error 004**: Driver not installed - Run Setup-Permissions.ps1

## Support

For additional help:
- Check documentation in docs/ folder
- Review logs in work/logs/
- Run Verify-Installation.ps1 for diagnostics
- Contact support with error logs

---
**Copyright © 2026 Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey**
"@

$troubleshooting | Out-File (Join-Path $OutputDir "TROUBLESHOOTING.md") -Encoding UTF8

# Generate FAQ
Write-ColoredMessage "Generating FAQ..." "Cyan"
$faq = @"
# Frequently Asked Questions (FAQ)

## General

### Q: Is this safe for my device?
A: Yes, but unlocking bootloader will void warranty. Always backup data first.

### Q: Will I lose my data?
A: Bootloader unlock will factory reset. Root installation preserves data.

### Q: Can I relock bootloader later?
A: Yes, but you may need to restore stock firmware first.

## Installation

### Q: How long does installation take?
A: Complete installation takes 20-30 minutes depending on internet speed.

### Q: Do I need special drivers?
A: The installer automatically downloads and installs required drivers.

### Q: Can I use this on any Realme C63?
A: Designed for RMX3939 model. Check device model before proceeding.

## Troubleshooting

### Q: Installation failed, what now?
A: Run Verify-Installation.ps1 to diagnose issues. Check TROUBLESHOOTING.md.

### Q: Device bootloop after root?
A: Boot to recovery, restore backup, or flash stock firmware.

### Q: Lost root after update?
A: Re-patch boot.img with Magisk after system updates.

## Advanced

### Q: Can I install custom recovery?
A: Yes, use TWRP-Manager module for TWRP installation.

### Q: How do I update Magisk?
A: Run Update-System.ps1 or use Magisk app's built-in updater.

### Q: Can I use this for other devices?
A: No, this installer is specifically for Realme C63 RMX3939.

---
**Copyright © 2026 Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey**
"@

$faq | Out-File (Join-Path $OutputDir "FAQ.md") -Encoding UTF8

Write-ColoredMessage "`nDocumentation Generation Complete!" "Green"
Write-ColoredMessage "Generated Files:" "Cyan"
Write-ColoredMessage "  - INSTALLATION-GUIDE.md" "White"
Write-ColoredMessage "  - DEVICE-CONFIG.md" "White"
Write-ColoredMessage "  - TROUBLESHOOTING.md" "White"
Write-ColoredMessage "  - FAQ.md" "White"

Write-ColoredMessage "`nAll documentation available in: $OutputDir" "Green"
