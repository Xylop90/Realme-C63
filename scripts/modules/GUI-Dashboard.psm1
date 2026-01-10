<#
.SYNOPSIS
    GUI Dashboard Module for Realme C63 (RMX3939) Installer
    
.DESCRIPTION
    Provides graphical user interface dashboard with real-time status monitoring,
    installation progress tracking, and interactive controls
    
.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Requires: Windows Forms
    
.LINK
    https://github.com/Xylop90/Realme-C63
#>

#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Module variables
$script:ModuleName = "GUI-Dashboard"
$script:ModuleVersion = "1.0.0"
$script:MainForm = $null
$script:StatusLabel = $null
$script:ProgressBar = $null
$script:LogTextBox = $null

<#
.SYNOPSIS
    Creates and shows the main GUI dashboard
    
.DESCRIPTION
    Initializes and displays the main dashboard window with all controls
    
.EXAMPLE
    Show-Dashboard
#>
function Show-Dashboard {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Initializing GUI Dashboard..." "INFO"
        
        # Create main form
        $script:MainForm = New-Object System.Windows.Forms.Form
        $script:MainForm.Text = "Realme C63 (RMX3939) Ultimate Installer - Dashboard"
        $script:MainForm.Size = New-Object System.Drawing.Size(900, 700)
        $script:MainForm.StartPosition = "CenterScreen"
        $script:MainForm.FormBorderStyle = "FixedDialog"
        $script:MainForm.MaximizeBox = $false
        
        # Header label
        $headerLabel = New-Object System.Windows.Forms.Label
        $headerLabel.Text = "Xtreme XA-I KI Elektronikx-Center-Matte Cyber ®"
        $headerLabel.Location = New-Object System.Drawing.Point(10, 10)
        $headerLabel.Size = New-Object System.Drawing.Size(860, 30)
        $headerLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $headerLabel.TextAlign = "MiddleCenter"
        $script:MainForm.Controls.Add($headerLabel)
        
        # Device info group
        $deviceGroup = New-Object System.Windows.Forms.GroupBox
        $deviceGroup.Text = "Device Information"
        $deviceGroup.Location = New-Object System.Drawing.Point(10, 50)
        $deviceGroup.Size = New-Object System.Drawing.Size(420, 150)
        $script:MainForm.Controls.Add($deviceGroup)
        
        # Device status label
        $deviceLabel = New-Object System.Windows.Forms.Label
        $deviceLabel.Text = "Device: Not Connected"
        $deviceLabel.Location = New-Object System.Drawing.Point(10, 25)
        $deviceLabel.Size = New-Object System.Drawing.Size(390, 20)
        $deviceGroup.Controls.Add($deviceLabel)
        
        # Model label
        $modelLabel = New-Object System.Windows.Forms.Label
        $modelLabel.Text = "Model: Unknown"
        $modelLabel.Location = New-Object System.Drawing.Point(10, 50)
        $modelLabel.Size = New-Object System.Drawing.Size(390, 20)
        $deviceGroup.Controls.Add($modelLabel)
        
        # Bootloader label
        $bootloaderLabel = New-Object System.Windows.Forms.Label
        $bootloaderLabel.Text = "Bootloader: Unknown"
        $bootloaderLabel.Location = New-Object System.Drawing.Point(10, 75)
        $bootloaderLabel.Size = New-Object System.Drawing.Size(390, 20)
        $deviceGroup.Controls.Add($bootloaderLabel)
        
        # Root label
        $rootLabel = New-Object System.Windows.Forms.Label
        $rootLabel.Text = "Root: Unknown"
        $rootLabel.Location = New-Object System.Drawing.Point(10, 100)
        $rootLabel.Size = New-Object System.Drawing.Size(390, 20)
        $deviceGroup.Controls.Add($rootLabel)
        
        # Refresh device button
        $refreshButton = New-Object System.Windows.Forms.Button
        $refreshButton.Text = "Refresh Device Info"
        $refreshButton.Location = New-Object System.Drawing.Point(10, 120)
        $refreshButton.Size = New-Object System.Drawing.Size(150, 25)
        $refreshButton.Add_Click({
            Update-DeviceInfo $deviceLabel $modelLabel $bootloaderLabel $rootLabel
        })
        $deviceGroup.Controls.Add($refreshButton)
        
        # Status group
        $statusGroup = New-Object System.Windows.Forms.GroupBox
        $statusGroup.Text = "Installation Status"
        $statusGroup.Location = New-Object System.Drawing.Point(450, 50)
        $statusGroup.Size = New-Object System.Drawing.Size(420, 150)
        $script:MainForm.Controls.Add($statusGroup)
        
        # Status label
        $script:StatusLabel = New-Object System.Windows.Forms.Label
        $script:StatusLabel.Text = "Status: Ready"
        $script:StatusLabel.Location = New-Object System.Drawing.Point(10, 25)
        $script:StatusLabel.Size = New-Object System.Drawing.Size(390, 20)
        $statusGroup.Controls.Add($script:StatusLabel)
        
        # Progress bar
        $script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
        $script:ProgressBar.Location = New-Object System.Drawing.Point(10, 50)
        $script:ProgressBar.Size = New-Object System.Drawing.Size(390, 25)
        $script:ProgressBar.Minimum = 0
        $script:ProgressBar.Maximum = 100
        $statusGroup.Controls.Add($script:ProgressBar)
        
        # Actions group
        $actionsGroup = New-Object System.Windows.Forms.GroupBox
        $actionsGroup.Text = "Installation Actions"
        $actionsGroup.Location = New-Object System.Drawing.Point(10, 210)
        $actionsGroup.Size = New-Object System.Drawing.Size(860, 120)
        $script:MainForm.Controls.Add($actionsGroup)
        
        # Button layout
        $buttonY = 25
        $buttonSpacing = 140
        
        # Full Install button
        $fullInstallButton = New-Object System.Windows.Forms.Button
        $fullInstallButton.Text = "Full Installation"
        $fullInstallButton.Location = New-Object System.Drawing.Point(10, $buttonY)
        $fullInstallButton.Size = New-Object System.Drawing.Size(120, 80)
        $fullInstallButton.Add_Click({
            Update-DashboardStatus "Starting full installation..."
            # Call installation function
        })
        $actionsGroup.Controls.Add($fullInstallButton)
        
        # Unlock button
        $unlockButton = New-Object System.Windows.Forms.Button
        $unlockButton.Text = "Unlock Bootloader"
        $unlockButton.Location = New-Object System.Drawing.Point(($buttonSpacing), $buttonY)
        $unlockButton.Size = New-Object System.Drawing.Size(120, 80)
        $unlockButton.Add_Click({
            Update-DashboardStatus "Unlocking bootloader..."
        })
        $actionsGroup.Controls.Add($unlockButton)
        
        # Root button
        $rootButton = New-Object System.Windows.Forms.Button
        $rootButton.Text = "Install Root"
        $rootButton.Location = New-Object System.Drawing.Point(($buttonSpacing * 2), $buttonY)
        $rootButton.Size = New-Object System.Drawing.Size(120, 80)
        $rootButton.Add_Click({
            Update-DashboardStatus "Installing Magisk root..."
        })
        $actionsGroup.Controls.Add($rootButton)
        
        # TWRP button
        $twrpButton = New-Object System.Windows.Forms.Button
        $twrpButton.Text = "Install TWRP"
        $twrpButton.Location = New-Object System.Drawing.Point(($buttonSpacing * 3), $buttonY)
        $twrpButton.Size = New-Object System.Drawing.Size(120, 80)
        $twrpButton.Add_Click({
            Update-DashboardStatus "Installing TWRP recovery..."
        })
        $actionsGroup.Controls.Add($twrpButton)
        
        # Drivers button
        $driversButton = New-Object System.Windows.Forms.Button
        $driversButton.Text = "Install Drivers"
        $driversButton.Location = New-Object System.Drawing.Point(($buttonSpacing * 4), $buttonY)
        $driversButton.Size = New-Object System.Drawing.Size(120, 80)
        $driversButton.Add_Click({
            Update-DashboardStatus "Installing drivers..."
        })
        $actionsGroup.Controls.Add($driversButton)
        
        # Firmware button
        $firmwareButton = New-Object System.Windows.Forms.Button
        $firmwareButton.Text = "Download Firmware"
        $firmwareButton.Location = New-Object System.Drawing.Point(($buttonSpacing * 5), $buttonY)
        $firmwareButton.Size = New-Object System.Drawing.Size(120, 80)
        $firmwareButton.Add_Click({
            Update-DashboardStatus "Downloading firmware..."
        })
        $actionsGroup.Controls.Add($firmwareButton)
        
        # Log group
        $logGroup = New-Object System.Windows.Forms.GroupBox
        $logGroup.Text = "Activity Log"
        $logGroup.Location = New-Object System.Drawing.Point(10, 340)
        $logGroup.Size = New-Object System.Drawing.Size(860, 280)
        $script:MainForm.Controls.Add($logGroup)
        
        # Log text box
        $script:LogTextBox = New-Object System.Windows.Forms.TextBox
        $script:LogTextBox.Location = New-Object System.Drawing.Point(10, 20)
        $script:LogTextBox.Size = New-Object System.Drawing.Size(830, 250)
        $script:LogTextBox.Multiline = $true
        $script:LogTextBox.ScrollBars = "Vertical"
        $script:LogTextBox.ReadOnly = $true
        $script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $logGroup.Controls.Add($script:LogTextBox)
        
        # Bottom buttons
        $closeButton = New-Object System.Windows.Forms.Button
        $closeButton.Text = "Close"
        $closeButton.Location = New-Object System.Drawing.Point(780, 630)
        $closeButton.Size = New-Object System.Drawing.Size(90, 30)
        $closeButton.Add_Click({
            $script:MainForm.Close()
        })
        $script:MainForm.Controls.Add($closeButton)
        
        # Add initial log entry
        Add-DashboardLog "Dashboard initialized - Ready for operations"
        
        # Show form
        Write-Log "GUI Dashboard created successfully" "INFO"
        $script:MainForm.ShowDialog() | Out-Null
        
    } catch {
        Write-Log "Error creating dashboard: $_" "ERROR"
        throw
    }
}

