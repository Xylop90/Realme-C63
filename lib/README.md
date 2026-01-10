# Lib Directory

This directory contains library files and shared resources for the Realme C63 system.

## Purpose

- Shared scripts and functions
- Common utilities
- Helper libraries
- Reusable modules

## Structure

Typical contents:
- Shell script libraries (`.sh`)
- Python modules (`.py`)
- Configuration templates
- Shared resources

## Usage

Source library files in scripts:
```bash
# In your script
source "${REALME_C63_LIB}/common.sh"
source "${REALME_C63_LIB}/logging.sh"
```

Or import in Python:
```python
import sys
sys.path.append(os.environ.get('REALME_C63_LIB', './lib'))
from utils import *
```

## Example Libraries

### `common.sh`
Common shell functions:
- Logging functions
- Error handling
- String manipulation
- File operations

### `device.sh`
Device-specific functions:
- ADB operations
- Fastboot commands
- Device detection
- Status checking

### `validation.sh`
Validation functions:
- File verification
- Checksum validation
- Configuration checks

## Notes

- Libraries should be sourced, not executed
- Keep libraries modular and reusable
- Document function parameters and return values
