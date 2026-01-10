# Bin Directory

This directory contains binary executables and scripts for the Realme C63 system.

## Purpose

- Store ADB and Fastboot tools
- Custom utility scripts
- Device management tools
- Installation helpers

## Tools to Install

### Android Platform Tools
- `adb` - Android Debug Bridge
- `fastboot` - Fastboot tool for flashing

### Optional Tools
- Device-specific utilities
- Flash tools
- Backup utilities

## Installation

Tools are automatically downloaded and installed to this directory during setup.

Manual installation:
```bash
# Download platform tools
cd bin
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
mv platform-tools/* .
```

## Usage

Add to PATH:
```bash
export PATH="$(pwd)/bin:$PATH"
```

Or use directly:
```bash
./bin/adb devices
./bin/fastboot devices
```

## Notes

- This directory is added to PATH via `environment.conf`
- Binary files are excluded from git
- Make sure executables have proper permissions: `chmod +x bin/*`
