# Rooting Guide for Realme C63 (RMX3939)

## Overview
This comprehensive guide provides step-by-step instructions for rooting your Realme C63 (RMX3939) device using Magisk. Rooting gives you superuser access to your device, allowing for advanced customization and system-level modifications.

## Prerequisites

### Required Items
- Realme C63 (RMX3939) with **unlocked bootloader** ([See Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md))
- Computer with ADB and Fastboot installed
- USB cable (preferably original)
- At least 80% battery charge
- Backup of all important data
- Internet connection for downloading files

### Required Downloads
- **Magisk APK** (Latest stable version from official GitHub)
  - Download: https://github.com/topjohnwu/Magisk/releases/latest
  - Recommended: Magisk v26.0 or newer
- **Stock Boot Image** for RMX3939 (matching your firmware version)
  - Check your firmware version: Settings → About Phone → Build Number
- **ADB Platform Tools** (if not already installed)
  - Download: https://developer.android.com/studio/releases/platform-tools

## Important Warnings ⚠️

- **Your bootloader MUST be unlocked before attempting to root**
- **This may void your warranty**
- **Rooting can cause stability issues if done incorrectly**
- **Always backup your data before proceeding**
- **Use only official Magisk releases**
- **Do not root system-critical apps like banking apps without proper configuration**

## Method 1: Patching Boot Image (Recommended)

This is the safest and most reliable method for rooting Realme C63.

### Step 1: Prepare Your Device
1. Ensure USB Debugging is enabled:
   - Go to **Settings** → **About Phone**
   - Tap **Build Number** 7 times
   - Go back to **Settings** → **Developer Options**
   - Enable **USB Debugging**

2. Connect device to computer and verify connection:
   ```bash
   adb devices
   ```

### Step 2: Extract Boot Image from Device

If you don't have the stock boot image, extract it from your device:

```bash
# List all partitions to find boot partition
adb shell ls -l /dev/block/bootdevice/by-name/

# Identify boot partition (usually boot_a or boot)
# Extract boot image
adb shell "su -c 'dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot.img'"

# Or for A/B devices:
adb shell "su -c 'dd if=/dev/block/bootdevice/by-name/boot_a of=/sdcard/boot.img'"

# Pull the boot image to your computer
adb pull /sdcard/boot.img
```

**Alternative**: Download the stock firmware for your exact build number and extract boot.img from it.

### Step 3: Install Magisk App

1. Transfer Magisk APK to your device:
   ```bash
   adb push Magisk-v26.0.apk /sdcard/
   ```

2. Install it on your device:
   ```bash
   adb install Magisk-v26.0.apk
   ```
   
   Or install manually from the device's file manager.

### Step 4: Patch Boot Image

1. Transfer the boot.img to your device:
   ```bash
   adb push boot.img /sdcard/Download/
   ```

2. On your device:
   - Open the **Magisk** app
   - Tap **Install** button
   - Select **Select and Patch a File**
   - Navigate to `/sdcard/Download/` and select `boot.img`
   - Tap **LET'S GO** to start patching
   - Wait for the process to complete

3. The patched image will be saved as `magisk_patched_[random].img` in the Download folder

4. Pull the patched image to your computer:
   ```bash
   adb pull /sdcard/Download/magisk_patched_[random].img
   ```

### Step 5: Flash Patched Boot Image

1. Reboot device to bootloader:
   ```bash
   adb reboot bootloader
   ```

2. Flash the patched boot image:
   ```bash
   fastboot flash boot magisk_patched_[random].img
   ```
   
   For A/B devices, flash to both slots:
   ```bash
   fastboot flash boot_a magisk_patched_[random].img
   fastboot flash boot_b magisk_patched_[random].img
   ```

3. Reboot to system:
   ```bash
   fastboot reboot
   ```

### Step 6: Verify Root Access

1. Wait for device to boot completely (may take longer than usual on first boot)
2. Open the Magisk app
3. You should see:
   - **Magisk** version number
   - **App** version number
   - **Ramdisk**: Yes
   - **Status**: Installed

4. Test root access:
   ```bash
   adb shell
   su
   # You should now have root prompt (#)
   ```

## Method 2: Direct Boot (Temporary Root)

This method provides temporary root without permanently modifying the boot partition. Root access is lost on reboot.

### Steps:

1. Patch boot image following Steps 1-4 from Method 1

2. Instead of flashing, boot directly from patched image:
   ```bash
   adb reboot bootloader
   fastboot boot magisk_patched_[random].img
   ```

3. Once booted, open Magisk app and tap **Install** → **Direct Install** to make it permanent

## Post-Root Configuration

### 1. Configure Magisk Settings

Open Magisk app and configure:
- **Systemless Hosts**: Enable (recommended)
- **Zygisk**: Enable (for advanced module support)
- **Enforce DenyList**: Enable (to hide root from specific apps)
- **Biometric Authentication**: Enable (for security)

### 2. Configure DenyList (Hide Root)

To hide root from banking apps, Netflix, etc.:

1. In Magisk, go to **Settings**
2. Enable **Enforce DenyList**
3. Tap **Configure DenyList**
4. Select apps that should not detect root:
   - Banking apps
   - Payment apps (Google Pay, PayPal, etc.)
   - Netflix, Disney+, etc.
   - Games with anti-cheat
   - Work apps

### 3. Hide Magisk App

To further hide from detection:

1. Magisk **Settings** → **Hide the Magisk app**
2. Enter a random package name (e.g., "com.android.settings")
3. The app will be renamed and hidden

### 4. Install Essential Magisk Modules (Optional)

