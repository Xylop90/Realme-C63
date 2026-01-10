# Rooting Guide - Magisk Installation for Realme C63

## Overview
This guide provides detailed instructions for rooting your Realme C63 device using Magisk. Root access allows you to modify system files, install root-only apps, and unlock advanced customization features.

## What is Root?

**Root access** (also called superuser access) gives you administrative privileges on your Android device, allowing you to:

- Modify system files and settings
- Install root-required apps (ad blockers, backup tools, etc.)
- Remove bloatware and pre-installed apps
- Install custom kernels and mods
- Use Xposed Framework or similar tools
- Advanced backup and restore capabilities
- Full control over CPU, GPU, and performance settings

## What is Magisk?

**Magisk** is the most popular rooting solution that:

- Provides systemless root (doesn't modify system partition)
- Passes SafetyNet checks (banking apps work)
- Supports modules for additional features
- Allows root hiding for specific apps
- Can be easily uninstalled if needed
- Open-source and actively maintained

## Prerequisites

Before rooting your device, ensure you have:

- ✅ **Unlocked bootloader** ([Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md))
- ✅ **TWRP Recovery** installed ([TWRP Installation Guide](TWRP_INSTALLATION.md))
- ✅ **Custom ROM** installed (Xtreme XA-vI or similar) - recommended
- ✅ **Device battery** at least 60% charged
- ✅ **USB cable** for computer connection
- ✅ **Backup** of important data
- ✅ **USB drivers** installed on computer
- ✅ **ADB and Fastboot** tools installed

## Important Warnings ⚠️

- **Warranty will be voided** (if not already voided by unlocking bootloader)
- **Some apps may not work** (banking apps, Netflix, etc.) - can be resolved with Magisk Hide
- **Security risks** if root is misused
- **Potential for boot loops** if done incorrectly
- **OTA updates may not work** without uninstalling Magisk first
- **Always backup** before rooting
- **Proceed at your own risk**

## Download Magisk

### Latest Magisk Release

1. Visit the official Magisk GitHub repository:
   - https://github.com/topjohnwu/Magisk/releases

2. Download the latest stable release:
   - Look for the latest version (e.g., v26.4)
   - Download **Magisk-v26.x.apk** file
   - Also download **Magisk-v26.x.zip** (for TWRP installation)

3. Verify the download:
   - Check file size matches the one on GitHub
   - Verify SHA256 checksum if provided

## Installation Methods

### Method 1: Install via TWRP (Recommended)

This is the easiest and most reliable method.

#### Step 1: Transfer Magisk ZIP to Device

1. Download **Magisk-v26.x.zip** to your computer
2. Connect device via USB
3. Copy the ZIP file to internal storage or SD card

#### Step 2: Boot into TWRP Recovery

**Via ADB:**
```bash
adb reboot recovery
```

**Via Hardware Keys:**
1. Power off device
2. Hold **Volume Up + Power** buttons
3. Release when TWRP appears

#### Step 3: Create Backup (Optional but Recommended)

1. In TWRP, tap **Backup**
2. Select **Boot** partition at minimum
3. Swipe to backup
4. This allows you to restore if something goes wrong

#### Step 4: Install Magisk ZIP

1. Tap **Install** in TWRP main menu
2. Navigate to the Magisk ZIP file location
3. Tap on **Magisk-v26.x.zip**
4. **Swipe to Confirm Flash**
5. Wait for installation to complete
6. You should see "Successful" message

#### Step 5: Reboot and Install Magisk Manager

1. Tap **Reboot System**
2. Wait for device to boot (may take a few minutes)
3. Once booted, install the **Magisk-v26.x.apk** file
4. Open Magisk Manager app
5. It should show "Installed" status

### Method 2: Patch Boot Image (Advanced)

This method is useful if you don't have TWRP or prefer direct boot image patching.

#### Step 1: Extract Boot Image

1. Download your ROM's boot image or extract it from the ROM ZIP
2. Transfer **boot.img** to your device's internal storage

#### Step 2: Install Magisk Manager APK

1. Transfer **Magisk-v26.x.apk** to your device
2. Install the APK
3. Open Magisk Manager

#### Step 3: Patch Boot Image

1. In Magisk Manager, tap **Install**
2. Select **Select and Patch a File**
3. Navigate to and select **boot.img**
4. Tap **LET'S GO**
5. Magisk will patch the boot image
6. Patched file will be saved as **magisk_patched_[random].img** in Downloads folder

#### Step 4: Transfer Patched Boot to Computer

1. Connect device to computer
2. Copy **magisk_patched_[random].img** from device to computer
3. Note the exact filename

#### Step 5: Flash Patched Boot

1. Boot device into bootloader mode:
   ```bash
   adb reboot bootloader
   ```

2. Flash the patched boot image:
   ```bash
   fastboot flash boot magisk_patched_[random].img
   ```
   Replace with your actual filename.

3. Reboot:
   ```bash
   fastboot reboot
   ```

4. Device will boot with Magisk installed

## Verify Root Access

### Check Magisk Manager

1. Open **Magisk Manager** app
2. You should see:
   - **Magisk:** Installed (version number)
   - **App:** Latest version
   - **Ramdisk:** Yes (or N/A)
   - **SafetyNet:** May show unchecked initially

### Test Root with Root Checker

1. Download **Root Checker** app from Play Store
2. Open the app
3. Tap **Verify Root**
4. Should show "Congratulations! Root access properly installed"

### Test Root via Terminal

1. Install a terminal app (e.g., Termux)
2. Open terminal
3. Type: `su`
4. Press Enter
5. Magisk should prompt for root permission
6. Grant permission
7. Prompt should change to `#` indicating root access

## Magisk Manager Features

### Main Screen

- **Status:** Shows installed Magisk version and SafetyNet status
- **Install:** Update or reinstall Magisk
- **Uninstall:** Remove Magisk completely

### Modules

Install Magisk modules to extend functionality:

1. Tap **Modules** in Magisk Manager
2. Tap **Install from storage** button
3. Select module ZIP file
4. Reboot after installation

**Popular Modules:**
- **Systemless Hosts:** Ad blocking
- **Busybox:** Additional Linux tools
- **YouTube Vanced:** Ad-free YouTube
- **ViPER4Android FX:** Audio enhancement
- **Greenify:** Battery optimization with root

### MagiskHide (App Hiding)

Hide root from apps that detect it (banking apps, Netflix, etc.):

1. In Magisk Manager, go to **Settings**
2. Enable **Zygisk** (if available)
3. Enable **Enforce DenyList**
4. Tap **Configure DenyList**
5. Select apps you want to hide root from
6. Reboot device

**Note:** In newer Magisk versions (24+), this feature is called **DenyList**.

### SafetyNet Check

Some apps check SafetyNet to detect unlocked bootloader/root:

1. In Magisk Manager, tap on **SafetyNet** section
2. Tap **CHECK**
3. Wait for results
4. You want both:
   - **basicIntegrity:** ✓ PASS
   - **ctsProfile:** ✓ PASS

If you fail SafetyNet:
- Enable MagiskHide/DenyList for system apps
- Install **Universal SafetyNet Fix** module
- Clear Google Play Services data
- Reboot and check again

## Root Management Apps

### Essential Root Apps

1. **Magisk Manager** - Root management (already installed)
2. **Root Checker** - Verify root status
3. **Titanium Backup** - Advanced backup/restore with root
4. **AdAway** - System-wide ad blocking
5. **SD Maid** - Advanced system cleaner
6. **Lucky Patcher** - App patching (use responsibly)
7. **Kernel Adiutor** - Kernel tweaking
8. **Greenify** - Battery optimization

### Recommended Magisk Modules

1. **Systemless Hosts** - For ad blocking
2. **Busybox for Android NDK** - Linux command-line tools
3. **YouTube Vanced** - Ad-free YouTube
4. **ViPER4Android** - Audio enhancement
5. **Active Edge Mod** - Gesture customization
6. **SQLite Optimizer** - Database optimization

## Troubleshooting

### Magisk not showing as installed
- Ensure you flashed the correct Magisk ZIP
- Check if boot partition was modified
- Try reinstalling via TWRP
- Restore boot backup and try again

### Boot loop after installing Magisk
- Boot into TWRP
- Restore boot partition backup
- Or flash original boot.img
- Check if Magisk version is compatible

### Root permission not working
- Open Magisk Manager and check status
- Reinstall Magisk Manager APK
- Re-flash Magisk ZIP in TWRP
- Clear Magisk Manager data and reboot

### SafetyNet failing
- Enable Zygisk in Magisk settings
- Enable DenyList and add system apps
- Install Universal SafetyNet Fix module
- Clear Play Services cache
- Rename Magisk Manager app

### Apps detecting root despite MagiskHide
- Ensure app is in DenyList
- Enable Zygisk
- Try renaming Magisk Manager
- Some apps may still detect unlocked bootloader
- Consider using Island or Shelter for app isolation

### Cannot update Magisk
- Download latest Magisk APK manually
- Install over existing installation
- Or flash new Magisk ZIP via TWRP
- Clear Magisk Manager data if needed

### OTA updates not installing
- Uninstall Magisk before applying OTA
- In Magisk Manager: Uninstall → Restore Images
- Apply OTA update
- Re-root with Magisk after update

## Updating Magisk

### Via Magisk Manager (Recommended)

1. Open Magisk Manager
2. When update is available, you'll see notification
3. Tap **Install** next to Magisk version
4. Choose installation method:
   - **Direct Install** (Recommended) - if you have TWRP
   - **Install to Inactive Slot** (for A/B devices)
5. Tap **LET'S GO**
6. Reboot when prompted

### Via TWRP

1. Download latest Magisk ZIP
2. Boot to TWRP
3. Flash new Magisk ZIP
4. Reboot
5. Update Magisk Manager APK if needed

## Uninstalling Magisk

### Complete Uninstall

**Via Magisk Manager:**
1. Open Magisk Manager
2. Tap **Uninstall** button
3. Select **Complete Uninstall**
4. Confirm and wait
5. Device will reboot without root

**Via TWRP:**
1. Boot into TWRP
2. Flash **Magisk-uninstaller.zip**
3. Or restore original boot backup
4. Reboot

## Best Practices for Root Users

1. **Be careful with system modifications** - can lead to boot loops
2. **Always create backups** before major changes
3. **Keep Magisk updated** for security and compatibility
4. **Use MagiskHide** for sensitive apps
5. **Don't grant root to unknown apps**
6. **Monitor root requests** in Magisk Manager logs
7. **Test thoroughly** after installing modules
8. **Keep TWRP backup** of working boot partition

## Security Considerations

- **Root access is powerful** - use responsibly
- **Malware can exploit root** - only install trusted apps
- **Review permissions** before granting root
- **Use secure lock screen** to protect root access
- **Consider unrooting** for sensitive transactions
- **Keep Magisk updated** for security patches

## Advanced Features

### Magisk Modules Development
- Create your own modules for custom modifications
- See Magisk documentation for module template

### Boot Scripts
- Add custom scripts to run at boot
- Place scripts in `/data/adb/service.d/`

### Systemless Modifications
- Modify system without touching system partition
- Safer and easier to revert

## FAQ

**Q: Will rooting erase my data?**  
A: Not if done correctly. However, always backup first.

**Q: Can I unroot anytime?**  
A: Yes, Magisk can be completely uninstalled.

**Q: Will banking apps work?**  
A: Use MagiskHide/DenyList to hide root from specific apps.

**Q: Is root safe?**  
A: If used responsibly, yes. Be careful what you grant root access to.

**Q: Can I still receive OTA updates?**  
A: You'll need to uninstall Magisk before applying OTA, then re-root.

**Q: Does root drain battery?**  
A: Root itself doesn't drain battery. Some root apps might if misconfigured.

## Support and Resources

- **Official Magisk:** https://github.com/topjohnwu/Magisk
- **Magisk Documentation:** https://topjohnwu.github.io/Magisk/
- **XDA Forums:** Magisk section
- **Telegram:** Official Magisk discussion group
- **GitHub Issues:** For bug reports

## Related Guides

- [Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md)
- [TWRP Installation Guide](TWRP_INSTALLATION.md)
- [Custom ROM Installation](ROM_INSTALLATION.md)
- [Development Guide](DEVELOPMENT.md)

---

**Last Updated:** 2026-01-10  
**Magisk Version Covered:** 26.0+  
**Author:** Xylop90 / Elektronikx-Center-Matte

**Disclaimer:** Rooting modifies your device. Proceed at your own risk. Always backup your data!
