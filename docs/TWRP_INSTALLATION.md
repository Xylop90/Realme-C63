# TWRP Installation Guide for Realme C63 (RMX3939)

## Overview
TWRP (Team Win Recovery Project) is a custom recovery that replaces the stock recovery on Android devices. It provides advanced features for backup, restore, and flashing custom ROMs, kernels, and mods.

## Prerequisites

### Required
- ✅ **Unlocked bootloader** ([See Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md))
- ✅ Computer with ADB and Fastboot installed
- ✅ USB cable (preferably original)
- ✅ At least 70% battery charge
- ✅ TWRP image file for Realme C63 (RMX3939)
- ✅ USB Debugging enabled

### Important Notes
- ⚠️ This requires unlocked bootloader
- ⚠️ Make backups before proceeding
- ⚠️ Stock recovery will be replaced
- ⚠️ OTA updates will no longer work

## Download TWRP

### Official Sources
1. **TWRP Official Website**
   - URL: https://twrp.me/Devices/
   - Search for "Realme C63" or "RMX3939"
   - Download the `.img` file

2. **XDA Developers Forum**
   - Search for "Realme C63 TWRP"
   - Or "RMX3939 TWRP"
   - Download from trusted developers
   - Check for device-specific builds

### File Naming
TWRP file typically named:
- `twrp-3.x.x-x-RMX3939.img`
- Or `recovery-twrp-3.x.x-RMX3939.img`

### Verification
- Verify file integrity (MD5/SHA256)
- Check developer reputation
- Read user feedback before flashing
- Ensure it's specifically for RMX3939

## Installation Methods

## Method 1: Temporary Boot (Recommended First)

This method lets you test TWRP without permanently flashing it.

### Step 1: Prepare Device
```bash
# Enable USB Debugging if not already done
# Connect device to computer
# Verify connection
adb devices
```

### Step 2: Boot to Fastboot
```bash
adb reboot bootloader
```

Or manually:
- Power off device
- Hold **Volume Down + Power**

### Step 3: Verify Fastboot Connection
```bash
fastboot devices
```

Should show your device ID.

### Step 4: Temporarily Boot TWRP
```bash
fastboot boot twrp-3.x.x-x-RMX3939.img
```

**Notes:**
- Replace filename with your actual TWRP file
- Device will boot into TWRP
- TWRP is not permanently installed yet
- Regular reboot returns to stock recovery

### Step 5: Test TWRP
1. Device should boot into TWRP recovery
2. Test basic functions:
   - Touch screen responsiveness
   - Button navigation
   - File browsing
   - Backup creation
3. If everything works, proceed to permanent installation

## Method 2: Permanent Installation via Fastboot

### Step 1: Boot to Fastboot Mode
```bash
adb reboot bootloader
```

### Step 2: Flash TWRP to Recovery Partition
```bash
fastboot flash recovery twrp-3.x.x-x-RMX3939.img
```

**For A/B devices (if applicable):**
```bash
fastboot flash recovery_a twrp-3.x.x-x-RMX3939.img
fastboot flash recovery_b twrp-3.x.x-x-RMX3939.img
```

### Step 3: Prevent Stock Recovery Restoration

⚠️ **Critical Step:**
Some devices automatically restore stock recovery on first boot. To prevent this:

**Option A: Boot directly to TWRP** (Do NOT boot to system first)
```bash
# Do not use 'fastboot reboot'
# Instead:
fastboot reboot recovery
```

**Option B: Using hardware buttons:**
1. After flashing, disconnect USB
2. Hold **Volume Up + Power** immediately
3. Keep holding until TWRP logo appears
4. This boots directly into TWRP

### Step 4: Disable Recovery Restoration in TWRP

Once in TWRP:
1. Tap **Mount**
2. Select **System**
3. Go back to main menu
4. Tap **Advanced** → **File Manager**
5. Navigate to `/system/recovery-from-boot.p`
6. Delete this file if it exists
7. Or rename it to `recovery-from-boot.bak`

Alternative using TWRP Terminal:
1. Tap **Advanced** → **Terminal**
2. Enter:
   ```bash
   mount /system
   rm /system/recovery-from-boot.p
   ```

### Step 5: Reboot to System

**Important:** First boot after TWRP installation:
1. In TWRP, tap **Reboot**
2. Select **System**
3. If prompted "No OS Installed," swipe to reboot anyway
4. Wait for system to boot (may take longer)

## Method 3: Permanent Installation via Existing TWRP

If you already have TWRP or another custom recovery:

### Step 1: Transfer TWRP Image
```bash
adb push twrp-3.x.x-x-RMX3939.img /sdcard/
```

### Step 2: Boot to Current Recovery
```bash
adb reboot recovery
```

