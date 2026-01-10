# Scripts Directory - Realme C63 (RMX3939)

This directory contains automated installation and download scripts for Windows and Termux (Android).

## 📦 Available Scripts

### Windows PowerShell Scripts

#### 1. `download-all-tools.ps1` ⭐ NEW!
**Standalone download script** - Downloads all required tools and drivers automatically.

**Features:**
- Downloads ADB & Fastboot Platform Tools
- Downloads USB drivers (Google, Universal, Realme, OPPO)
- Downloads TWRP Recovery for RMX3939
- Downloads Magisk (Latest + Canary)
- Downloads SP Flash Tool (optional)
- Creates organized folder structure
- Generates README files in each folder
- Creates download manifest

**Usage:**
```powershell
# Run with default settings
.\download-all-tools.ps1

# Specify custom download location
.\download-all-tools.ps1 -DownloadPath "D:\MyDownloads"

# Skip optional tools
.\download-all-tools.ps1 -SkipOptional
```

**Requirements:**
- Windows 10/11
- PowerShell 5.1 or newer
- Internet connection
- ~500MB disk space

---

#### 2. `install-windows.ps1`
**Complete installation wizard** - Interactive menu-driven installer with comprehensive features.

**Features:**
- Setup ADB/Fastboot
- Install USB drivers
- **Download all required tools** (Option 3)
- **Install all drivers** (Option 4)
- Verify device connection
- Display device diagnostics
- Unlock bootloader
- Flash recovery
- Flash ROM
- Full automated installation

**Usage:**
```powershell
# Run with administrator privileges
.\install-windows.ps1

# Skip ADB installation
.\install-windows.ps1 -SkipADB

# Skip driver installation
.\install-windows.ps1 -SkipDrivers

# Custom working directory
.\install-windows.ps1 -WorkingDirectory "D:\Realme-Tools"
```

**Requirements:**
- Windows 10/11
- **Administrator privileges** required
- PowerShell 5.1 or newer
- Internet connection

---

#### 3. `install-windows.bat`
**Legacy batch script** - Simple batch file wrapper for PowerShell script.

**Usage:**
```cmd
install-windows.bat
```

---

### Android/Termux Script

#### 4. `install-termux.sh`
**Termux installation script** - For installing tools directly on Android device via Termux.

**Usage:**
```bash
bash install-termux.sh
```

**Requirements:**
- Termux app installed
- Internet connection
- Storage permission granted

---

## 🚀 Quick Start Guide

### For Windows Users - Download Only

If you just want to download all required files:

1. **Open PowerShell** (no admin needed)
2. Navigate to scripts folder:
   ```powershell
   cd C:\path\to\Realme-C63\scripts
   ```
3. Run download script:
   ```powershell
   .\download-all-tools.ps1
   ```
4. Files will be downloaded to `C:\Realme-C63-Downloads` by default

### For Windows Users - Full Installation

If you want the complete automated installation wizard:

1. **Open PowerShell as Administrator** (Right-click → Run as Administrator)
2. Navigate to scripts folder:
   ```powershell
   cd C:\path\to\Realme-C63\scripts
   ```
3. Enable script execution (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```
4. Run installation wizard:
   ```powershell
   .\install-windows.ps1
   ```
5. Follow the interactive menu

---

## 📋 What Gets Downloaded

### Essential Tools (~100MB)
- ✅ Android Platform Tools (ADB & Fastboot)
- ✅ Minimal ADB and Fastboot (alternative)

### USB Drivers (~50MB)
- ✅ Google USB Driver
- ✅ Universal ADB Driver
- ✅ Realme USB Driver
- ✅ OPPO USB Driver

### Recovery & Root (~20MB)
- ✅ TWRP Recovery (RMX3939-specific)
- ✅ Magisk Latest Stable
- ✅ Magisk Canary (Beta)

### Flash Tools (Optional, ~300MB)
- ⚪ SP Flash Tool (MediaTek)

**Total Size: ~470MB** (without optional tools)

---

## 🔧 Troubleshooting

### PowerShell Execution Policy Error

**Error:** "Cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Download Failures

**Cause:** Firewall, antivirus, or network issues

**Solutions:**
1. Disable antivirus temporarily
2. Check firewall settings
3. Try different network
4. Download files manually from URLs in script

### Driver Installation Fails

**Cause:** Requires administrator privileges

**Solution:**
1. Close PowerShell
2. Right-click PowerShell → Run as Administrator
3. Run script again

---

## 📖 Related Documentation

- [Bootloader Unlock Guide](../docs/BOOTLOADER_UNLOCK.md)
- [TWRP Installation Guide](../docs/TWRP_INSTALLATION.md)
- [Rooting Guide](../docs/ROOTING_GUIDE.md)
- [ROM Installation](../docs/INSTALLATION.md)

---

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review error messages in PowerShell
3. Check log files (created automatically)
4. Visit repository issues: https://github.com/Xylop90/Realme-C63/issues
5. Read documentation in `/docs` folder

---

## ⚖️ Legal Notice

- Tools are downloaded from official sources
- Drivers are from manufacturer websites
- Magisk is from official GitHub repository
- Use at your own risk
- Always backup your data

---

**Last Updated:** 2026-01-10  
**Author:** Xylop90 / Elektronikx-Center-Matte  
**Repository:** https://github.com/Xylop90/Realme-C63
