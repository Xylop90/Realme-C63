# Copilot Instructions for Realme C63 / Xtreme XA-vI ROM Project

## Project Overview

This repository hosts **Xtreme XA-vI**, a performance-optimized custom ROM for the **Realme C63 (RMX3939)** device, along with comprehensive installation tools and documentation. The project is primarily a **documentation and automation repository** rather than ROM source code.

**Key Components:**
- Installation automation scripts (Bash, PowerShell)
- Device-specific guides (bootloader unlock, TWRP, rooting)
- ROM installation workflows
- Development documentation

**Copyright:** © Elektronikx-Center-Matte by Alexander Mathey

## Architecture & Structure

```
.
├── docs/                    # Comprehensive user and developer documentation
│   ├── BOOTLOADER_UNLOCK.md # Realme-specific unlock process (7-15 day wait)
│   ├── TWRP_INSTALLATION.md # Custom recovery setup
│   ├── ROOTING_GUIDE.md     # Magisk integration with SafetyNet
│   ├── INSTALLATION.md      # ROM flashing procedures
│   ├── DEVELOPMENT.md       # Contribution guidelines
│   └── CHANGELOG.md         # Version history
├── scripts/                 # Automated installation tools
│   ├── install-windows.ps1  # Windows installer with OptimizedMode
│   ├── download-all-tools.ps1  # Standalone download script
│   ├── install-termux.sh    # Android/Termux installer
│   └── README.md            # Script usage documentation
├── install.sh               # Universal Linux/macOS installer
├── run-complete-auto.sh     # Fully automated installation system
└── README.md                # Project entry point (German/English)
```

## Critical Workflows

### Installation Scripts Architecture

**Three-tier automation system:**

1. **Universal Installer** (`install.sh`):
   - Cross-platform (Linux, macOS, Windows/WSL)
   - Automatic OS detection and package manager selection (apt, yum, pacman, brew)
   - Dependency installation, file downloads, configuration generation
   - Usage: `./install.sh [--verbose] [--dry-run] [--non-interactive]`

2. **Complete Auto Installer** (`run-complete-auto.sh`):
   - AI-powered system analysis and optimization recommendations
   - Multi-stage installation: Init → Analysis → Validation → Optimization → Bootloader → ROM → Root
   - Error recovery system with rollback capabilities
   - Requires ADB/Fastboot tools and device connection
   - Interactive prompts at critical stages (bootloader unlock, ROM flash)

3. **Windows PowerShell** (`scripts/install-windows.ps1`):
   - **OptimizedMode**: Parallel downloads (3x faster), BITS transfer, caching
   - Options: `-AutoInstall`, `-OptimizedMode`, `-UseCache`, `-DownloadOnly`, `-ParallelDownloads [2-5]`
   - Downloads: Android Platform Tools, USB drivers, TWRP, Magisk, SP Flash Tool
   - Interactive menu (options 1-9) or fully automated mode
   - Example: `.\install-windows.ps1 -AutoInstall -OptimizedMode -UseCache`

### Device-Specific Constraints

**Realme C63 (RMX3939) Requirements:**
- Bootloader unlock has **7-15 day waiting period** for official approval
- TWRP Recovery v3.x+ required before ROM installation
- Android 12 / Realme UI 3.0+ base
- ADB debugging and USB drivers critical for all operations

## Code Conventions

### Documentation Standards

- **Language**: Mixed German/English (README in German, guides in English)
- **Style**: Markdown with emoji indicators (✅, 🔐, 🛠️, ⚠️)
- **Copyright notice**: Include "Copyright © Elektronikx-Center-Matte by Alexander Mathey" in new files
- **Last Updated**: Include timestamp footer (format: `2026-01-10`)

### Shell Script Patterns

**Bash scripts follow these conventions:**
- Strict mode: `set -euo pipefail`
- Readonly constants for configuration (uppercase with `readonly` or `declare -r`)
- Color-coded logging functions: `log_info`, `log_success`, `log_warning`, `log_error`
- Progress indicators: `print_progress current total label`
- Comprehensive error handling with `trap` for cleanup
- State files for checkpoint/resume functionality

**Example logging pattern:**
```bash
log_info "Starting operation..."
if operation_succeeds; then
    log_success "Operation completed"
else
    log_error "Operation failed"
    return 1
fi
```