### Step 3: Flash via Recovery
1. In recovery, tap **Install**
2. Tap **Install Image** (button at bottom)
3. Navigate to TWRP image file
4. Select **Recovery** as target partition
5. Swipe to flash
6. Reboot to recovery to load new TWRP

## Booting into TWRP

### Method 1: Using ADB
```bash
adb reboot recovery
```

### Method 2: Hardware Keys
1. Power off device completely
2. Hold **Volume Up + Power** simultaneously
3. Release when TWRP logo appears
4. Wait for TWRP to load

### Method 3: From Bootloader
```bash
# Boot to bootloader
adb reboot bootloader

# Boot to recovery
fastboot boot twrp-3.x.x-x-RMX3939.img
# Or if permanently installed:
fastboot reboot recovery
```

## First-Time TWRP Setup

### Initial Screen
When TWRP loads first time:
1. **Language Selection**
   - Choose your preferred language
2. **Keep System Read Only?**
   - Swipe to allow modifications
   - This is necessary for most operations

### TWRP Main Menu

Main buttons explained:
- **Install**: Flash ZIPs (ROMs, mods, Magisk)
- **Wipe**: Erase data/cache/system
- **Backup**: Create full backups
- **Restore**: Restore from backups
- **Mount**: Mount/unmount partitions
- **Settings**: Configure TWRP
- **Advanced**: Advanced tools
- **Reboot**: Reboot options

## Essential TWRP Operations

### Creating a Backup (Nandroid)

**Very Important:** Always backup before making changes!

1. Tap **Backup** in TWRP
2. Select partitions to backup:
   - ✅ **Boot** (kernel)
   - ✅ **System** (Android OS)
   - ✅ **Data** (apps and user data)
   - ⬜ Cache (optional, not critical)
   - ⬜ Recovery (optional)
3. Swipe slider to begin backup
4. Wait for completion (5-20 minutes depending on size)
5. Store backup on external SD or computer:
   ```bash
   adb pull /sdcard/TWRP/BACKUPS/ ./twrp-backup/
   ```

### Restoring a Backup

1. Tap **Restore**
2. Select backup date/time
3. Choose partitions to restore
4. Swipe to restore
5. Wait for completion
6. Reboot to system

### Wiping Data

**For Custom ROM Installation:**
1. Tap **Wipe**
2. Tap **Advanced Wipe**
3. Select:
   - ✅ Dalvik/ART Cache
   - ✅ Cache
   - ✅ System
   - ✅ Data
   - ⬜ Internal Storage (only if needed)
4. Swipe to wipe

**Factory Reset (Keep ROM):**
1. Tap **Wipe**
2. Swipe **Factory Reset**

### Installing ZIPs

**For ROMs, Magisk, mods:**
1. Transfer ZIP to device:
   ```bash
   adb push file.zip /sdcard/
   ```
2. In TWRP, tap **Install**
3. Navigate to ZIP file
4. Tap file to select
5. Swipe to confirm flash
6. Wait for completion
7. Tap **Reboot System**

### Using ADB Sideload

**For installing without file transfer:**
1. In TWRP, tap **Advanced** → **ADB Sideload**
2. Swipe to start sideload
3. On computer:
   ```bash
   adb sideload file.zip
   ```
4. Wait for completion
5. Reboot

## TWRP Settings & Configuration

### Recommended Settings

1. **Settings** → **General Settings**:
   - ✅ ZIP signature verification (security)
   - ✅ Use rm -rf instead of formatting
   - ✅ Skip MD5 generation (faster backups)

2. **Settings** → **Screen**:
   - Adjust screen timeout
   - Adjust brightness

3. **Settings** → **Vibration**:
   - Configure haptic feedback

4. **Settings** → **Storage**:
   - Set default storage location
   - Configure backup location

### Protecting TWRP with Password

1. **Settings** → **Security**
2. Set TWRP password
3. Enables encryption for backups

## Troubleshooting

### TWRP Won't Boot

**Symptoms:** Device boots to black screen or bootloop

**Solutions:**
1. Flash TWRP again:
   ```bash
   fastboot flash recovery twrp-3.x.x-x-RMX3939.img
   ```

2. Try different TWRP version:
   - Check XDA for alternative builds
   - Try unofficial builds if official unavailable

3. Flash via alternative recovery

4. Restore stock recovery and try again

### Touch Screen Not Working

**Solutions:**
- Use hardware buttons for navigation
  - Volume = Up/Down
  - Power = Select/Back
- Try different TWRP build
- Check for device-specific touch fixes on XDA

### Cannot Mount Partitions

**Error:** "Failed to mount /system"

**Solutions:**
1. In TWRP, tap **Wipe** → **Format Data**
2. Type `yes` to confirm
3. Reboot to TWRP
4. Try mounting again

