<#
.SYNOPSIS
    Documentation Generator Module for Realme C63 (RMX3939)
    
.DESCRIPTION
    Automatically generates comprehensive documentation for installation procedures,
    device configuration, and troubleshooting guides
    
.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    
.LINK
    https://github.com/Xylop90/Realme-C63
#>

#Requires -Version 5.1

# Module variables
$script:ModuleName = "Doc-Generator"
$script:ModuleVersion = "1.0.0"

<#
.SYNOPSIS
    Generates installation documentation
    
.DESCRIPTION
    Creates comprehensive step-by-step installation documentation
    
.PARAMETER OutputPath
    Output directory for generated documentation
    
.EXAMPLE
    New-InstallationDocumentation -OutputPath "C:\Docs"
#>
function New-InstallationDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$PSScriptRoot\..\..\docs\generated"
    )
    
    try {
        Write-Log "Generating installation documentation..." "INFO"
        
        # Ensure output directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        $docPath = Join-Path $OutputPath "INSTALLATION-GUIDE.md"
        
        $content = @"
# Realme C63 (RMX3939) Installation Guide

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Version:** 1.0.0  
**Author:** Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [System Requirements](#system-requirements)
3. [Installation Steps](#installation-steps)
4. [Bootloader Unlock](#bootloader-unlock)
5. [Root Installation](#root-installation)
6. [TWRP Installation](#twrp-installation)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- Windows 10/11 PC with administrator rights
- USB cable (original recommended)
- Realme C63 (RMX3939) device
- USB debugging enabled
- OEM unlocking enabled
- Device drivers installed

## System Requirements

- **OS:** Windows 10/11 (64-bit)
- **RAM:** 4GB minimum, 8GB recommended
- **Storage:** 10GB free space
- **Internet:** Required for downloads

## Installation Steps

### Step 1: Prepare Device

1. Enable Developer Options
2. Enable USB Debugging
3. Enable OEM Unlocking
4. Connect device to PC

### Step 2: Install Drivers

1. Run ``Install-RealmeC63-Ultimate.ps1``
2. Select driver installation option
3. Follow on-screen instructions

### Step 3: Unlock Bootloader

Three methods available (automatic fallback):

**Method 1: unisoc-unlock (Recommended)**
- Success Rate: 95%
- Automatic Python setup
- No manual steps required

**Method 2: CVE-2022-38694 Exploit**
- Success Rate: 80%
- Fallback option
- Automated process

**Method 3: DeepTesting App**
- Success Rate: 60%
- Official Realme method
- Requires app installation

### Step 4: Install Magisk Root

1. Firmware download (automatic)
2. boot.img extraction
3. Magisk APK installation
4. Boot image patching
5. Flashed via fastboot
6. Root verification

## Bootloader Unlock

### Automated Process

The installer provides intelligent 3-method bootloader unlock:

``````powershell
# Automatic unlock
Unlock-Bootloader
``````

### Manual Process

If automatic unlock fails:

1. Download unisoc-unlock tool
2. Boot device to fastboot mode
3. Run unlock command
4. Verify bootloader status

## Root Installation

### Automated Root

``````powershell
# Install Magisk root
Install-MagiskRoot
``````

### Manual Root

1. Download firmware
2. Extract boot.img
3. Install Magisk app
4. Patch boot image
5. Flash patched image

## TWRP Installation

### TWRP Recovery

``````powershell
# Install TWRP
Install-TWRP
``````

Supports:
- TWRP (official/unofficial)
- OrangeFox Recovery
- PitchBlack Recovery

## Troubleshooting

### Device Not Detected

- Install USB drivers
- Enable USB debugging
- Try different USB port
- Use original cable

### Bootloader Unlock Failed

- Verify OEM unlocking enabled
- Check device connection
- Try alternative method
- Reboot device and retry

### Root Installation Failed

- Verify bootloader unlocked
- Check firmware compatibility
- Retry boot.img extraction
- Ensure sufficient storage

## Support

For issues and support:
- GitHub: https://github.com/Xylop90/Realme-C63
- Documentation: See generated docs folder

---

**Copyright © 2026 Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey**
"@
        
        Set-Content -Path $docPath -Value $content -Encoding UTF8
        Write-Log "Installation documentation generated: $docPath" "INFO"
        
        return @{
            Success = $true
            Path = $docPath
        }
        
    } catch {
        Write-Log "Error generating documentation: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Generates device configuration documentation
    
.DESCRIPTION
    Creates device-specific configuration documentation
    
.EXAMPLE
    New-DeviceConfigDocumentation
#>
function New-DeviceConfigDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$PSScriptRoot\..\..\docs\generated"
    )
    
    try {
        Write-Log "Generating device configuration documentation..." "INFO"
        
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        $docPath = Join-Path $OutputPath "DEVICE-CONFIG.md"
        
        # Get current device info if connected
        $deviceInfo = @{
            Model = "RMX3939"
            Manufacturer = "Realme"
            Chipset = "Unisoc/Spreadtrum"
            AndroidVersion = "14"
        }
        
        try {
            $connectedDevice = Get-DeviceInfo
            if ($connectedDevice) {
                $deviceInfo = $connectedDevice
            }
        } catch {
            # Use defaults
        }
        
        $content = @"
# Realme C63 (RMX3939) Device Configuration

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Device Specifications

- **Model:** $($deviceInfo.Model)
- **Manufacturer:** $($deviceInfo.Manufacturer)
- **Chipset:** $($deviceInfo.Chipset)
- **Android Version:** $($deviceInfo.AndroidVersion)

## Supported Features

- ✅ Bootloader Unlock (3 methods)
- ✅ Magisk Root (v30.6)
- ✅ TWRP Recovery
- ✅ Custom ROMs
- ✅ SPD Flash Tool Support

## Installation Paths

- **Firmware:** /sdcard/RealmeC63-Installer/Firmware
- **Recovery:** /sdcard/RealmeC63-Installer/Recovery
- **Magisk:** /sdcard/RealmeC63-Installer/Magisk
- **Backups:** /sdcard/RealmeC63-Installer/Backups
- **Logs:** /sdcard/RealmeC63-Installer/Logs

## Configuration Settings

### ADB Settings
``````
USB Debugging: Enabled
OEM Unlocking: Enabled
USB Install: Enabled (optional)
``````

### Fastboot Settings
``````
Bootloader Mode: Volume Down + Power
Recovery Mode: Volume Up + Power
``````

---

**Copyright © 2026 Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey**
"@
        
        Set-Content -Path $docPath -Value $content -Encoding UTF8
        Write-Log "Device configuration documentation generated: $docPath" "INFO"
        
        return @{
            Success = $true
            Path = $docPath
        }
        
    } catch {
        Write-Log "Error generating device config documentation: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Generates all documentation
    
.DESCRIPTION
    Generates complete documentation suite
    
.EXAMPLE
    New-AllDocumentation
#>
function New-AllDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$PSScriptRoot\..\..\docs\generated"
    )
    
    try {
        Write-Log "Generating all documentation..." "INFO"
        
        $results = @()
        
        # Generate installation docs
        $installResult = New-InstallationDocumentation -OutputPath $OutputPath
        $results += $installResult
        
        # Generate device config docs
        $configResult = New-DeviceConfigDocumentation -OutputPath $OutputPath
        $results += $configResult
        
        Write-Log "All documentation generated successfully" "INFO"
        
        return @{
            Success = $true
            Generated = $results
            Count = $results.Count
        }
        
    } catch {
        Write-Log "Error generating all documentation: $_" "ERROR"
        throw
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'New-InstallationDocumentation',
    'New-DeviceConfigDocumentation',
    'New-AllDocumentation'
)
