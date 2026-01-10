# Bootloader Unlock Guide for Realme C63

## Overview
This guide provides step-by-step instructions for unlocking the bootloader on Realme C63 devices. Unlocking the bootloader allows for custom ROM installation, rooting, and other advanced modifications.

## Prerequisites
- A Realme C63 device
- USB cable (preferably original)
- Computer with ADB (Android Debug Bridge) installed
- USB drivers for Realme C63
- Backup of all important data (bootloader unlocking will wipe the device)
- Realme account credentials

## Warning ⚠️
- **This process will erase all data on your device**
- **Your warranty may be voided**
- **Proceed at your own risk**
- Make sure your device battery is at least 60% charged before starting

## Step-by-Step Instructions

### 1. Enable Developer Options
1. Go to **Settings** → **About Phone**
2. Tap on **Build Number** 7-10 times until you see "You are now a developer"
3. Go back to **Settings** → **Developer Options**

### 2. Enable USB Debugging
1. In **Developer Options**, enable **USB Debugging**
2. Connect your device to your computer via USB cable
3. A prompt will appear on your device asking for permission - tap **Allow**

### 3. Set Up ADB
1. Install ADB on your computer (if not already installed)
2. Open a terminal/command prompt
3. Verify ADB connection:
   ```bash
   adb devices
   ```
   Your device should appear in the list

### 4. Unlock the Bootloader
1. Enable **OEM Unlock** in Developer Options (if available)
2. Reboot your device to bootloader mode:
   ```bash
   adb reboot bootloader
   ```
3. Once in bootloader mode, execute:
   ```bash
   fastboot flashing unlock
   ```
4. Use the volume buttons to confirm the unlock on your device
5. Press the power button to confirm
6. Wait for the process to complete (may take a few minutes)

### 5. Verify Unlock Status
1. The device will reboot automatically
2. Boot back into bootloader:
   ```bash
   adb reboot bootloader
   ```
3. Check status:
   ```bash
   fastboot getvar unlocked
   ```
   Should show: `unlocked: yes`

### 6. Reboot to System
```bash
fastboot reboot
```

## Troubleshooting

### Device not recognized
- Install correct USB drivers for Realme C63
- Try a different USB port
- Use an original USB cable

### Bootloader already unlocked
- Your bootloader is already unlocked, no further action needed

### Permission denied errors
- Ensure USB Debugging is enabled
- Revoke USB Debugging permissions and re-authorize
- Restart ADB daemon: `adb kill-server && adb start-server`

### Device stuck in bootloader
- Connect to ADB and run: `fastboot reboot`
- If that doesn't work, force reboot using power button

## After Unlocking

Once your bootloader is unlocked, you can:
- Flash custom ROMs
- Install TWRP recovery
- Root your device
- Modify system files
- Install Magisk modules

## Related Resources
- [TWRP Installation Guide](TWRP_INSTALLATION.md)
- [Custom ROM Installation](ROM_INSTALLATION.md)
- [Rooting with Magisk](ROOTING_GUIDE.md)

## Support
For additional help and community support, visit:
- Realme Community Forums
- XDA Developers Forum - Realme C63 section
- GitHub Issues (if applicable)

---

**Last Updated:** 2026-01-10
**Author:** Xylop90

