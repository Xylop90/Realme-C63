# PowerShell Scripts for Realme C63 (RMX3939)

Automated Windows 11 PowerShell scripts for flashing stock firmware on Realme C63 with Unisoc/Spreadtrum chipset.

## Quick Start

### Prerequisites
- Windows 11 (or Windows 10)
- PowerShell 5.1+ (included with Windows)
- Administrator privileges
- Internet connection
- USB cable

### Installation

```powershell
# 1. Open PowerShell as Administrator
# Right-click Start → Windows PowerShell (Admin)

# 2. Navigate to the repository
cd path\to\Realme-C63

# 3. Run the installation script
.\scripts\ps\install-realme-c63.ps1
```

That's it! The script will:
- Download SPD Flash Tool
- Download USB drivers
- Download firmware
- Install drivers
- Guide you through the flash process

## Scripts Overview

### Main Script

#### `install-realme-c63.ps1`
The main installation script that orchestrates the entire process.

**Usage:**
```powershell
# Basic usage (recommended)
.\install-realme-c63.ps1

# Use stable firmware version
.\install-realme-c63.ps1 -FirmwareVersion stable

# Skip driver installation
.\install-realme-c63.ps1 -SkipDriverInstall

# Test mode (no actual flashing)
.\install-realme-c63.ps1 -TestMode

# Expert mode (no prompts)
.\install-realme-c63.ps1 -ForceNoPrompt

# Custom config file
.\install-realme-c63.ps1 -ConfigPath "path\to\custom-config.json"

# Custom cache directory
.\install-realme-c63.ps1 -CacheDirectory "D:\MyCache"
```

**Parameters:**
- `-ConfigPath`: Path to configuration file (default: `config/downloads.json`)
- `-SkipDriverInstall`: Skip driver installation
- `-FirmwareVersion`: Firmware version to use (`latest` or `stable`)
- `-ForceNoPrompt`: No user prompts (use with caution!)
- `-TestMode`: Simulate the process without downloads/flashing
- `-CacheDirectory`: Custom cache directory (default: `work/cache`)

### Helper Modules

Located in `lib/` directory:

#### `logger.ps1`
Logging functionality with color-coded output and file logging.

**Functions:**
- `Initialize-Logger`: Set up logging
- `Write-Log`: Log messages with levels (INFO, SUCCESS, WARN, ERROR, DEBUG)
- `Write-LogSection`: Log section headers
- `Write-LogError`: Log errors with exception details

#### `download-helper.ps1`
File download functionality with progress tracking and caching.

**Functions:**
- `Download-FileWithProgress`: Download with retry logic
- `Test-UrlAccessible`: Check if URL is accessible
- `Format-FileSize`: Format bytes to human-readable size
- `Expand-ArchiveWithProgress`: Extract archives

#### `hash-verifier.ps1`
SHA256 hash calculation and verification.

**Functions:**
- `Get-FileSHA256Hash`: Calculate file hash
- `Test-FileHash`: Verify file against expected hash
- `Verify-DownloadIntegrity`: Complete integrity check

### SPD Flash Tool Automation

#### `spd-flash-automation.ps1`
Helper functions for SPD Flash Tool automation.

**Functions:**
- `Start-SPDFlashTool`: Launch SPD Flash Tool
- `Show-SPDFlashInstructions`: Display step-by-step instructions
- `Wait-ForSPDDevice`: Wait for device detection
- `Test-SPDDriversInstalled`: Check driver status
- `Get-SPDFlashToolPath`: Find SPD Flash Tool executable

## Configuration

### `config/downloads.json`
Central configuration file with download URLs and device information.

**Structure:**
```json
{
  "spd_flash_tool": {
    "url": "...",
    "version": "...",
    "sha256": "..."
  },
  "usb_drivers": {
    "realme_universal": { ... },
    "spd_drivers": { ... }
  },
  "firmware": {
    "latest": { ... },
    "stable": { ... },
    "sources": [ ... ]
  },
  "device_info": { ... },
  "flash_options": { ... }
}
```

**Updating URLs:**
1. Edit `config/downloads.json`
2. Update the `url` fields
3. Optionally update `sha256` hashes
4. Save and run the script

