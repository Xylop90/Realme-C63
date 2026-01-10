# Quick Start Guide - Realme C63 Installation

This guide will help you get started quickly with installing the custom ROM on your Realme C63 (RMX3939).

## ⚡ Prerequisites (5 minutes)

Before you begin, ensure you have:

- [ ] **Realme C63 (RMX3939)** device
- [ ] **70%+ battery charge** 
- [ ] **Backup of all data** (will be wiped!)
- [ ] **Windows PC** (or Linux/macOS)
- [ ] **USB cable** (preferably original)
- [ ] **Internet connection** (for downloads)

## 🚀 Quick Installation (3 Easy Steps)

### Step 1: Download & Prepare (10 minutes)

**On Windows:**
```powershell
# Open PowerShell as Administrator
cd path\to\Realme-C63\scripts
.\install-windows.ps1 -DownloadOnly -OptimizedMode
```

**On Linux/macOS:**
```bash
cd Realme-C63
./install.sh --skip-config
```

This downloads all required tools automatically.

### Step 2: Unlock Bootloader (7-15 days wait)

1. **Submit unlock request:**
   - Read: `docs/BOOTLOADER_UNLOCK.md`
   - Go to Realme unlock page
   - Submit your device IMEI
   - **Wait 7-15 days** for approval ⏰

2. **After approval:**
   ```bash
   # Boot to fastboot mode
   # Power off device, then: Volume Down + Power
   
   # Run unlock (on PC)
   fastboot flashing unlock
   ```

⚠️ **WARNING**: This will **WIPE ALL DATA** on your device!

### Step 3: Install ROM (30 minutes)

1. **Flash TWRP Recovery:**
   ```bash
   # Boot to fastboot mode
   fastboot flash recovery twrp.img
   fastboot boot twrp.img
   ```

2. **Install ROM in TWRP:**
   - Wipe → Factory Reset
   - Install → Select ROM.zip
   - Swipe to confirm
   - Reboot System

3. **Done!** 🎉

## 📱 Device Setup

### On Your Device:

1. **Enable Developer Options:**
   - Settings → About Phone
   - Tap "Build Number" 7 times

2. **Enable USB Debugging:**
   - Settings → System → Developer Options
   - Enable "USB Debugging"
   - Enable "OEM Unlocking"

3. **Install USB Drivers** (Windows only):
   - Automatic with installer script
   - Or manual from: `config/download-urls.md`

## 🔧 Automated Installation (Advanced)

For a fully automated experience:

**Windows:**
```powershell
.\scripts\install-windows.ps1 -AutoInstall -OptimizedMode
```

**Linux/macOS:**
```bash
./run-complete-auto.sh
```

This will:
✅ Download all tools
✅ Install drivers
✅ Verify device connection
✅ Guide through unlock process
✅ Install TWRP
✅ Flash ROM

## 📚 Detailed Guides

For more detailed information, see:

| Guide | Description | Time |
|-------|-------------|------|
| [Bootloader Unlock](docs/BOOTLOADER_UNLOCK.md) | Complete unlock process | 7-15 days |
| [TWRP Installation](docs/TWRP_INSTALLATION.md) | Recovery installation | 15 min |
| [ROM Installation](docs/INSTALLATION.md) | Flash custom ROM | 30 min |
| [Rooting Guide](docs/ROOTING_GUIDE.md) | Install Magisk (optional) | 15 min |

## 🐛 Troubleshooting

### Device Not Detected
```bash
# Check ADB connection
adb devices

# If empty, try:
# 1. Replug USB cable
# 2. Try different USB port
# 3. Reinstall drivers
# 4. Enable USB debugging again
```

### Stuck at Boot Logo
```bash
# Boot to TWRP recovery
# Power off, then: Volume Up + Power

# In TWRP:
# Wipe → Advanced Wipe → Select: Dalvik, Cache
# Reboot
```

### Lost IMEI / No Network
```bash
# This is serious! You need to:
# 1. Boot to TWRP
# 2. Restore EFS backup (if you made one)
# 3. Or flash stock firmware
# Always backup EFS before modding!
```

## ⚠️ Important Warnings

🔴 **Data Loss**: Bootloader unlock will erase everything!
🔴 **Warranty**: Will be void after unlocking
🔴 **Brick Risk**: Follow instructions carefully
🔴 **No Restore**: Can't officially re-lock bootloader
🔴 **Banking Apps**: May not work (can be fixed with Magisk)

## ✅ Checklist

Before starting:
- [ ] Read all documentation
- [ ] Backup everything important
- [ ] Charge device to 70%+
- [ ] Download all required files
- [ ] Understand the risks
- [ ] Have recovery plan ready
- [ ] Note Google account credentials

During installation:
- [ ] Verify file checksums
- [ ] Make NANDROID backup in TWRP
- [ ] Keep device plugged in
- [ ] Don't interrupt the process
- [ ] Follow steps exactly

After installation:
- [ ] Complete Android setup
- [ ] Test all features
- [ ] Install essential apps
- [ ] Configure settings
- [ ] Enjoy your new ROM! 🎉

## 📞 Getting Help

If you encounter issues:

1. **Check Documentation**: `docs/` folder
2. **Search XDA**: Forum for RMX3939
3. **GitHub Issues**: https://github.com/Xylop90/Realme-C63/issues
4. **Realme Community**: https://c.realme.com/
5. **Reddit**: r/Realme

## 🎯 Quick Commands Reference

```bash
# Check device connection
adb devices

# Reboot to fastboot
adb reboot bootloader

# Reboot to recovery
adb reboot recovery

# Check bootloader status
fastboot getvar unlocked

# Flash recovery
fastboot flash recovery twrp.img

# Boot recovery (temporary)
fastboot boot twrp.img

# Reboot to system
fastboot reboot
```

## 📖 Configuration

All configuration files are in `config/`:
- `realme-c63.conf` - Main settings
- `platform.conf` - Device specs
- `environment.conf` - Environment variables
- `download-urls.md` - All download links

Load environment:
```bash
source config/environment.conf
```

## 🚀 Pro Tips

1. **Always backup**: Use TWRP to create full NANDROID backup
2. **Verify downloads**: Check MD5/SHA256 checksums
3. **Keep originals**: Save stock ROM for emergency
4. **Take notes**: Document what you did
5. **Be patient**: Don't rush the process
6. **Stay updated**: Check for ROM updates regularly

## 📊 Time Estimates

| Task | Time Required |
|------|---------------|
| Reading documentation | 30 min |
| Downloading files | 20 min |
| Setting up device | 10 min |
| Unlocking bootloader | 7-15 days wait |
| Installing TWRP | 15 min |
| Flashing ROM | 30 min |
| Post-setup | 30 min |
| **Total** | **~8-16 days** |

*Most time is waiting for bootloader unlock approval*

## 🎓 Next Steps

After installation:
1. ✅ Complete Android setup
2. ✅ Restore app data
3. ✅ Install Magisk (optional, for root)
4. ✅ Configure privacy settings
5. ✅ Install your favorite apps
6. ✅ Enjoy your custom ROM!

## 📝 Notes

- Keep this guide handy during installation
- Don't skip safety warnings
- Ask for help if unsure
- Document your process
- Share your experience with community

---

**Version**: 1.0.0  
**Last Updated**: 2026-01-10  
**Author**: Elektronikx-Center-Matte / Xylop90  
**Repository**: https://github.com/Xylop90/Realme-C63

**Good luck! You got this! 💪**