**PowerShell conventions:**
- CmdletBinding with parameter validation
- Progress bars using `Write-Progress`
- Try-catch-finally error handling
- Admin privilege checks where required
- Parallel downloads using `Start-Job` in OptimizedMode

### Commit Message Format

Use conventional commit prefixes:
- `feat`: New features (e.g., `feat: Add OptimizedMode to Windows installer`)
- `fix`: Bug fixes
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `style`: Formatting changes

## Testing & Validation

**No automated test suite exists.** Manual testing approach:

1. **Script Testing:**
   - Test with `--dry-run` flag first
   - Verify downloads work (check internet connectivity)
   - Test on multiple OS/distros (Ubuntu, Fedora, macOS, Windows 10/11)
   - Validate file permissions (`chmod +x` for scripts)

2. **Documentation Testing:**
   - Verify all internal links work
   - Check markdown rendering on GitHub
   - Ensure commands are copy-pasteable
   - Test on real Realme C63 device when possible

3. **Installation Validation:**
   - Check ADB/Fastboot device detection (`adb devices`, `fastboot devices`)
   - Verify tool downloads are from official sources
   - Test rollback/error recovery scenarios

## Dependencies & External Tools

**Required System Tools:**
- `adb` and `fastboot` (Android Platform Tools)
- `curl` or `wget` for downloads
- `git` for repository operations
- `python3` (optional, for advanced operations)

**Downloaded Tools (via scripts):**
- Android Platform Tools (Google official)
- USB Drivers (Google, Universal ADB, Realme, OPPO)
- TWRP Recovery (device-specific: RMX3939)
- Magisk (latest stable + canary from official GitHub)
- SP Flash Tool (optional, for MediaTek devices)

**Package Managers Supported:**
- Linux: apt, yum, pacman, zypper
- macOS: Homebrew (required)
- Windows: Chocolatey, Scoop (optional)

## Integration Points

**ADB/Fastboot Communication:**
- Device detection timeouts: 30s (ADB), 300s (Bootloader)
- Battery threshold: 20% minimum for flashing operations
- Device verification: Check `ro.product.model` matches "C63" or "Realme"
- Fastboot mode detection: `fastboot devices | grep -E "fastboot|recovery"`

**File Generation:**
- Scripts auto-generate configuration files in `config/` directory
- Log files in `logs/` with timestamp: `install_YYYY-MM-DD_HH-MM-SS.log`
- Backup markers in `backups/` directory
- State files in `temp/` for resume capability

## Common Pitfalls

1. **Bootloader Unlock Timing**: Documentation must emphasize 7-15 day wait period
2. **Driver Installation**: Windows users often miss USB driver installation
3. **PowerShell Execution Policy**: Scripts may be blocked; require `Set-ExecutionPolicy Bypass`
4. **ADB Authorization**: Device must authorize computer for ADB debugging
5. **Recovery Mode**: TWRP must be installed before ROM sideload operations
6. **Parallel Operations**: Windows OptimizedMode uses 3-5 parallel downloads; ensure stable internet

## When Making Changes

**Documentation updates:**
- Match existing emoji style (🔐, 🛠️, ✅, ⚠️, 📱, 📖)
- Update "Last Updated" timestamps
- Test all command examples
- Verify cross-references between documents

**Script modifications:**
- Test with `--dry-run` or `-WhatIf` first
- Maintain logging consistency (color codes, format)
- Update version numbers in script headers
- Preserve error recovery mechanisms

**New features:**
- Add to CHANGELOG.md with version number
- Update relevant README files
- Include usage examples in documentation
- Consider cross-platform compatibility

## Key Files for Reference

- **Entry point**: `README.md` (German) - project overview and navigation
- **Complete workflow**: `run-complete-auto.sh` - reference implementation
- **Windows features**: `scripts/README.md` - detailed PowerShell options
- **Device specifics**: `docs/BOOTLOADER_UNLOCK.md` - Realme quirks and timing

## Support & Community

- **Repository**: https://github.com/Xylop90/Realme-C63
- **Issues**: GitHub Issues for bugs and feature requests
- **Community**: XDA Developers forum, Realme Community (c.realme.com)
- **Contact**: Developer is Alexander Mathey (Elektronikx-Center-Matte)

---

*This guide is for AI coding agents. For user documentation, see README.md and docs/ directory.*