<#
.SYNOPSIS
    Updates device information in the dashboard
    
.DESCRIPTION
    Refreshes device status, model, bootloader, and root information
#>
function Update-DeviceInfo {
    param(
        $DeviceLabel,
        $ModelLabel,
        $BootloaderLabel,
        $RootLabel
    )
    
    try {
        Add-DashboardLog "Refreshing device information..."
        
        $device = Get-ConnectedDevice
        if ($device) {
            $DeviceLabel.Text = "Device: Connected ($($device.Serial))"
            $DeviceLabel.ForeColor = "Green"
            
            $deviceInfo = Get-DeviceInfo
            $ModelLabel.Text = "Model: $($deviceInfo.Model)"
            
            $bootloaderStatus = Test-BootloaderUnlocked
            $BootloaderLabel.Text = "Bootloader: " + $(if ($bootloaderStatus) { "Unlocked" } else { "Locked" })
            $BootloaderLabel.ForeColor = $(if ($bootloaderStatus) { "Green" } else { "Red" })
            
            $rootStatus = Test-MagiskInstalled
            $RootLabel.Text = "Root: " + $(if ($rootStatus) { "Installed" } else { "Not Installed" })
            $RootLabel.ForeColor = $(if ($rootStatus) { "Green" } else { "Red" })
            
            Add-DashboardLog "Device information updated successfully"
        } else {
            $DeviceLabel.Text = "Device: Not Connected"
            $DeviceLabel.ForeColor = "Red"
            $ModelLabel.Text = "Model: Unknown"
            $BootloaderLabel.Text = "Bootloader: Unknown"
            $RootLabel.Text = "Root: Unknown"
            
            Add-DashboardLog "No device connected"
        }
    } catch {
        Add-DashboardLog "Error updating device info: $_"
    }
}

