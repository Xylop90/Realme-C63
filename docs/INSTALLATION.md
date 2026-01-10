# Installation Instructions - Xtreme XA-vI ROM

## Prerequisites

Before installing Xtreme XA-vI ROM on your Realme C63 (RMX3939), ensure you have:

- **Unlocked bootloader** - [See Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md)
- **TWRP Recovery installed** - [See TWRP Installation Guide](TWRP_INSTALLATION.md)
- A fully charged device battery (at least 80%)
- A computer with USB drivers installed for Realme devices
- USB cable (preferably original)
- ADB (Android Debug Bridge) and Fastboot tools installed
- Xtreme XA-vI ROM file downloaded on your computer
- **Optional**: Root access with Magisk - [See Rooting Guide](ROOTING_GUIDE.md)

## Installation Methods

### Method 1: Using Fastboot (Recommended)

1. **Boot into Fastboot Mode**
   - Power off your Realme C63 completely
   - Connect to USB to your computer
   - Hold Volume Down + Power button until you see the Fastboot screen

2. **Flash the ROM**
   ```bash
   fastboot flash system xtreme-xa-vi-realme-c63.img
   fastboot reboot
   ```

3. **Wait for Installation**
   - The device will reboot and complete the installation
   - This may take 10-15 minutes

### Method 2: Using TWRP Recovery

1. **Boot into Recovery Mode**
   - Power off your device
   - Hold Volume Up + Power button until recovery boots

2. **Wipe Data (Optional but Recommended)**
   - Select "Wipe"
   - Choose "System", "Data", and "Cache"
   - Confirm the wipe

3. **Install ROM**
   - Select "Install"
   - Navigate to the Xtreme XA-vI ROM file
   - Swipe to confirm installation
   - Wait for completion

4. **Reboot**
   - Select "Reboot System"

## Post-Installation

After the ROM boots successfully:

- Allow the device to boot fully (may take longer on first boot, 5-10 minutes)
- Set up your device as normal
- Grant necessary permissions to applications
- Check for system updates in Settings

### Optional: Install Root (Magisk)

If you want root access after ROM installation:

1. Download latest Magisk APK from [official GitHub](https://github.com/topjohnwu/Magisk/releases)
2. Follow our comprehensive [Rooting Guide](ROOTING_GUIDE.md)
3. Flash Magisk via TWRP or patch boot image
4. Configure Magisk modules and SafetyNet

### Recommended Post-Install Steps

1. **Create a TWRP Backup**
   - Boot to TWRP
   - Tap Backup
   - Select Boot, System, Data
   - Swipe to backup

2. **Configure System Settings**
   - Enable Developer Options
   - Configure USB Debugging (if needed)
   - Set up security (screen lock, fingerprint)

3. **Install Essential Apps**
   - Restore from Google backup
   - Install preferred apps
   - Configure app permissions

## Troubleshooting

### Device stuck on boot loop
- Boot into recovery and perform a factory reset
- Reflash the ROM using Fastboot

### USB connection issues
- Install Realme USB drivers on your computer
- Try a different USB port
- Use a different USB cable

### Installation fails
- Ensure your device battery is sufficiently charged
- Verify the ROM file integrity (check file size)
- Clear temporary files and retry

## Support

For additional help or issues:
- Check the project repository for updates
- Review the ROM changelog for known issues
- Test on another computer if problems persist
- Visit [XDA Developers Forum](https://forum.xda-developers.com/) for community support

### Related Guides
- [Bootloader Unlock Guide](BOOTLOADER_UNLOCK.md)
- [TWRP Installation Guide](TWRP_INSTALLATION.md)
- [Rooting with Magisk](ROOTING_GUIDE.md)
- [Development Guide](DEVELOPMENT.md)

## Disclaimer

Flashing custom ROMs may void your device warranty. Proceed at your own risk. Always backup your data before flashing.

---
*Last Updated: 2026-01-10*
