# TWRP Recovery Installation Guide for Realme C63

## Overview
This guide provides step-by-step instructions for installing TWRP (Team Win Recovery Project) custom recovery on your Realme C63 device. TWRP is required for flashing custom ROMs, creating backups, and performing advanced system modifications.

## Prerequisites

Before you begin, ensure you have:

- **Unlocked bootloader** ([See Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md))
- **Realme C63** device with at least 60% battery charge
- **USB cable** (preferably original)
- **Computer** with ADB and Fastboot installed
- **TWRP recovery image** for Realme C63 (version 3.7.0 or higher)
- **USB drivers** for Realme C63 installed on your computer
- **Backup of important data** (recommended)

## Warning ⚠️

- Installing custom recovery may void your warranty
- Ensure your bootloader is unlocked before proceeding
- Download TWRP from official sources only
- Proceed at your own risk

## Download TWRP Recovery

1. Visit the official TWRP website: https://twrp.me/
2. Search for "Realme C63" or your device codename
3. Download the latest TWRP recovery image file (usually named `twrp-x.x.x-devicename.img`)
4. Save the file to a known location on your computer

## Installation Methods

### Method 1: Temporary Boot (Recommended for Testing)

This method boots TWRP temporarily without permanently installing it. Useful for testing compatibility.

1. **Enable USB Debugging** on your device (Settings → Developer Options → USB Debugging)

2. **Connect your device** to your computer via USB cable

3. **Open terminal/command prompt** on your computer and navigate to the folder containing the TWRP image

4. **Verify ADB connection:**
   ```bash
   adb devices
   ```
   Your device should appear in the list.

5. **Reboot to bootloader:**
   ```bash
   adb reboot bootloader
   ```

6. **Boot TWRP temporarily:**
   ```bash
   fastboot boot twrp-3.7.0-c63.img
   ```
   Replace `twrp-3.7.0-c63.img` with your actual TWRP image filename.

7. Your device will boot into TWRP recovery temporarily.

### Method 2: Permanent Installation

This method permanently installs TWRP to your device's recovery partition.

1. **Follow steps 1-5 from Method 1** to boot into bootloader mode

2. **Flash TWRP to recovery partition:**
   ```bash
   fastboot flash recovery twrp-3.7.0-c63.img
   ```
   Replace `twrp-3.7.0-c63.img` with your actual TWRP image filename.

3. **Wait for the process to complete.** You should see:
   ```
   Sending 'recovery' (xxxxx KB)                      OKAY [  x.xxxs]
   Writing 'recovery'                                 OKAY [  x.xxxs]
   Finished. Total time: x.xxxs
   ```

4. **Boot into TWRP recovery:**
   ```bash
   fastboot reboot recovery
   ```
   
   **Important:** Do NOT let the device boot into system. Boot directly into recovery by using the command above or by using hardware keys.

5. **Hardware key combination (if needed):**
   - Power off the device
   - Hold **Volume Up + Power** buttons simultaneously
   - Release when TWRP logo appears

## First Boot Configuration

When TWRP boots for the first time:

1. **Swipe to Allow Modifications** (if prompted)
   - This allows TWRP to make changes to your system
   - If you keep it read-only, you won't be able to flash ROMs

2. **Select Language** (if available)

3. **Set up password/PIN** (if your device is encrypted)
   - Enter your device's lock screen password/PIN
   - This is required to access encrypted data

## Verify TWRP Installation

1. **Check TWRP version:**
   - In TWRP, go to **Settings**
   - Scroll down to see the TWRP version
   - Should show version 3.7.0 or higher

2. **Test basic functions:**
   - Navigate through menus
   - Try mounting/unmounting partitions (Advanced → Mount)
   - Check if storage is accessible (Advanced → File Manager)

## TWRP Basic Features

### Main Menu Options

- **Install:** Flash ZIP files (ROMs, mods, kernels)
- **Wipe:** Wipe data, cache, system partitions
- **Backup:** Create full device backups
- **Restore:** Restore previous backups
- **Mount:** Mount/unmount system partitions
- **Settings:** Configure TWRP options
- **Advanced:** Access advanced features (terminal, file manager, etc.)
- **Reboot:** Reboot to system, recovery, bootloader, or power off

### Creating a Backup

Before flashing custom ROMs, create a backup:

1. **Tap Backup** in TWRP main menu
2. **Select partitions to backup:**
   - Boot ✓
   - System ✓
   - Data ✓
   - (Optional) Vendor, EFS, Modem
3. **Swipe to Backup**
4. **Wait for completion** (may take 10-20 minutes)
5. Backups are stored in `/sdcard/TWRP/BACKUPS/`

## Troubleshooting

### TWRP won't boot after installation
- Ensure your bootloader is unlocked
- Re-flash TWRP using fastboot
- Try a different TWRP version
- Check if you downloaded the correct TWRP for your device

### Can't access storage in TWRP
- Go to **Wipe → Format Data** (this will erase all data)
- Type "yes" to confirm
- This removes encryption and allows TWRP to access storage

### Device boots to system instead of TWRP
- Stock ROM may replace TWRP with stock recovery
- Boot into TWRP immediately after flashing
- Flash a custom ROM or disable stock recovery replacement

### Touch screen not working in TWRP
- Try a different TWRP version
- Use USB OTG mouse as alternative input
- Check TWRP forums for device-specific fixes

### TWRP shows "Failed to mount /data"
- Your data partition may be encrypted
- Enter your PIN/password in TWRP
- Or Format Data (Warning: This erases all data)

## Updating TWRP

To update to a newer TWRP version:

1. Download the new TWRP image
2. Boot into current TWRP recovery
3. Go to **Install → Install Image**
4. Select the new TWRP `.img` file
5. Choose **Recovery** as the target partition
6. Swipe to confirm
7. Reboot to recovery to use the new version

## Next Steps

Now that you have TWRP installed, you can:

- **Flash custom ROMs** ([See ROM Installation Guide](ROM_INSTALLATION.md))
- **Install Magisk** for root access ([See Rooting Guide](ROOTING_GUIDE.md))
- **Create regular backups** of your device
- **Flash custom kernels, mods, and themes**
- **Perform advanced system maintenance**

## Additional Resources

- **Official TWRP Website:** https://twrp.me/
- **TWRP FAQ:** https://twrp.me/FAQ/
- **XDA Developers Forum:** Realme C63 section
- **Realme Community Forums**
- **GitHub Issues:** For this project

## Support

For help with TWRP installation:
- Check the [Troubleshooting](#troubleshooting) section above
- Visit the official TWRP forums
- Search XDA Developers forum for your device
- Open an issue on this GitHub repository

---

**Last Updated:** 2026-01-10  
**Author:** Xylop90  
**TWRP Version Covered:** 3.7.0+
