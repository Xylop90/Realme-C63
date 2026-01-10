# Xtreme XA-vI ROM Installation Guide

## Table of Contents
- [Prerequisites](#prerequisites)
- [Step-by-Step Installation Instructions](#step-by-step-installation-instructions)
- [Troubleshooting](#troubleshooting)
- [FAQs](#faqs)

---

## Prerequisites

Before installing the Xtreme XA-vI ROM on your Realme C63, ensure you have the following:

### Hardware Requirements
- **Device**: Realme C63
- **Storage Space**: Minimum 3GB of free storage on your device
- **Battery**: At least 70% battery charge (fully charged recommended)
- **USB Cable**: Original or high-quality USB cable for data transfer
- **Computer**: Windows, macOS, or Linux with USB drivers installed

### Software Requirements
- **ADB & Fastboot**: Download from [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- **USB Drivers**: Realme C63 USB drivers (available on Realme official website)
- **ROM File**: Xtreme XA-vI ROM (latest version)
- **Recovery Tools**: TWRP or similar recovery environment (optional but recommended)

### Backup & Data
- **Full Device Backup**: Back up all important data (contacts, messages, photos, apps)
- **Cloud Storage**: Upload critical files to cloud services (Google Drive, OneDrive, etc.)
- **App Backup**: Consider using apps like Titanium Backup or Swift Backup for app backups

### Important Notes
- ⚠️ **Factory Reset Warning**: This process will erase all device data
- ⚠️ **Developer Mode**: Must be enabled on your device
- ⚠️ **USB Debugging**: Must be enabled for ADB commands
- ⚠️ **Warranty**: Installing custom ROMs may void your device warranty

---

## Step-by-Step Installation Instructions

### Phase 1: Preparation

#### Step 1.1: Enable Developer Options
1. Open **Settings** on your Realme C63
2. Navigate to **About Device** or **About Phone**
3. Tap **Build Number** 7 times rapidly
4. Return to Settings and verify **Developer Options** now appears
5. Open **Developer Options**
6. Enable **USB Debugging** and **OEM Unlocking**

#### Step 1.2: Unlock Bootloader
1. Power off your device completely
2. Boot into bootloader mode: Press **Power + Volume Down** buttons simultaneously
3. Connect your device to the computer via USB cable
4. Open Command Prompt/Terminal in the ADB platform-tools directory
5. Run the following commands:
   ```bash
   fastboot devices
   fastboot oem unlock
   ```
6. Confirm the unlock on your device using the volume buttons
7. Wait for the bootloader to unlock (this may take a few minutes)

#### Step 1.3: Install Custom Recovery (Recommended)
1. Download TWRP recovery for Realme C63
2. Boot device into bootloader mode again
3. Run the following command:
   ```bash
   fastboot flash recovery twrp.img
   fastboot boot twrp.img
   ```
4. TWRP recovery should now boot on your device

#### Step 1.4: Download ROM Files
1. Download the latest Xtreme XA-vI ROM from the official source
2. Verify the MD5 checksum:
   ```bash
   certutil -hashfile filename.zip MD5
   ```
   (Replace `filename.zip` with the actual ROM file name)
3. Store the ROM file in a safe location on your computer

### Phase 2: Installation via Recovery

#### Step 2.1: Transfer ROM to Device
1. Connect your device to the computer
2. Enable **MTP Mode** (Media Transfer Protocol) on your device
3. Copy the Xtreme XA-vI ROM file to the device's internal storage or SD card
4. Recommended location: `/sdcard/` or `/sdcard/Download/`

#### Step 2.2: Boot into Recovery
1. Power off your device completely
2. Press **Power + Volume Up** buttons simultaneously
3. Hold until the Realme logo appears
4. TWRP recovery should boot automatically

#### Step 2.3: Backup Current System (Optional but Recommended)
1. In TWRP, tap **Backup**
2. Select **System**, **System Image**, **Boot**, and **Data**
3. Tap **Back Up** and wait for completion
4. Return to the main menu

#### Step 2.4: Factory Reset / Wipe Data
1. From TWRP main menu, tap **Wipe**
2. Swipe to confirm factory reset
3. Select **Advanced Wipe**
4. Choose **System**, **Data**, **Dalvik Cache**, and **Cache**
5. Swipe to confirm the wipe process

#### Step 2.5: Flash the ROM
1. From TWRP main menu, tap **Install**
2. Navigate to the location where you stored the Xtreme XA-vI ROM file
3. Select the ROM file (e.g., `Xtreme-XA-vI-C63.zip`)
4. Swipe to confirm installation
5. Wait for the installation to complete (this may take 5-10 minutes)

#### Step 2.6: Flash GApps (Google Apps) - Optional
1. If the ROM doesn't include Google Apps, download the appropriate GApps package
2. In TWRP, tap **Install**
3. Select the GApps file
4. Swipe to confirm installation
5. Wait for completion

#### Step 2.7: Reboot System
1. From TWRP main menu, tap **Reboot**
2. Select **System**
3. Wait for the device to boot (first boot may take 5-15 minutes)

### Phase 3: Post-Installation Setup

#### Step 3.1: Initial Boot Configuration
1. Allow the device to complete its first boot sequence
2. Follow the on-screen setup wizard
3. Connect to Wi-Fi for initial configuration
4. Sign in to your Google account

#### Step 3.2: Verify Installation
1. Go to **Settings > About Phone**
2. Confirm the ROM version displays as "Xtreme XA-vI"
3. Check build number and other system information
4. Verify all system features are working

#### Step 3.3: Install Apps & Restore Data
1. Open Google Play Store
2. Restore apps from your backup or install fresh
3. Restore data using your preferred backup method
4. Test core functionality (calls, SMS, camera, etc.)

---

## Troubleshooting

### Installation Issues

#### Issue 1: "Device Not Detected" in ADB/Fastboot
**Solutions**:
- Check USB drivers are properly installed
- Try a different USB cable (preferably the original)
- Restart ADB server: `adb kill-server` then `adb start-server`
- Try a different USB port on your computer
- Disable USB Selective Suspend in Device Manager
- Verify USB Debugging is enabled in Developer Options

#### Issue 2: Bootloader Unlock Fails
**Solutions**:
- Ensure OEM Unlocking is enabled in Developer Options
- Try again after waiting 24 hours (some devices have unlock delays)
- Check internet connection is stable
- Use the official Realme Unlock tool if available
- Contact Realme support if persistent

#### Issue 3: TWRP Won't Boot
**Solutions**:
- Redownload TWRP from the official source
- Verify the device model matches the TWRP version
- Try the command: `fastboot boot twrp.img` (without flashing)
- Ensure fastboot drivers are properly installed

#### Issue 4: ROM Installation Fails with "Installation Aborted"
**Solutions**:
- Verify MD5 checksum matches the official ROM
- Ensure sufficient storage space (at least 3GB free)
- Try wiping System, Dalvik Cache, and Cache separately
- Download the ROM again from the official source
- Try installing from an SD card instead of internal storage

#### Issue 5: Device Stuck in Boot Loop
**Solutions**:
- Boot into TWRP recovery
- Select **Wipe > Advanced Wipe**
- Clear Dalvik Cache and Cache only
- Try rebooting
- If still looping, restore from your backup
- As last resort, flash the stock ROM

#### Issue 6: Google Play Store Not Available
**Solutions**:
- Ensure GApps were flashed correctly
- Re-flash the appropriate GApps package
- Clear Play Store cache: **Settings > Apps > Play Store > Storage > Clear Cache**
- Check Google account is properly signed in
- Verify internet connection is working

### Performance Issues

#### Issue 7: Device Running Slow
**Solutions**:
- Wait 24-48 hours for system optimization to complete
- Go to **Settings > Apps > Special Access > Optimize Battery Usage** and adjust settings
- Clear cache: **Settings > Storage > Other Apps > Clear Cache**
- Disable unnecessary animations: **Settings > Developer Options**
- Uninstall unnecessary pre-installed apps

#### Issue 8: Battery Draining Quickly
**Solutions**:
- Disable location services when not needed
- Turn off background app refresh
- Reduce screen brightness and disable Always-On Display temporarily
- Check for rogue apps: **Settings > Battery > Battery Usage**
- Disable Google Location Accuracy if not needed

#### Issue 9: Overheating Issues
**Solutions**:
- Allow device to cool for 30 minutes
- Avoid using in direct sunlight
- Disable heavy background processes
- Reduce screen brightness
- If persistent, restore backup and try stable ROM version

### Connectivity Issues

#### Issue 10: No Mobile Signal or Weak Signal
**Solutions**:
- Restart the device
- Toggle Airplane Mode on/off
- Verify SIM card is properly inserted
- Go to **Settings > SIM Settings** and check configuration
- Flash the correct ROM version for your region
- Contact your carrier to ensure compatibility

#### Issue 11: Wi-Fi Not Connecting
**Solutions**:
- Forget the Wi-Fi network and reconnect
- Reset Network Settings: **Settings > System > Reset Options > Reset Wi-Fi, Mobile & Bluetooth**
- Restart your router
- Update router firmware
- Move closer to the router to verify signal strength

#### Issue 12: Bluetooth Issues
**Solutions**:
- Restart Bluetooth
- Unpair and re-pair the device
- Clear Bluetooth cache: **Settings > Apps > Bluetooth > Storage > Clear Cache**
- Restart both devices
- Update Bluetooth device firmware if available

---

## FAQs

### General Questions

**Q1: Is it safe to install a custom ROM?**
A: Installing custom ROMs carries some risks including:
- Device warranty may be voided
- Potential data loss (always backup first)
- Stability issues depending on ROM quality
- However, established ROMs like Xtreme XA-vI are generally safe if instructions are followed carefully

**Q2: Will I lose my data?**
A: Yes, the installation process performs a factory reset. Always create complete backups before proceeding.

**Q3: Can I go back to the stock ROM?**
A: Yes, you can:
- Restore from your TWRP backup if you created one
- Flash the stock Realme C63 ROM using fastboot
- Use Realme's official recovery tools

**Q4: How long does installation take?**
A: Typically:
- Bootloader unlock: 5 minutes
- Data wipe: 2-3 minutes
- ROM installation: 5-10 minutes
- First boot: 5-15 minutes
- Total: 20-40 minutes

**Q5: Do I need a computer to install?**
A: Technically yes for initial setup, but some steps can be done on the device itself using apps like:
- Magisk Manager
- TWRP app managers
However, the safest method uses ADB/Fastboot via computer.

### Post-Installation Questions

**Q6: The ROM doesn't include Google Apps. How do I install them?**
A: Download the appropriate GApps package for your Android version and flash it via TWRP using the same process as the ROM installation.

**Q7: Can I take OTA updates with a custom ROM?**
A: Generally no. Custom ROM updates are provided separately. Always check the official source for updates, or use the built-in update checker in the ROM settings.

**Q8: Some apps don't work or say "Device not certified"**
A: This may be because the ROM modifies system signatures. Try:
- Installing from alternative app stores (APKPure, F-Droid)
- Using Magisk to hide the ROM modifications
- Contact the app developer for support

**Q9: What's Magisk and do I need it?**
A: Magisk is a tool that allows you to:
- Modify system without affecting the actual system partition
- Hide root from apps that require certification
- Completely optional but recommended for enhanced customization

**Q10: How do I update the ROM in the future?**
A: Typically:
1. Backup your current system via TWRP
2. Download the latest ROM version
3. Boot into TWRP recovery
4. Wipe Dalvik Cache and Cache only (NOT Data/System)
5. Flash the new ROM
6. Reboot and test

**Q11: The ROM is lagging or unstable. What should I do?**
A: Try these troubleshooting steps:
- Wait 48 hours for system optimization
- Disable heavy animations in Developer Options
- Factory reset and reinstall cleanly
- Try a different ROM version if available
- Restore your backup and use the stock ROM

**Q12: Is there a way to restore my apps and settings after installation?**
A: Yes, several methods:
- Use Google account sync for contacts and calendar
- Use app backup tools like Titanium Backup or Helium
- Restore from cloud services you used before
- Google Play automatically reinstalls your apps (if you have Play Protect enabled)

### Support & Resources

**Q13: Where can I get more help?**
A: Consult these resources:
- Official Xtreme XA-vI ROM documentation
- Realme C63 community forums
- XDA Developers forum for your device
- ROM developer's GitHub repository
- Official community Discord/Telegram channels

**Q14: Is there an official Discord or Telegram group?**
A: Check:
- The ROM's GitHub repository (usually has links in README)
- XDA Developers forum for your device
- Search for "Xtreme XA-vI ROM" in community platforms

**Q15: What if something goes wrong and my device won't boot?**
A: Don't panic! You have options:
1. Boot into recovery (TWRP) using Volume Up + Power
2. Restore your TWRP backup
3. Wipe Dalvik Cache and Cache, then reboot
4. If TWRP doesn't work, flash the stock ROM using Fastboot
5. Last resort: Contact Realme customer support

---

## Additional Resources

- [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- [TWRP Official Website](https://twrp.me/)
- [XDA Developers - Realme C63](https://xda-developers.com/)
- [Xtreme XA-vI ROM Repository](https://github.com/Xylop90/Realme-C63)
- [Realme Official Support](https://www.realme.com/support)

---

## Disclaimer

This guide is provided as-is for educational purposes. The author assumes no responsibility for:
- Device damage or data loss
- Bricked devices
- Warranty implications
- Any issues arising from following these instructions

**Always proceed at your own risk and ensure you have complete backups before installation.**

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-10 | Initial release with comprehensive installation guide |

---

**Last Updated**: 2026-01-10
**Maintained By**: Xylop90
**Feedback & Issues**: Please report issues via GitHub Issues or community forums
