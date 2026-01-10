# Custom ROM Installation Guide - Xtreme XA-vI

## Overview
This comprehensive guide walks you through the complete process of installing Xtreme XA-vI custom ROM on your Realme C63 device. Follow each step carefully to ensure a successful installation.

## Prerequisites Checklist

Before beginning the installation, verify you have completed:

- ✅ **Unlocked bootloader** ([Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md))
- ✅ **TWRP Recovery installed** ([TWRP Installation Guide](TWRP_INSTALLATION.md))
- ✅ **Device battery** charged to at least 70%
- ✅ **Complete backup** of all important data
- ✅ **USB cable** (original recommended)
- ✅ **Computer** with ADB and Fastboot installed
- ✅ **Downloaded ROM files:**
  - Xtreme XA-vI ROM ZIP file
  - GApps package (optional, if needed)
  - Magisk ZIP (optional, for root)

## Important Warnings ⚠️

- **This will erase all data on your device**
- **Take a complete backup before proceeding**
- **Ensure you download the correct ROM for Realme C63**
- **Do not interrupt the flashing process**
- **Keep your device charged throughout the process**
- **Warranty may be voided by installing custom ROMs**
- **Proceed at your own risk**

## Download Required Files

### 1. Xtreme XA-vI ROM
- Download the latest Xtreme XA-vI ROM ZIP from the releases section
- Verify file integrity (check MD5/SHA256 if provided)
- File size should be approximately 1-2 GB

### 2. GApps (Google Apps) - Optional
If the ROM doesn't include Google apps:
- Download from: https://opengapps.org/
- Platform: ARM64
- Android Version: 14
- Variant: Nano or Micro (recommended for this device)

### 3. Magisk (Root) - Optional
For root access:
- Download latest Magisk ZIP from: https://github.com/topjohnwu/Magisk/releases
- Version: 26.0 or higher

## Transfer Files to Device

### Option 1: Transfer While in System
1. Connect device to computer via USB
2. Enable File Transfer mode
3. Copy ROM ZIP (and optional files) to internal storage or SD card
4. Remember the location

### Option 2: Transfer via ADB Sideload
1. Boot into TWRP recovery
2. Go to **Advanced → ADB Sideload**
3. Swipe to start sideload
4. On computer, run:
   ```bash
   adb sideload xtreme-xa-vi-realme-c63.zip
   ```

### Option 3: Use USB OTG
1. Copy files to USB flash drive
2. Boot into TWRP
3. Connect USB OTG adapter with flash drive
4. Install from USB OTG storage

## Installation Process

### Step 1: Boot into TWRP Recovery

**Method A - Using ADB:**
```bash
adb reboot recovery
```

**Method B - Hardware Keys:**
1. Power off your device completely
2. Press and hold **Volume Up + Power** buttons
3. Release when TWRP logo appears

### Step 2: Create a Backup (Highly Recommended)

1. In TWRP, tap **Backup**
2. Select partitions to backup:
   - ✓ Boot
   - ✓ System
   - ✓ Data
   - ✓ Vendor (if available)
3. Swipe to start backup
4. Wait for completion (10-20 minutes)

### Step 3: Wipe Data (Clean Install)

For a clean installation:

1. Tap **Wipe** in TWRP main menu
2. Tap **Advanced Wipe**
3. Select the following partitions:
   - ✓ Dalvik / ART Cache
   - ✓ Cache
   - ✓ System
   - ✓ Data
   - **DO NOT** select Internal Storage or SD Card
4. **Swipe to Wipe**
5. Wait for completion

**Note:** For dirty flash (upgrade), only wipe Dalvik/Cache. Skip System and Data.

### Step 4: Install Xtreme XA-vI ROM

1. Return to TWRP main menu
2. Tap **Install**
3. Navigate to the ROM ZIP file location
4. Tap on **xtreme-xa-vi-realme-c63.zip**
5. **Swipe to Confirm Flash**
6. Wait for installation to complete (5-10 minutes)
7. **Do not reboot yet**

### Step 5: Install GApps (Optional)

If you need Google apps:

1. Tap **Install** again (or go back if still in install screen)
2. Select the **GApps ZIP** file
3. **Swipe to Confirm Flash**
4. Wait for installation to complete
5. **Do not reboot yet**

### Step 6: Install Magisk (Optional)

For root access:

1. Tap **Install** again
2. Select the **Magisk ZIP** file
3. **Swipe to Confirm Flash**
4. Wait for installation to complete

### Step 7: Clear Cache and Reboot

1. Tap **Wipe Cache/Dalvik** button (if prompted)
2. Or manually: **Wipe → Advanced Wipe → Dalvik/Cache + Cache**
3. Return to main menu
4. Tap **Reboot**
5. Select **System**
6. If prompted about TWRP app installation, swipe **Do Not Install**

### Step 8: First Boot

- **First boot takes 5-15 minutes** - be patient!
- Device may reboot multiple times - this is normal
- You'll see the Xtreme XA-vI boot animation
- Eventually, you'll reach the setup screen

## Post-Installation Setup

### Initial Configuration

