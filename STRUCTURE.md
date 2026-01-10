# Realme C63 Project Structure

This document provides a complete overview of the project structure and organization.

## Directory Tree

```
Realme-C63/
├── .cache/                     # Cache directory for downloads
├── .git/                       # Git repository data
├── .gitignore                  # Git ignore rules
├── README.md                   # Main project documentation
│
├── backups/                    # Backup files
│   └── README.md              # Backups guide
│
├── bin/                        # Binary executables and tools
│   ├── .gitkeep               # Preserve directory in git
│   └── README.md              # Binary tools guide
│
├── config/                     # Configuration files
│   ├── .gitkeep               # Preserve directory in git
│   ├── README.md              # Configuration guide
│   ├── device-specs.md        # Device specifications
│   ├── download-urls.md       # Download links and resources
│   ├── environment.conf       # Environment variables
│   ├── installation-checklist.md  # Installation checklist
│   ├── platform.conf          # Platform configuration
│   └── realme-c63.conf        # Main configuration
│
├── docs/                       # Documentation
│   ├── BOOTLOADER_UNLOCK.md   # Bootloader unlock guide
│   ├── CHANGELOG.md           # Version history
│   ├── DEVELOPMENT.md         # Development guide
│   ├── INSTALLATION.md        # ROM installation guide
│   ├── ROOTING_GUIDE.md       # Root installation guide
│   └── TWRP_INSTALLATION.md   # TWRP recovery guide
│
├── lib/                        # Shared libraries
│   ├── .gitkeep               # Preserve directory in git
│   ├── README.md              # Library guide
│   └── common.sh              # Common utility functions
│
├── logs/                       # Log files (auto-generated)
│   └── README.md              # Logs guide
│
├── scripts/                    # Installation scripts
│   ├── README.md              # Scripts documentation
│   ├── download-all-tools.ps1 # Windows download script
│   ├── install-termux.sh      # Termux installation
│   ├── install-windows.bat    # Windows batch installer
│   └── install-windows.ps1    # Windows PowerShell installer
│
├── temp/                       # Temporary files
│   └── README.md              # Temp directory guide
│
├── install.sh                  # Universal installer script
└── run-complete-auto.sh        # Fully automated installer
```

## File Descriptions

### Root Level Files

#### `README.md`
Main project documentation with:
- Project overview
- Feature list
- Quick navigation to guides
- Prerequisites
- Installation overview
- Support information

#### `.gitignore`
Git ignore configuration excluding:
- Logs and temporary files
- Backups
- Build artifacts
- Downloads
- Cache files
- IDE configuration
- Sensitive data

#### `install.sh`
Universal automated installer supporting:
- Multi-platform (Linux, macOS, Windows)
- Dependency installation
- Configuration generation
- File downloads
- System detection

#### `run-complete-auto.sh`
Fully automated installer with:
- AI-powered analysis
- Complete automation
- Error recovery
- Real-time monitoring
- Safety checks

### Configuration Directory (`config/`)

#### `realme-c63.conf`
Main configuration file containing:
- Installation settings
- Device information (Realme C63, RMX3939)
- Feature flags
- Logging configuration
- Security settings
- Performance options
- Timeout values

#### `platform.conf`
Platform-specific settings:
- Operating system details
- Device platform (MediaTek Helio G85)
- Android version (12)
- Partition layout
- Bootloader information
- Tool versions

#### `environment.conf`
Environment variables:
- Installation paths
- Version information
- Device details
- System settings
- Tool paths
- Color codes
- Aliases

