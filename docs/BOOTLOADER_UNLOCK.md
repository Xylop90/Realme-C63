# Bootloader Unlock Guide for Realme C63 (RMX3939)

## Overview
This comprehensive guide provides step-by-step instructions for unlocking the bootloader on Realme C63 (RMX3939) devices. Unlocking the bootloader allows for custom ROM installation, rooting, and other advanced modifications.

## Device Information
- **Model**: Realme C63
- **Model Number**: RMX3939
- **Chipset**: MediaTek Helio G85 / Unisoc T612 (varies by region)
- **Android Version**: Android 12 / Realme UI 3.0+
- **Security**: AVB 2.0, dm-verity enabled

## Prerequisites
- A Realme C63 (RMX3939) device
- USB cable (preferably original Realme cable)
- Computer with Windows 10/11, macOS, or Linux
- ADB (Android Debug Bridge) and Fastboot tools installed
- USB drivers for Realme/OPPO devices
- Backup of all important data (bootloader unlocking will wipe the device)
- Active internet connection
- Device battery charged to at least 60%
- Patience (the Realme unlock process can take 7-15 days for approval)

## Important Warnings ⚠️

### Critical Information
- **This process will COMPLETELY ERASE all data on your device**
- **Your warranty WILL BE VOIDED**
- **Banking apps and DRM-protected content may stop working**
- **SafetyNet will fail until proper root configuration**
- **The unlock process requires waiting period (typically 7-15 days)**
- **You cannot relock bootloader without official firmware**
- **Proceed ONLY if you understand the risks**

### Before You Begin
- ✅ Backup all important data (photos, contacts, messages, apps)
- ✅ Remove Google account and screen lock
- ✅ Charge device to at least 60%
- ✅ Ensure stable internet connection
- ✅ Have original USB cable ready
- ✅ Install required drivers and tools

## Required Downloads