Popular modules for Realme C63:
- **Busybox for Android NDK**
- **SQLite 3**: Better database performance
- **Debloater**: Remove unwanted system apps
- **ViPER4Android FX**: Audio enhancement
- **Systemless Xposed** (if needed)

Install modules:
1. Download module ZIP file
2. Open Magisk → **Modules**
3. Tap **Install from storage**
4. Select module ZIP
5. Reboot after installation

## Verification Steps

### Check Root Status
```bash
# Via ADB
adb shell
su
id
# Should show: uid=0(root) gid=0(root)

# Via Terminal app on device
su
whoami
# Should show: root
```

### Check SafetyNet Status (Optional)

1. Open Magisk app
2. Go to **Settings**
3. Scroll to **SafetyNet Check**
4. Tap **Check Status**
5. Both should show green:
   - **basicIntegrity**: Pass
   - **ctsProfile**: Pass

Note: SafetyNet may fail even with proper configuration. Use Universal SafetyNet Fix module if needed.

## Troubleshooting

### Boot Loop After Flashing
1. Boot to bootloader:
   - Power off device
   - Hold Volume Down + Power
2. Flash stock boot image:
   ```bash
   fastboot flash boot stock_boot.img
   fastboot reboot
   ```

### Magisk App Shows "N/A"
- **Ramdisk: N/A** means boot image patching failed
- Re-patch boot image ensuring correct file
- Verify you're using matching boot image for your firmware

### Root Access Denied
1. Open Magisk app
2. Go to **Superuser** tab
3. Check if requesting app is listed
4. Grant or deny access as needed

### SafetyNet Fails
1. Enable **Zygisk** in Magisk settings
2. Install **Universal SafetyNet Fix** module
3. Enable **Enforce DenyList**
4. Add problematic apps to DenyList
5. Reboot and test again

### Device Stuck in Fastboot
```bash
fastboot reboot
# Or
fastboot reboot recovery
```

### OTA Updates Break Root
- After OTA update, root is lost
- Re-patch new boot image from updated firmware
- Flash patched boot image again
- Or use Magisk's built-in OTA installation method

### Magisk Modules Cause Issues
1. Boot to safe mode (Magisk disables modules)
   - Volume Down during boot logo
2. Uninstall problematic module
3. Reboot normally

## Unrooting (Restoring Stock)

### Method 1: Flash Stock Boot Image
```bash
adb reboot bootloader
fastboot flash boot stock_boot.img
fastboot reboot
```

### Method 2: Uninstall from Magisk
1. Open Magisk app
2. Tap **Uninstall**
3. Select **Restore Images**
4. Reboot

### Method 3: Complete Restore (Relock Bootloader)
⚠️ **WARNING**: This will wipe all data!

```bash
adb reboot bootloader
fastboot flashing lock
# Confirm on device
fastboot reboot
```

## Important Security Considerations

### Do's ✅
- Keep Magisk updated to latest stable version
- Only install modules from trusted sources
- Use DenyList for sensitive apps
- Backup regularly (including boot images)
- Read module descriptions and reviews before installing
- Use Magisk's built-in SafetyNet checks

### Don'ts ❌
- Don't grant root access to unknown apps
- Don't install modules from untrusted sources
- Don't modify system partitions manually if unsure
- Don't ignore Magisk security warnings
- Don't use root for everyday tasks when not needed
- Don't skip backups before major changes

## Advanced Topics

### Restoring Boot Image Backups
Magisk automatically creates backups:
```bash
adb pull /data/adb/magisk/stock_boot_[random].img
```

### Installing Magisk via Recovery (TWRP)
1. Download Magisk APK and rename to `Magisk-v26.0.zip`
2. Boot to TWRP recovery
3. Install → Select Magisk ZIP
4. Swipe to confirm
5. Reboot to system

### Using Magisk Manager via ADB
```bash
# Grant root to an app
adb shell su -c "pm grant com.example.app android.permission.WRITE_SECURE_SETTINGS"

# List root-enabled apps
adb shell su -c "magisk --sqlite 'SELECT * FROM policies'"
```

## Resources and Links

### Official Resources
- **Magisk GitHub**: https://github.com/topjohnwu/Magisk
- **Magisk Documentation**: https://topjohnwu.github.io/Magisk/
- **Magisk Modules Repository**: https://github.com/Magisk-Modules-Repo

### Community Resources
- **XDA Developers - Realme C63**: https://forum.xda-developers.com/
- **Realme Community Forums**: https://c.realme.com/
- **Reddit - r/Magisk**: https://reddit.com/r/Magisk

### Related Guides
- [Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md)
- [TWRP Installation Guide](TWRP_INSTALLATION.md)
- [ROM Installation Guide](INSTALLATION.md)

## Getting Help

If you encounter issues:
1. Check the Troubleshooting section above
2. Review Magisk's official documentation
3. Search XDA forums for similar issues
4. Check GitHub issues for known problems
5. Create a new issue with:
   - Device model (Realme C63 RMX3939)
   - Firmware version
   - Magisk version
   - Detailed error description
   - Log files (from Magisk app)

## Support This Project

If this guide helped you:
- ⭐ Star the repository on GitHub
- 🐛 Report bugs and issues
- 📝 Suggest improvements
- 🤝 Share with others

---

**Last Updated**: 2026-01-10  
**Guide Version**: 1.0  
**Author**: Xylop90 / Elektronikx-Center-Matte

**Disclaimer**: Rooting your device may void warranty, cause data loss, or brick your device if done incorrectly. Proceed at your own risk. The author is not responsible for any damage to your device.
