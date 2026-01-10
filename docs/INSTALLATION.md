# Installation Instructions - Xtreme XA-vI ROM

## Prerequisites

Before installing Xtreme XA-vI ROM on your Realme C63, ensure you have:

- A fully charged device battery (at least 80%)
- A computer with USB drivers installed for Realme devices
- USB cable (preferably original)
- ADB (Android Debug Bridge) and Fastboot tools installed
- Xtreme XA-vI ROM file downloaded on your computer
- TWRP recovery (if flashing via recovery)

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

- Allow the device to boot fully (may take longer on first boot)
- Set up your device as normal
- Grant necessary permissions to applications
- Check for system updates in Settings

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

## Disclaimer

Flashing custom ROMs may void your device warranty. Proceed at your own risk. Always backup your data before flashing.

---
*Last Updated: 2026-01-10*