### 1. ADB and Fastboot Tools
- **Windows**: Download SDK Platform Tools from [Google](https://developer.android.com/studio/releases/platform-tools)
- **macOS**: Install via Homebrew: `brew install android-platform-tools`
- **Linux**: `sudo apt install android-tools-adb android-tools-fastboot` (Debian/Ubuntu)

### 2. Realme/OPPO USB Drivers
- Download from [Realme Support](https://www.realme.com/support)
- Or use universal Android drivers

### 3. Realme Unlock Tool (Optional but Helpful)
- Check XDA Forums for community-developed unlock tools
- Official Realme unlock tool (if available for your region)

## Step-by-Step Instructions

### Phase 1: Preparation

#### 1. Enable Developer Options
#### 1. Enable Developer Options
1. Go to **Settings** → **About Phone** → **Version**
2. Tap on **Build Number** 7-10 times continuously
3. You'll see "You are now a developer!" message
4. Enter your device PIN/password if prompted
5. Go back to **Settings** → **System Settings** (or **Additional Settings**)
6. Open **Developer Options** (now visible)

#### 2. Enable Required Developer Options
#### 2. Enable Required Developer Options
1. In **Developer Options**, enable the following:
   - ✅ **USB Debugging** - Required for ADB communication
   - ✅ **OEM Unlocking** - Critical for bootloader unlock
   - ✅ **Disable Automatic System Updates** - Prevents unwanted updates during process

2. Connect your device to computer via USB cable
3. On device screen, tap **Allow** when "Allow USB Debugging?" prompt appears
4. Check "Always allow from this computer" (recommended)
5. Tap **OK**

#### 3. Verify ADB Connection
#### 3. Verify ADB Connection
1. Open Command Prompt (Windows) or Terminal (macOS/Linux)
2. Navigate to platform-tools directory (or add to PATH)
3. Test ADB connection:
   ```bash
   adb devices
   ```
4. You should see output like:
   ```
   List of devices attached
   1234567890ABCDEF    device
   ```
5. If device shows as "unauthorized", check your device screen for authorization prompt

6. Test ADB communication:
   ```bash
   adb shell getprop ro.product.model
   ```
   Should return: `RMX3939` or `Realme C63`

### Phase 2: Bootloader Unlock Process

#### 4. Method A: Using Fastboot Command (Standard Method)

This is the standard method that works on most Realme devices with unlocked regions.

##### Step 4.1: Reboot to Fastboot Mode
##### Step 4.1: Reboot to Fastboot Mode

Option 1 - Using ADB:
```bash
adb reboot bootloader
```

Option 2 - Hardware Keys:
1. Power off device completely
2. Hold **Volume Down** + **Power** button simultaneously
3. Keep holding until you see Fastboot/Bootloader screen
4. Screen should show:
   - "FASTBOOT mode..."
   - Or Realme logo with Chinese/English text
   - Device info (model, variant, lock state)

##### Step 4.2: Verify Fastboot Connection

In Command Prompt/Terminal:
```bash
fastboot devices
```

Should show:
```
1234567890ABCDEF    fastboot
```

If device is not detected:
- Install proper USB drivers
- Try different USB port (prefer USB 2.0)
- Use original cable
- Restart ADB server: `adb kill-server && adb start-server`

##### Step 4.3: Check Current Lock State

```bash
fastboot getvar unlocked
```

Output will show:
- `unlocked: no` - Bootloader is locked (proceed with unlock)
- `unlocked: yes` - Already unlocked (no further action needed)

Also check:
```bash
fastboot getvar all
```

Look for:
- `(bootloader) device-state:` (locked/unlocked)
- `(bootloader) secure:` (yes = locked, no = unlocked)

##### Step 4.4: Attempt Unlock
##### Step 4.4: Attempt Unlock

Try the standard unlock command:
```bash
fastboot flashing unlock
```

**Possible Responses:**

**✅ Success Response:**
- Device screen shows unlock confirmation
- Use Volume keys to select "UNLOCK THE BOOTLOADER"
- Press Power button to confirm
- Device will wipe and unlock
- Skip to Step 6 (Verification)

**❌ Error: "Flashing Unlock is not allowed"**
This means OEM Unlocking is not enabled or your device is carrier-locked.

Solutions:
1. Reboot to system: `fastboot reboot`
2. Re-enable OEM Unlocking in Developer Options
3. Try again

**❌ Error: "Device not unlocked, cannot flash"**
Your device requires official unlock approval. Proceed to Method B.

**❌ Error: "Command not supported"**
Try alternative command:
```bash
fastboot oem unlock
```

#### 5. Method B: Using Realme/OPPO Official Unlock Tool

Many Realme devices (including RMX3939) require official approval from Realme.

##### Step 5.1: Apply for Bootloader Unlock

⚠️ **This process takes 7-15 days for approval**

1. **Using In-Depth Testing Application (Recommended):**

   a. On your device, go to:
      - **Settings** → **About Phone**
      - Tap **Version** multiple times (7-10 times)
      - Developer options will be enabled

   b. Go to:
      - **Settings** → **Additional Settings** → **Developer Options**
      - Find **Apply for In-depth Test** or **Bootloader Unlock Application**
      - Tap and follow on-screen instructions

   c. Fill out the application form:
      - Provide device IMEI
      - Accept terms and conditions
      - Submit application

   d. Wait for approval (usually 7-15 days)
      - You'll receive notification when approved
      - Check status in the same menu

2. **Using Deep Testing Application:**

   - Some regions use "Deep Testing" app
   - Download from Realme Community or official forums
   - Install and login with your Realme account
   - Apply for unlock permission
   - Wait for approval email

##### Step 5.2: After Receiving Approval

Once your application is approved:

1. You'll receive confirmation via:
   - In-app notification
   - Email to registered account
   - SMS to registered phone number

2. The "Apply for In-depth Test" option will change to:
   - **"Start In-depth Testing"**
   - Or **"Unlock Bootloader"**

3. Tap the option and follow instructions:
   - Device will reboot to fastboot
   - Unlock process will begin automatically
   - All data will be wiped
   - Device will reboot unlocked

##### Step 5.3: Manual Unlock After Approval

If automatic unlock doesn't work:

1. Reboot to fastboot:
   ```bash
   adb reboot bootloader
   ```

2. Try unlock command again:
   ```bash
   fastboot flashing unlock
   ```

3. Or use OEM command:
   ```bash
   fastboot oem unlock
   ```

4. On device screen:
   - Use **Volume Down** to navigate to "Unlock the bootloader"
   - Press **Power** to confirm
   - Wait for process to complete

#### 6. Complete Unlock Process

After running unlock command:

1. **On Device Screen:**
   - Confirmation screen appears
   - Warning about data wipe and warranty void
   - Use Volume buttons to highlight "UNLOCK THE BOOTLOADER" or "YES"
   - Press Power button to confirm

2. **Unlock Process:**
   - Device shows "Unlocking bootloader..."
   - All data is wiped
   - Process takes 1-5 minutes
   - Do NOT disconnect USB or power off

3. **Automatic Reboot:**
   - Device will reboot automatically
   - Or manually reboot: `fastboot reboot`

### Phase 3: Verification and Post-Unlock

#### 7. Verify Unlock Status
#### 7. Verify Unlock Status

##### 7.1: First Boot After Unlock

- First boot takes longer (5-10 minutes)
- Bootloader unlocked warning will appear on every boot:
  - "Orange State" warning
  - "Your device has been unlocked and can't be trusted"
  - This is NORMAL and cannot be removed
- Wait for device to boot completely

##### 7.2: Check Unlock Status via Fastboot

1. Complete initial device setup (or skip)
2. Re-enable USB Debugging:
   - Settings → About Phone → Tap Build Number 7 times
   - Settings → Developer Options → Enable USB Debugging

3. Reboot to fastboot:
   ```bash
   adb reboot bootloader
   ```

4. Check unlock status:
   ```bash
   fastboot getvar unlocked
   ```
   
   **Expected Output:**
   ```
   unlocked: yes
   Finished. Total time: 0.001s
   ```

5. Additional verification:
   ```bash
   fastboot getvar all | grep -i "device-state\|secure\|lock"
   ```
   
   Should show:
   - `device-state: unlocked`
   - `secure: no`

##### 7.3: Visual Confirmation

Every boot will show:
- **Orange State** warning (Realme/OPPO devices)
- **Unlocked bootloader** warning message
- 5-second delay before boot continues
- This confirms successful unlock

#### 8. Reboot to System
#### 8. Reboot to System
```bash
fastboot reboot
```

Or hold Power button for 10 seconds to force reboot.

## Troubleshooting

### Common Issues and Solutions

#### Device Not Recognized by ADB
#### Device Not Recognized by ADB

**Solutions:**
- Install proper Realme/OPPO USB drivers
  - Download from official website
  - Or use universal ADB drivers
- Try different USB port (USB 2.0 preferred)
- Use original USB cable or high-quality alternative
- Enable USB Debugging again
- Restart ADB server:
  ```bash
  adb kill-server
  adb start-server
  adb devices
  ```
- Change USB connection mode on device:
  - Settings → USB preferences → File Transfer (MTP)
- Try another computer if possible
- Update USB drivers in Device Manager (Windows)

#### "Flashing Unlock is Not Allowed"
#### "Flashing Unlock is Not Allowed"

**Causes:**
- OEM Unlocking is not enabled
- Device is carrier-locked
- Bootloader unlock not approved by Realme

**Solutions:**
1. Enable OEM Unlocking:
   - Settings → Developer Options
   - Enable "OEM Unlocking"
   - Reboot and try again

2. Remove Google account:
   - Settings → Accounts → Remove all accounts
   - Factory reset may be needed
   - Try unlock again

3. Wait for official approval:
   - Apply via "In-depth Testing" application
   - Wait 7-15 days for approval
   - Check application status regularly

4. Check if device is carrier-locked:
   - Contact your carrier
   - Pay off device if on payment plan
   - Request unlock code if available

#### "Waiting for Device" in Fastboot

**Solutions:**
- Install Fastboot USB drivers
- Try different USB port (USB 2.0)
- Manually install drivers:
  - Windows: Device Manager → Update Driver
  - Point to Android SDK driver folder
- Use "fastboot -w" to wait for device
- Reboot to fastboot again
- Check cable connection

#### Device Stuck in Fastboot Mode

**Solutions:**
- Wait 5-10 minutes (some operations take time)
- Force reboot: Hold Power button for 15-20 seconds
- Reboot via command:
  ```bash
  fastboot reboot
  ```
- If completely stuck:
  ```bash
  fastboot reboot recovery
  ```
  Then reboot from recovery

#### Bootloader Already Unlocked
#### Bootloader Already Unlocked
- `fastboot getvar unlocked` shows `yes`
- No further action needed
- Proceed to root or custom ROM installation

#### Permission Denied Errors

**Solutions:**
**Solutions:**
- Ensure USB Debugging is enabled
- Check authorization on device screen
- Revoke USB Debugging authorizations:
  - Developer Options → Revoke USB Debugging Authorizations
  - Reconnect device and authorize again
- Restart ADB daemon:
  ```bash
  adb kill-server
  adb start-server
  ```
- Run command prompt/terminal as Administrator (Windows)
- Use `sudo` on Linux/macOS:
  ```bash
  sudo fastboot flashing unlock
  ```

#### Boot Loop After Unlocking

**Solutions:**
- Let device attempt boot for 10-15 minutes
- If still boot looping:
  1. Boot to recovery (Volume Up + Power)
  2. Factory reset
  3. Reboot

- If recovery doesn't work:
  1. Download official firmware for RMX3939
  2. Flash via SP Flash Tool (MediaTek) or QFIL (Qualcomm)
  3. Follow device-specific flashing guides

#### Data Not Wiped After Unlock

**This is unusual but possible:**
- Manually factory reset:
  - Settings → System → Reset → Factory Reset
- Or via recovery:
  - Boot to recovery
  - Select "Wipe data/factory reset"

#### Device Won't Boot After Unlock

**Critical Solutions:**
1. Try booting to recovery:
   - Power off
   - Hold Volume Up + Power

2. Flash stock firmware:
   - Download firmware for RMX3939
   - Use appropriate flashing tool
   - Follow unbrick guide

3. If bricked:
   - Seek professional help
   - Check XDA forums for unbrick guides
   - May need EDL/9008 mode flashing

#### "Waiting for Approval" Status Stuck

**For In-depth Testing application:**
- Status has been "pending" for >15 days
- Contact Realme support via:
  - Official support channels
  - Realme Community forums
  - Email: support@realme.com
- Provide:
  - IMEI number
  - Model number (RMX3939)
  - Application reference number
  - Screenshot of pending status

#### Cannot Enter Fastboot Mode

**Alternative methods:**
1. Using hardware keys:
   - Power off completely
   - Volume Down + Power (hold both)
   - Try Volume Up + Power if above doesn't work
   
2. Using ADB:
   ```bash
   adb reboot bootloader
   ```

3. From powered-off state:
   - Volume Down + Power + Volume Up (all three)
   - Try different combinations

4. Check online guides:
   - Device-specific button combinations vary
   - XDA has device-specific guides

### Device Stuck in Bootloader
### Device Stuck in Bootloader
**Solutions:**
- Connect to computer and run:
  ```bash
  fastboot reboot
  ```
- If that doesn't work, force reboot:
  - Hold Power button for 15-20 seconds
- Try booting to recovery instead:
  ```bash
  fastboot reboot recovery
  ```
- Worst case - flash stock firmware via EDL mode

## Post-Unlock Information

### What Changes After Unlocking?

### What Changes After Unlocking?

#### ⚠️ Every Boot:
- **Orange State** warning appears for 5 seconds
- "Your device software can't be checked for corruption"
- "Your device will boot in 5 seconds"
- **This is normal and cannot be removed**

#### 🔓 New Capabilities:
- Flash custom recovery (TWRP, OrangeFox)
- Install custom ROMs
- Root your device with Magisk
- Modify system partitions
- Flash custom kernels
- Install GSI (Generic System Images)

#### ⚠️ Limitations/Issues:
- **Warranty void** (officially, though some regions vary)
- **SafetyNet fails** (banking apps, Netflix HD, etc.)
  - Can be fixed with Magisk + modules
- **Widevine L1 → L3 downgrade** (lower quality streaming)
  - Cannot be reversed
- **OTA updates may fail**
  - Need to flash manually
  - Or use custom ROM updater
- Some apps detect unlocked bootloader:
  - Banking apps
  - Payment apps (Google Pay)
  - Enterprise apps
  - Solution: Use Magisk Hide

### Next Steps After Unlocking

Now that your bootloader is unlocked, you can:
### Next Steps After Unlocking

Now that your bootloader is unlocked, you can:

#### 1. Install Custom Recovery (Recommended First Step)
- **TWRP** (Team Win Recovery Project)
- **OrangeFox Recovery**
- See: [TWRP Installation Guide](TWRP_INSTALLATION.md)

#### 2. Root Your Device
- Use **Magisk** for systemless root
- Full root guide: [Rooting Guide for RMX3939](ROOTING_GUIDE.md)
- Benefits:
  - Full system access
  - Install Magisk modules
  - Advanced customization
  - Backup/restore capabilities

#### 3. Flash Custom ROMs
- Install Xtreme XA-vI ROM (this project!)
- Or try other custom ROMs:
  - LineageOS
  - Pixel Experience
  - Evolution X
- See: [ROM Installation Guide](INSTALLATION.md)

#### 4. Install Mods and Tweaks
- Custom kernels for better performance/battery
- Xposed Framework modules
- Magisk modules:
  - Viper4Android (audio)
  - YouTube Vanced
  - AdAway
  - And many more

#### 5. System-Level Customization
- Modify system files
- Custom boot animations
- Advanced theming
- Remove bloatware permanently
- Overclock/underclock CPU

### Important Security Notes

#### ⚠️ Security Considerations:
- Unlocked bootloader = easier physical access attacks
- Anyone with physical device access can:
  - Flash malicious software
  - Access user data (without encryption)
  - Bypass lock screen

#### 🛡️ Improve Security:
- **Enable Full Disk Encryption** (usually automatic on Android 10+)
  - Settings → Security → Encrypt phone
- **Use strong screen lock**
  - PIN, password, or fingerprint
- **Enable "Find My Device"**
  - For remote wipe capability
- **Regular backups**
  - Use TWRP for full backups
  - Or Titanium Backup (requires root)
- **Keep device physically secure**
  - Never leave unattended
  - Use lock screen always

## Re-locking Bootloader (Not Recommended)

### ⚠️ Critical Warnings:
- **Will wipe all data again**
- **Can brick device if done incorrectly**
- **Must have stock ROM installed**
- **Must have stock recovery**
- **Boot image must be stock**
- **Only do this if absolutely necessary**

### Prerequisites for Re-locking:
1. Flash complete stock firmware for RMX3939
2. Ensure device boots properly to system
3. Remove root (uninstall Magisk)
4. Flash stock recovery
5. Verify all partitions are stock

### Re-lock Commands:

```bash
# Boot to fastboot
adb reboot bootloader

# Disable OEM Unlocking first (in system)
# Settings → Developer Options → OEM Unlocking = OFF

# Lock bootloader (HIGH RISK!)
fastboot flashing lock
# Or
fastboot oem lock

# Confirm on device screen
# Wait for completion
# Device will reboot
```

### If Device Bricks During Re-lock:
- Use EDL/9008 mode to flash firmware
- Requires specialized tools
- Seek professional help if unsure
- Check XDA forums for unbrick guides

## Related Guides & Resources

### Official Documentation
- [Realme Support](https://www.realme.com/support)
- [Realme Community](https://c.realme.com/)

### This Repository's Guides
- 📱 [TWRP Installation Guide](TWRP_INSTALLATION.md)
- 🔧 [Custom ROM Installation](INSTALLATION.md)
- 🔑 [Rooting with Magisk](ROOTING_GUIDE.md)
- 📋 [Development Guide](DEVELOPMENT.md)

### Community Resources
- **XDA Developers Forum**
  - Realme C63 section
  - Search for RMX3939 specific threads
  - URL: https://forum.xda-developers.com/
- **Realme Community Forums**
  - Official support and discussions
  - URL: https://c.realme.com/
- **Reddit Communities**
  - r/Realme
  - r/Android
  - r/AndroidRoot

### Useful Tools
- **ADB Platform Tools**: https://developer.android.com/studio/releases/platform-tools
- **Minimal ADB and Fastboot**: https://forum.xda-developers.com/
- **Realme Flash Tool**: Check Realme forums
- **SP Flash Tool** (for MediaTek): https://spflashtool.com/

### Video Tutorials
- Search YouTube for "Realme C63 bootloader unlock"
- Search for "RMX3939 unlock bootloader"
- Watch multiple guides to understand process
- Always verify information date (use recent videos)

## Frequently Asked Questions (FAQ)

### Q1: Will unlocking bootloader delete my data?
**A:** Yes, 100% of user data will be erased. Backup everything first.

### Q2: Can I re-lock the bootloader?
**A:** Yes, but it's risky and will wipe data again. Only do with stock firmware.

### Q3: Will I receive OTA updates?
**A:** Stock OTA updates may fail. You'll need to flash updates manually or use custom ROM updaters.

### Q4: Can I still use banking apps?
**A:** Initially no (SafetyNet fails), but can be fixed with Magisk + SafetyNet fix modules after rooting.

### Q5: Will my warranty be void?
**A:** Officially yes, but enforcement varies by region and circumstances.

### Q6: Can I undo the unlock?
**A:** Yes, but requires re-locking bootloader with stock firmware (risky).

### Q7: How long does the approval process take?
**A:** Typically 7-15 days for official Realme unlock approval.

### Q8: What is "Orange State"?
**A:** Boot warning indicating unlocked bootloader. Cannot be removed.

### Q9: Will Netflix and Amazon Prime work?
**A:** Yes, but only in lower quality (SD/HD) due to Widevine L3 downgrade. Cannot be reversed.

### Q10: Is it safe to unlock?
**A:** Generally yes, if you follow instructions carefully. Always backup and understand risks.

### Q11: Can I brick my device?
**A:** Risk is low during unlock itself. Higher risk when flashing ROMs/recoveries. Always have stock firmware available.

### Q12: Do I need root after unlocking?
**A:** No, unlocking and rooting are separate. Unlock enables rooting but doesn't root automatically.

## Support & Help

### Getting Help:
1. **Read this guide thoroughly**
2. **Check Troubleshooting section**
3. **Search XDA forums** for similar issues
4. **Visit Realme Community** forums
5. **Create GitHub issue** with:
   - Device model: Realme C63 (RMX3939)
   - Current status/step
   - Error messages
   - Screenshots
   - What you've tried

### Reporting Issues:
When asking for help, always include:
- ✅ Device model and variant (RMX3939)
- ✅ Current firmware version
- ✅ Computer OS (Windows/Mac/Linux)
- ✅ ADB/Fastboot version
- ✅ Exact error messages
- ✅ Screenshots of errors
- ✅ Steps you've already tried
- ✅ Output of `fastboot getvar all`

## Changelog

### Version 2.0 - 2026-01-10
- Added RMX3939-specific instructions
- Expanded Realme official unlock process
- Added detailed troubleshooting
- Included alternative unlock methods
- Enhanced security information
- Added FAQ section
- Updated resource links

### Version 1.0 - Initial Release
- Basic bootloader unlock guide
- Standard ADB/Fastboot instructions

---

## Legal Disclaimer

- This guide is provided "AS IS" without warranty
- The author is not responsible for:
  - Bricked devices
  - Lost data
  - Warranty void
  - Financial loss
  - Any other damages
- Unlocking bootloader may void warranty
- Proceed at your own risk
- Always backup your data
- Only proceed if you understand the risks
- Check local laws regarding device modification

---

**Last Updated**: 2026-01-10  
**Guide Version**: 2.0  
**Author**: Xylop90 / Elektronikx-Center-Matte  
**Repository**: https://github.com/Xylop90/Realme-C63

**For issues, suggestions, or contributions:**
- Create an issue on GitHub
- Submit a pull request
- Contact via Realme Community forums

**Support this project:**
- ⭐ Star the repository
- 🐛 Report bugs
- 📝 Suggest improvements
- 🤝 Share with others who may benefit

---

*Your journey to a fully customized Realme C63 starts here! 🚀*