## Workflow

The script follows this workflow:

1. **System Check**
   - Verify Windows 11
   - Check Administrator privileges
   - Verify PowerShell version

2. **Configuration**
   - Load `config/downloads.json`
   - Display device information

3. **Download Phase**
   - Download SPD Flash Tool (if not cached)
   - Download USB drivers (if not cached)
   - Download firmware (if not cached)
   - Verify SHA256 hashes

4. **Installation Phase**
   - Extract and install USB drivers
   - Verify driver installation

5. **Flash Phase**
   - Start SPD Flash Tool
   - Display step-by-step instructions
   - Wait for device detection
   - Monitor flash process

6. **Post-Flash**
   - Display completion message
   - Provide next steps

## Cache System

Downloaded files are cached in `work/cache/`:
```
work/
├── cache/
│   ├── spd-flash-tool.zip
│   ├── spd-flash-tool/ (extracted)
│   ├── realme_universal.zip
│   ├── spd_drivers.zip
│   ├── drivers/ (extracted drivers)
│   └── RMX3939export_14_A.77.pac
└── logs/
    └── install-YYYYMMDD-HHmmss.log
```

**Benefits:**
- Reuse downloads on subsequent runs
- Faster re-installation
- Reduced bandwidth usage
- Offline installation (if all files cached)

**Clearing Cache:**
```powershell
Remove-Item -Path work\cache\* -Recurse -Force
```

## Logging

Logs are saved to `work/logs/`:
```
work/logs/install-20260110-092730.log
```

**View Latest Log:**
```powershell
Get-ChildItem work\logs\ | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1 | 
    Get-Content
```

**Log Levels:**
- **INFO** (Cyan): General information
- **SUCCESS** (Green): Successful operations
- **WARN** (Yellow): Warnings
- **ERROR** (Red): Errors
- **DEBUG** (Gray): Debug information

## Troubleshooting

### Script Won't Run
```powershell
# Check execution policy
Get-ExecutionPolicy

# If restricted, allow scripts (run as Admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Download Fails
- Check internet connection
- Verify URLs in `config/downloads.json`
- Try manual download and place in `work/cache/`

### Driver Installation Fails
- Ensure running as Administrator
- Check Device Manager for errors
- Try manual driver installation (see `docs/TROUBLESHOOTING.md`)

### Device Not Detected
- Verify USB cable
- Try different USB port (prefer USB 2.0)
- Check if drivers installed correctly
- See `docs/TROUBLESHOOTING.md`

## Best Practices

### Before Running
1. ✅ Backup all data (will be erased!)
2. ✅ Charge battery to at least 50%
3. ✅ Use original/quality USB cable
4. ✅ Close other USB-intensive programs

### During Flash
1. ❌ Do NOT disconnect USB cable
2. ❌ Do NOT power off PC
3. ❌ Do NOT force close SPD Flash Tool
4. ⏳ Be patient (can take 10-15 minutes)

### After Flash
1. ⏱️ Wait for first boot (5-10 minutes)
2. 📱 Follow device setup wizard
3. 💾 Restore data from backup

## Advanced Usage

### Custom Firmware
1. Place your `.pac` file in `work/cache/`
2. Update `config/downloads.json` with filename and hash
3. Run script with appropriate firmware version

### Batch Installation
```powershell
# Install on multiple devices
$devices = 1..5
foreach ($device in $devices) {
    Write-Host "Installing on device $device"
    .\install-realme-c63.ps1 -ForceNoPrompt
    Read-Host "Connect next device and press Enter"
}
```

### Scheduled Installation
```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\path\to\install-realme-c63.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "Realme C63 Auto Flash" -Action $action -Trigger $trigger -RunLevel Highest
```

## Support

- 📘 [Troubleshooting Guide](../../docs/TROUBLESHOOTING.md)
- ❓ [FAQ](../../docs/FAQ.md)
- 🐛 [GitHub Issues](https://github.com/Xylop90/Realme-C63/issues)

## Contributing

Contributions welcome! Please:
1. Test your changes thoroughly
2. Follow PowerShell best practices
3. Update documentation
4. Submit a pull request

---

**Last Updated:** 2026-01-10