#### `device-specs.md`
Complete device specifications:
- Display (6.74" IPS LCD, 90Hz)
- Performance (Helio G85)
- Memory (4GB/6GB/8GB RAM)
- Camera specifications
- Battery (5000 mAh)
- Connectivity
- Sensors
- Partition information

#### `download-urls.md`
Resource links for:
- Android Platform Tools
- USB Drivers
- TWRP Recovery
- Magisk
- Custom ROMs
- GApps
- Stock firmware
- Community resources

#### `installation-checklist.md`
Step-by-step checklist for:
- Pre-installation preparation
- Bootloader unlock
- TWRP installation
- ROM installation
- Root installation (Magisk)
- Post-installation setup
- Troubleshooting

### Library Directory (`lib/`)

#### `common.sh`
Shared utility functions:
- **Logging**: info, success, warning, error, debug
- **User Interaction**: prompts, yes/no questions
- **File Operations**: exists checks, backups, directory creation
- **System Checks**: root check, OS detection, architecture
- **String Functions**: trim, case conversion
- **Progress Indicators**: spinner, progress bar
- **Validation**: IP address, URL validation
- **Error Handling**: error exit, trap functions

### Scripts Directory (`scripts/`)

#### `download-all-tools.ps1`
Standalone PowerShell download script for:
- ADB & Fastboot Platform Tools
- USB drivers (Google, Universal, Realme, OPPO)
- TWRP Recovery
- Magisk
- SP Flash Tool

#### `install-windows.ps1`
Complete PowerShell installer with:
- Interactive menu system
- Automated installation
- Optimized mode (parallel downloads)
- Caching support
- Full device management

#### `install-termux.sh`
Termux (Android) installer for:
- On-device installation
- Storage permission handling
- Termux-specific optimizations

### Documentation Directory (`docs/`)

#### `BOOTLOADER_UNLOCK.md`
Comprehensive bootloader unlock guide:
- Realme-specific process
- Official unlock method
- 7-15 day waiting period
- Safety warnings
- Troubleshooting

#### `TWRP_INSTALLATION.md`
TWRP recovery installation:
- Download links
- Installation steps
- Backup procedures
- First boot configuration

#### `ROOTING_GUIDE.md`
Root installation with Magisk:
- Magisk installation
- SafetyNet configuration
- Banking apps compatibility
- Module management

#### `INSTALLATION.md`
ROM installation guide:
- Pre-installation checklist
- Flashing procedure
- Post-installation setup
- Optimization tips

## Data Flow

### Installation Process
```
1. User runs install.sh or run-complete-auto.sh
2. Scripts load config from config/
3. Scripts source lib/common.sh for utilities
4. Downloads stored in bin/ and .cache/
5. Logs written to logs/
6. Backups created in backups/
7. Temp files in temp/
```

### Configuration Loading
```
1. Source config/environment.conf
2. Load config/realme-c63.conf
3. Apply platform-specific settings from config/platform.conf
4. Override with user environment variables
```

### Logging
```
1. Log directory created: logs/
2. Log file: logs/install_YYYY-MM-DD_HH-MM-SS.log
3. Rotation: 30 days retention
4. Max size: 10MB per file
```

## Key Features

### Modular Design
- Separate directories for different purposes
- Reusable library functions
- Configuration separation
- Clear documentation

### Cross-Platform
- Linux support
- macOS support
- Windows support (PowerShell & Batch)
- Android (Termux) support

### Safety Features
- Backup before modifications
- Configuration validation
- Comprehensive logging
- Error recovery
- Lock files prevent concurrent runs

### User-Friendly
- Clear documentation
- Step-by-step guides
- Interactive prompts
- Progress indicators
- Helpful error messages

## Usage Examples

### Load Environment
```bash
source config/environment.conf
echo $REALME_C63_VERSION
```

### Use Common Library
```bash
source lib/common.sh
log_info "Starting process"
log_success "Process completed"
```

### Run Installation
```bash
# Unix/Linux/macOS
./install.sh

# Windows PowerShell
.\scripts\install-windows.ps1 -AutoInstall -OptimizedMode

# Termux (Android)
bash scripts/install-termux.sh
```

### View Configuration
```bash
cat config/realme-c63.conf
cat config/platform.conf
```

### Check Logs
```bash
tail -f logs/install_*.log
grep -i error logs/*.log
```

## Maintenance

### Adding New Features
1. Update configuration files in `config/`
2. Add functions to `lib/common.sh`
3. Update documentation in `docs/`
4. Update this STRUCTURE.md

### Cleaning Up
```bash
# Clean temporary files
rm -rf temp/*

# Clean old logs
find logs/ -mtime +30 -delete

# Clean cache
rm -rf .cache/*
```

## Development

### Contributing
See `docs/DEVELOPMENT.md` for:
- Development setup
- Coding standards
- Testing procedures
- Pull request process

### File Locations
- **Configuration**: `config/`
- **Libraries**: `lib/`
- **Documentation**: `docs/`
- **Scripts**: `scripts/` and root
- **Data**: Auto-generated in `logs/`, `backups/`, `temp/`

## Version Information

- **Project Version**: 1.0.0
- **Last Updated**: 2026-01-10
- **Maintained by**: Elektronikx-Center-Matte / Xylop90
- **Repository**: https://github.com/Xylop90/Realme-C63

## License

See main README.md for license information.

## Support

- **GitHub Issues**: https://github.com/Xylop90/Realme-C63/issues
- **Documentation**: `docs/` directory
- **XDA Forum**: Search for Realme C63 (RMX3939)
- **Realme Community**: https://c.realme.com/
