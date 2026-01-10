# Realme C63 Installation Checklist

## Pre-Installation Requirements

### ☐ Device Preparation
- [ ] Charge battery to at least 70%
- [ ] Enable USB Debugging in Developer Options
- [ ] Enable OEM Unlocking in Developer Options
- [ ] Install USB drivers on PC
- [ ] Backup all important data
- [ ] Backup photos, contacts, messages
- [ ] Note down Google account credentials

### ☐ Software Requirements
- [ ] Install ADB and Fastboot
- [ ] Download TWRP Recovery
- [ ] Download Custom ROM
- [ ] Download Magisk (if rooting)
- [ ] Download GApps (if needed)
- [ ] Verify checksums of all downloads

### ☐ Knowledge Requirements
- [ ] Read bootloader unlock guide
- [ ] Read TWRP installation guide
- [ ] Read ROM installation guide
- [ ] Understand the risks
- [ ] Know how to restore device
- [ ] Have backup plan ready

## Installation Process

### Phase 1: Bootloader Unlock
- [ ] Submit unlock request to Realme
- [ ] Wait for approval (7-15 days)
- [ ] Download unlock tool
- [ ] Boot device to fastboot mode
- [ ] Run unlock tool
- [ ] Confirm bootloader is unlocked
- [ ] ⚠️ Device will be wiped!

### Phase 2: TWRP Installation
- [ ] Boot device to fastboot mode
- [ ] Flash TWRP recovery
- [ ] Boot into TWRP
- [ ] Verify TWRP is working
- [ ] Make full NANDROID backup
- [ ] Backup to external storage

### Phase 3: ROM Installation
- [ ] Copy ROM zip to device
- [ ] Boot into TWRP
- [ ] Wipe Data/Factory Reset
- [ ] Wipe Cache and Dalvik Cache
- [ ] Format Data (if required)
- [ ] Flash ROM zip file
- [ ] Flash GApps (if needed)
- [ ] Wipe Cache and Dalvik Cache
- [ ] Reboot to system

### Phase 4: Root Installation (Optional)
- [ ] Download latest Magisk
- [ ] Copy Magisk to device
- [ ] Boot into TWRP
- [ ] Flash Magisk zip
- [ ] Wipe Cache and Dalvik Cache
- [ ] Reboot to system
- [ ] Open Magisk Manager
- [ ] Verify root access
- [ ] Configure SafetyNet

### Phase 5: Post-Installation
- [ ] Complete Android setup
- [ ] Install essential apps
- [ ] Restore app data
- [ ] Configure system settings
- [ ] Test all features
- [ ] Verify camera works
- [ ] Test WiFi and Bluetooth
- [ ] Test phone calls
- [ ] Check battery performance
- [ ] Install banking apps (test SafetyNet)

## Troubleshooting

### Device Not Booting
- [ ] Boot into TWRP
- [ ] Wipe Cache and Dalvik Cache
- [ ] Reinstall ROM
- [ ] Restore NANDROID backup

### Bootloop
- [ ] Boot into TWRP
- [ ] Format Data
- [ ] Wipe Cache and Dalvik Cache
- [ ] Reflash ROM

### No Signal / IMEI Lost
- [ ] Restore EFS backup
- [ ] Flash stock firmware
- [ ] Contact support

### SafetyNet Failing
- [ ] Update Magisk
- [ ] Install Universal SafetyNet Fix
- [ ] Use Magisk Hide
- [ ] Check for updates

## Post-Installation Tips

### Performance
- [ ] Disable unnecessary animations
- [ ] Limit background processes
- [ ] Use Greenify for hibernation
- [ ] Clear cache regularly

### Battery Life
- [ ] Optimize app battery usage
- [ ] Use battery saver mode
- [ ] Disable unnecessary sync
- [ ] Lower screen brightness

### Security
- [ ] Set up screen lock
- [ ] Enable Find My Device
- [ ] Regular backups
- [ ] Keep system updated

## Important Notes

⚠️ **WARNINGS:**
- Bootloader unlock will WIPE all data
- Warranty will be VOID
- Process is IRREVERSIBLE (officially)
- Banking apps may NOT work
- System updates may FAIL

✅ **BENEFITS:**
- Full control over device
- Custom ROMs and kernels
- Better performance
- Removed bloatware
- Latest Android features

## Emergency Contacts

- **XDA Forum:** [Link to thread]
- **Telegram Group:** [Link if exists]
- **GitHub Issues:** https://github.com/Xylop90/Realme-C63/issues

## Version

- **Checklist Version:** 1.0
- **Last Updated:** 2026-01-10
- **Compatible ROM:** Xtreme XA-vI v1.0