If still failing:
```bash
# Via TWRP Terminal
mount -t ext4 /dev/block/by-name/system /system
```

### Backup Fails

**Causes:**
- Insufficient storage space
- Corrupted SD card
- Partition mount issues

**Solutions:**
- Free up space
- Backup to different location
- Try smaller backup (exclude System)
- Check SD card health

### TWRP Replaced by Stock Recovery

**This happens if:**
- Booted to system before disabling recovery restoration
- Recovery-from-boot.p not removed

**Fix:**
1. Flash TWRP again
2. Boot directly to TWRP (don't boot system)
3. Delete `/system/recovery-from-boot.p`
4. Then boot to system

### "No OS Installed" Warning

**When:** Booting to system after fresh TWRP install

**Solution:**
- This is normal if you just flashed TWRP
- Swipe to reboot anyway
- System will boot normally

### Device Encrypted, Cannot Access Data

**Solution:**
1. Enter PIN/password when TWRP prompts
2. If TWRP doesn't support encryption:
   - Install DM-Verity disabler
   - Or format data (loses everything)

## Advanced TWRP Features

### TWRP Terminal Commands

Access: **Advanced** → **Terminal**

Useful commands:
```bash
# Mount system
mount /system

# List partitions
ls -la /dev/block/bootdevice/by-name/

# Check partition info
df -h

# Fix permissions
chmod 755 /system/bin/*

# Reboot commands
reboot
reboot recovery
reboot bootloader
```

### File Manager

Access: **Advanced** → **File Manager**

Features:
- Browse all files and folders
- Copy/move/delete files
- Change permissions (chmod)
- Edit text files
- Extract archives

### Partition Management

Access: **Wipe** → **Advanced Wipe** → **Repair or Change File System**

Options:
- Repair file system
- Change file system (ext2/ext3/ext4)
- Resize partition (advanced!)

### Flashing Boot Images

For kernels or Magisk patched boot:
1. Tap **Install**
2. Tap **Install Image**
3. Select `.img` file
4. Choose **Boot** partition
5. Swipe to flash

## Keeping TWRP Updated

### Check for Updates
1. Visit TWRP official website regularly
2. Check XDA forums for newer builds
3. Look for changelog and improvements

### Updating TWRP
1. Download new TWRP image
2. Flash via fastboot (Method 2 above)
3. Or flash via current TWRP (Method 3)
4. Your backups remain safe

## Uninstalling TWRP

### Restore Stock Recovery

**Reason:** Return to stock for OTA updates

1. Download stock recovery for RMX3939
2. Flash via fastboot:
   ```bash
   fastboot flash recovery stock-recovery.img
   fastboot reboot
   ```

### Extract Stock Recovery

If you don't have stock recovery image:
1. Download stock firmware
2. Extract recovery.img from firmware
3. Flash as shown above

## Alternative Custom Recoveries

### OrangeFox Recovery
- Based on TWRP
- Additional features
- Better aesthetics
- Check XDA for availability

### PBRP (Pitch Black Recovery)
- Dark themed TWRP variant
- Additional customization
- May be available for RMX3939

## Best Practices

### Do's ✅
- Always create backup before major changes
- Store backups on external storage or computer
- Test TWRP boot before permanent installation
- Keep TWRP updated
- Use official or trusted builds only
- Verify downloads (checksums)

### Don'ts ❌
- Don't wipe Internal Storage unless necessary
- Don't flash ZIPs from untrusted sources
- Don't modify partitions unless you know what you're doing
- Don't interrupt flash/backup processes
- Don't forget to backup before experiments

## Related Resources

### This Repository
- [Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md)
- [Rooting Guide](ROOTING_GUIDE.md)
- [ROM Installation](INSTALLATION.md)

### External Resources
- **TWRP Official**: https://twrp.me/
- **XDA Forums**: https://forum.xda-developers.com/
- **TWRP FAQ**: https://twrp.me/faq/

### Video Tutorials
- Search "TWRP tutorial" on YouTube
- Watch "How to use TWRP recovery"
- Device-specific guides preferred

## Getting Help

### Before Asking
1. Read this guide thoroughly
2. Check TWRP official documentation
3. Search XDA forums
4. Review troubleshooting section

### When Asking for Help
Include:
- Device: Realme C63 (RMX3939)
- TWRP version
- What you're trying to do
- Exact error messages
- Screenshots if possible
- Steps you've tried

---

**Last Updated**: 2026-01-10  
**Guide Version**: 1.0  
**Author**: Xylop90 / Elektronikx-Center-Matte

**Disclaimer**: Installing custom recovery may void warranty and can potentially brick your device if done incorrectly. Proceed at your own risk. Always backup your data.

---

*TWRP opens up endless possibilities for your Realme C63! 🛠️*
