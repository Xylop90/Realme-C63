# Contributing to Realme C63 Ultimate Installer

First off, thank you for considering contributing to the Realme C63 Ultimate Installer! 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
  - [PowerShell Style Guide](#powershell-style-guide)
  - [Git Commit Messages](#git-commit-messages)
- [Testing](#testing)

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (screenshots, logs, etc.)
- **Describe the behavior you observed and what you expected**
- **Include your environment details**:
  - Windows version
  - PowerShell version
  - Device model and firmware version

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **List some examples** of how it would work

### Pull Requests

1. Fork the repo and create your branch from `main`
2. Make your changes
3. Add or update tests as needed
4. Ensure the test suite passes
5. Run PSScriptAnalyzer to check code quality
6. Update documentation if needed
7. Submit a pull request

## Development Setup

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or higher
- Git
- Pester 5.x (for testing)
- PSScriptAnalyzer (for code quality)

### Setup Steps

```powershell
# Clone the repository
git clone https://github.com/Xylop90/Realme-C63.git
cd Realme-C63

# Install development dependencies
Install-Module -Name Pester -Force -SkipPublisherCheck
Install-Module -Name PSScriptAnalyzer -Force

# Run tests
.\tests\Test-Installation.ps1
```

## Style Guidelines

### PowerShell Style Guide

We follow the [PowerShell Practice and Style Guide](https://poshcode.gitbooks.io/powershell-practice-and-style/):

- **Use approved verbs** for function names (Get-, Set-, New-, etc.)
- **Use PascalCase** for function and parameter names
- **Use camelCase** for variables
- **Include comment-based help** for all functions
- **Use parameter validation** attributes
- **Handle errors properly** with try/catch blocks

Example:

```powershell
function Get-DeviceInfo {
    <#
    .SYNOPSIS
        Gets device information via ADB
    
    .DESCRIPTION
        Retrieves device model, serial number, and Android version
    
    .PARAMETER SerialNumber
        Specific device serial number (optional)
    
    .EXAMPLE
        Get-DeviceInfo
        Get-DeviceInfo -SerialNumber "ABC123"
    
    .OUTPUTS
        PSCustomObject with device information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber
    )
    
    try {
        # Implementation here
    }
    catch {
        Write-Error "Failed to get device info: $_"
        throw
    }
}
```

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests after the first line

Example:
```
Add firmware auto-discovery feature

- Implement web scraping for 5 firmware sources
- Add caching mechanism for firmware metadata
- Include SHA256 verification

Fixes #123
```

## Testing

All code should include tests. We use Pester for PowerShell testing.

### Running Tests

```powershell
# Run all tests
.\tests\Test-Installation.ps1

# Run specific module tests
Invoke-Pester .\tests\Module-Tests.ps1

# Run with coverage report
Invoke-Pester -CodeCoverage
```

### Writing Tests

```powershell
Describe "Download-Manager" {
    Context "When downloading files" {
        It "Should download file successfully" {
            $result = Get-RemoteFile -Url "https://example.com/file.zip"
            $result.Success | Should -Be $true
        }
        
        It "Should verify SHA256 hash" {
            $result = Get-RemoteFile -Url "https://example.com/file.zip" -ExpectedHash "abc123..."
            $result.HashValid | Should -Be $true
        }
    }
}
```

## Code Quality

Before submitting:

1. **Run PSScriptAnalyzer**:
   ```powershell
   Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning
   ```

2. **Run all tests**:
   ```powershell
   Invoke-Pester
   ```

3. **Test manually** with actual device if possible

## Documentation

- Update documentation for any user-facing changes
- Use clear, concise language
- Include code examples where appropriate
- Keep documentation in sync with code

## Questions?

Feel free to open an issue for questions or discussions!

---

**Copyright © 2026 Elektronikx-Center-Matte by Alexander Mathey**
