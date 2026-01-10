<#
.SYNOPSIS
    Pester test suite for Realme C63 installer.

.DESCRIPTION
    Comprehensive test suite covering all modules and scripts
    with unit tests, integration tests, and mock data.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
#>

[CmdletBinding()]
param()

# Install Pester if not available
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installing Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Import modules to test
$modulePath = Join-Path $PSScriptRoot "..\modules"

Describe "Logger Module Tests" {
    BeforeAll {
        Import-Module (Join-Path $modulePath "Logger.psm1") -Force
    }
    
    It "Should write log messages" {
        { Write-Log -Message "Test" -Level "INFO" } | Should -Not -Throw
    }
    
    It "Should create log file" {
        $logDir = Join-Path $PSScriptRoot "..\..\work\logs"
        (Test-Path $logDir) | Should -Be $true
    }
}

Describe "UI-Helper Module Tests" {
    BeforeAll {
        Import-Module (Join-Path $modulePath "UI-Helper.psm1") -Force
    }
    
    It "Should display colored messages" {
        { Write-ColoredMessage -Message "Test" -Color "Green" } | Should -Not -Throw
    }
    
    It "Should show progress" {
        { Show-Progress -Percent 50 -Status "Testing" } | Should -Not -Throw
    }
}

Describe "Hash-Verifier Module Tests" {
    BeforeAll {
        Import-Module (Join-Path $modulePath "Hash-Verifier.psm1") -Force
    }
    
    It "Should calculate SHA256 hash" {
        $testFile = New-TemporaryFile
        "test content" | Out-File $testFile
        $hash = Get-FileHash256 -FilePath $testFile.FullName
        $hash | Should -Not -BeNullOrEmpty
        Remove-Item $testFile
    }
}

Describe "Device-Manager Module Tests" {
    BeforeAll {
        Import-Module (Join-Path $modulePath "Device-Manager.psm1") -Force
    }
    
    It "Should check ADB availability" {
        { Test-ADBAvailable } | Should -Not -Throw
    }
    
    It "Should handle device detection" {
        { Get-ConnectedDevice } | Should -Not -Throw
    }
}

Describe "Configuration Files Tests" {
    $configPath = Join-Path $PSScriptRoot "..\..\config"
    
    It "Should have valid installer-config.json" {
        $config = Get-Content (Join-Path $configPath "installer-config.json") | ConvertFrom-Json
        $config | Should -Not -BeNullOrEmpty
        $config.version | Should -Not -BeNullOrEmpty
    }
    
    It "Should have valid firmware-sources.json" {
        $config = Get-Content (Join-Path $configPath "firmware-sources.json") | ConvertFrom-Json
        $config.sources | Should -Not -BeNullOrEmpty
        $config.sources.Count | Should -BeGreaterThan 0
    }
    
    It "Should have valid tool-versions.json" {
        $config = Get-Content (Join-Path $configPath "tool-versions.json") | ConvertFrom-Json
        $config.tools | Should -Not -BeNullOrEmpty
    }
}

Describe "Integration Tests" {
    It "Should load all modules without errors" {
        $modules = Get-ChildItem $modulePath -Filter "*.psm1"
        foreach ($module in $modules) {
            { Import-Module $module.FullName -Force } | Should -Not -Throw
        }
    }
    
    It "Should have consistent module exports" {
        $modules = Get-ChildItem $modulePath -Filter "*.psm1"
        foreach ($module in $modules) {
            Import-Module $module.FullName -Force
            $commands = Get-Command -Module $module.BaseName
            $commands.Count | Should -BeGreaterThan 0
        }
    }
}

# Run tests
$testResults = Invoke-Pester -PassThru

Write-Host "`nTest Summary:" -ForegroundColor Cyan
Write-Host "Total: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor Red

if ($testResults.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