<#
.SYNOPSIS
    Updates dashboard status message
    
.DESCRIPTION
    Updates the status label with current operation status
#>
function Update-DashboardStatus {
    param(
        [string]$Message
    )
    
    if ($script:StatusLabel) {
        $script:StatusLabel.Text = "Status: $Message"
        Add-DashboardLog $Message
    }
}

<#
.SYNOPSIS
    Updates dashboard progress bar
    
.DESCRIPTION
    Sets the progress bar value
#>
function Update-DashboardProgress {
    param(
        [int]$Percent
    )
    
    if ($script:ProgressBar) {
        $script:ProgressBar.Value = [Math]::Min(100, [Math]::Max(0, $Percent))
    }
}

<#
.SYNOPSIS
    Adds log entry to dashboard
    
.DESCRIPTION
    Appends a log message to the dashboard log text box
#>
function Add-DashboardLog {
    param(
        [string]$Message
    )
    
    if ($script:LogTextBox) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] $Message"
        $script:LogTextBox.AppendText("$logEntry`r`n")
        $script:LogTextBox.SelectionStart = $script:LogTextBox.TextLength
        $script:LogTextBox.ScrollToCaret()
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Show-Dashboard',
    'Update-DashboardStatus',
    'Update-DashboardProgress',
    'Add-DashboardLog'
)