1. **Select language** and region
2. **Connect to Wi-Fi**
3. **Set up Google account** (if GApps installed)
4. **Configure security** (PIN/password/fingerprint)
5. **Restore apps and data** from backup (optional)

### Verify Installation

Check the following to confirm successful installation:

1. **Settings → About Phone**
   - ROM Version: Should show "Xtreme XA-vI"
   - Android Version: Should show Android 14
   - Build Date: Should match ROM release date

2. **Test basic functions:**
   - ✓ Wi-Fi connectivity
   - ✓ Mobile data
   - ✓ Bluetooth
   - ✓ Camera
   - ✓ Audio/speakers
   - ✓ Touchscreen
   - ✓ Fingerprint sensor

3. **Check root status** (if Magisk installed):
   - Open Magisk Manager app
   - Should show "Installed" status

### Install Essential Apps

1. Open Play Store (if GApps installed)
2. Sign in with Google account
3. Install your essential apps
4. Restore app data if needed

## Troubleshooting

### Device stuck on boot logo
- **Wait at least 15 minutes** before taking action
- If still stuck, boot to TWRP and:
  - Wipe Cache and Dalvik Cache
  - Reboot
- If problem persists, restore TWRP backup or re-flash ROM

### Boot loop (continuous rebooting)
- Boot into TWRP
- Wipe Cache and Dalvik Cache
- If issue continues, perform a clean installation again
- Ensure you downloaded the correct ROM version

### No signal / Mobile network not working
- Check APN settings: Settings → Mobile Network → Access Point Names
- Reset network settings: Settings → System → Reset → Reset Wi-Fi, mobile & Bluetooth
- Re-flash the ROM with proper wipe

### Wi-Fi/Bluetooth not working
- Toggle Airplane mode on/off
- Reset network settings
- Re-flash ROM ensuring proper wipe

### Apps crashing or not installing
- Wipe Dalvik/ART Cache in TWRP
- Clear app data for problematic apps
- Reinstall the app
- Check if GApps were properly installed

### Camera not working
- Clear camera app data and cache
- Check if camera permissions are granted
- Try a third-party camera app
- Re-flash ROM if issue persists

### Battery draining fast
- Wait 2-3 days for battery optimization to kick in
- Check battery usage: Settings → Battery
- Disable unnecessary background apps
- Reduce screen brightness and refresh rate

### Device overheating
- This is normal during first few days as ROM optimizes
- Avoid heavy usage during initial setup
- If persistent, check for rogue apps in battery usage

### Cannot access internal storage
- This may happen if data is encrypted
- Boot to TWRP → Wipe → Format Data
- Type "yes" to confirm (this erases all data)

## Updating the ROM

### Dirty Flash (Recommended for Updates)

1. Download new ROM version
2. Boot to TWRP
3. Take a backup (recommended)
4. Wipe only **Dalvik/Cache**
5. Flash new ROM ZIP
6. Reboot
7. No need to re-flash GApps or Magisk (usually)

### Clean Flash (For Major Updates)

1. Follow the full installation process again
2. Perform complete wipe (except internal storage)
3. Flash ROM, GApps, and Magisk
4. This is like a fresh installation

## Reverting to Stock ROM

If you need to return to stock:

1. Download official stock ROM for Realme C63
2. Flash using fastboot or official flash tool
3. This will erase TWRP and custom ROM
4. See device-specific guides for stock ROM flashing

## Performance Optimization Tips

1. **Disable animations:** Settings → Developer Options → Animation scales → 0.5x
2. **Limit background processes:** Developer Options → Background process limit
3. **Use battery saver mode** when needed
4. **Disable unused connectivity:** Turn off Wi-Fi, Bluetooth, GPS when not needed
5. **Clear cache regularly:** Settings → Storage → Cache data
6. **Uninstall bloatware** and unused apps

## FAQ

**Q: Will I lose my data?**  
A: Yes, clean installation erases all data. Always backup first.

**Q: Can I install this ROM without unlocking bootloader?**  
A: No, unlocked bootloader is mandatory for custom ROM installation.

**Q: How often should I update the ROM?**  
A: Check for updates monthly, or when important fixes are released.

**Q: Can I use banking apps with this ROM?**  
A: Some banking apps may not work on rooted devices. Use Magisk Hide feature to hide root.

**Q: Will OTA updates work?**  
A: Depends on ROM support. Check ROM changelog for OTA availability.

**Q: Can I downgrade to previous ROM version?**  
A: Yes, but perform a clean flash when downgrading.

## Support and Community

- **GitHub Issues:** Report bugs and request features
- **XDA Developers:** Join Realme C63 community
- **Telegram/Discord:** Join official ROM community groups
- **Documentation:** Check [CHANGELOG.md](CHANGELOG.md) for latest updates

## Additional Resources

- [Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md)
- [TWRP Installation Guide](TWRP_INSTALLATION.md)
- [Rooting Guide](ROOTING_GUIDE.md)
- [Development Guide](DEVELOPMENT.md)
- [Changelog](CHANGELOG.md)

---

**Last Updated:** 2026-01-10  
**ROM Version:** 1.0  
**Author:** Xylop90 / Elektronikx-Center-Matte

**Remember:** Always backup, follow instructions carefully, and be patient during the process!
