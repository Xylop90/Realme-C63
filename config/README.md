# Config Directory

This directory contains configuration files for the Realme C63 installation system.

## Files

### `realme-c63.conf`
Main configuration file containing:
- Installation settings
- Device information
- Feature toggles
- Logging configuration
- Security settings
- Performance options
- ROM configuration

### `platform.conf`
Platform-specific configuration including:
- Operating system details
- Device platform information
- Android platform details
- Partition layout
- Bootloader information
- Tool versions and URLs

### `environment.conf`
Environment variables configuration for:
- Installation paths
- Version information
- Device information
- System settings
- Logging configuration
- Feature flags
- Tool paths
- URLs and resources

## Usage

Load environment variables:
```bash
source config/environment.conf
```

View configuration:
```bash
cat config/realme-c63.conf
cat config/platform.conf
```

## Notes

- Configuration files use shell-compatible syntax
- Variables can be overridden via environment
- Files are automatically generated during installation
- Backup copies are created before modifications
