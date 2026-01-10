#Requires -Version 5.1

<#
.SYNOPSIS
    Error handler module with rollback capabilities

.DESCRIPTION
    Provides comprehensive error handling, checkpoint creation,
    and rollback functionality for safe operations.

.NOTES
    Author: Xtreme XA-I KI Elektronikx-Center-Matte Cyber ® By Alexander Mathey
    Version: 1.0.0
    Created: 2026-01-10
#>

$script:CheckpointStack = @()
$script:CheckpointDirectory = $null

<#
.SYNOPSIS
    Initializes the error handler

.PARAMETER CheckpointDirectory
    Directory to store checkpoints

.EXAMPLE
    Initialize-ErrorHandler -CheckpointDirectory "work/checkpoints"
#>
function Initialize-ErrorHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CheckpointDirectory
    )

    try {
        $script:CheckpointDirectory = $CheckpointDirectory

        if (-not (Test-Path $CheckpointDirectory)) {
            New-Item -ItemType Directory -Path $CheckpointDirectory -Force | Out-Null
        }

        Write-Verbose "Error handler initialized with checkpoint directory: $CheckpointDirectory"
    }
    catch {
        Write-Error "Failed to initialize error handler: $_"
        throw
    }
}

<#
.SYNOPSIS
    Creates a checkpoint for rollback

.PARAMETER Name
    Checkpoint name

.PARAMETER Data
    Data to save with checkpoint

.EXAMPLE
    New-Checkpoint -Name "before_unlock" -Data @{BootloaderState="locked"}
#>
function New-Checkpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [hashtable]$Data = @{}
    )

    try {
        if ($null -eq $script:CheckpointDirectory) {
            throw "Error handler not initialized"
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $checkpointId = "$Name`_$timestamp"
        
        $checkpoint = @{
            Id = $checkpointId
            Name = $Name
            Timestamp = (Get-Date -Format "o")
            Data = $Data
        }

        $checkpointFile = Join-Path $script:CheckpointDirectory "$checkpointId.json"
        $checkpoint | ConvertTo-Json -Depth 10 | Out-File -FilePath $checkpointFile -Encoding UTF8

        $script:CheckpointStack += $checkpoint

        Write-Verbose "Checkpoint created: $checkpointId"
        return $checkpointId
    }
    catch {
        Write-Error "Failed to create checkpoint: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Retrieves a checkpoint

.PARAMETER CheckpointId
    Checkpoint ID

.EXAMPLE
    $checkpoint = Get-Checkpoint -CheckpointId "before_unlock_20260110_120000"
#>
function Get-Checkpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CheckpointId
    )

    try {
        $checkpointFile = Join-Path $script:CheckpointDirectory "$CheckpointId.json"
        
        if (-not (Test-Path $checkpointFile)) {
            Write-Warning "Checkpoint not found: $CheckpointId"
            return $null
        }

        $checkpoint = Get-Content -Path $checkpointFile -Raw | ConvertFrom-Json
        return $checkpoint
    }
    catch {
        Write-Error "Failed to retrieve checkpoint: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Lists all available checkpoints

.EXAMPLE
    $checkpoints = Get-CheckpointList
#>
function Get-CheckpointList {
    [CmdletBinding()]
    param()

    try {
        if ($null -eq $script:CheckpointDirectory) {
            return @()
        }

        $checkpointFiles = Get-ChildItem -Path $script:CheckpointDirectory -Filter "*.json"
        
        $checkpoints = @()
        foreach ($file in $checkpointFiles) {
            try {
                $checkpoint = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                $checkpoints += $checkpoint
            }
            catch {
                Write-Warning "Failed to load checkpoint: $($file.Name)"
            }
        }

        return $checkpoints
    }
    catch {
        Write-Error "Failed to list checkpoints: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Removes a checkpoint

.PARAMETER CheckpointId
    Checkpoint ID

.EXAMPLE
    Remove-Checkpoint -CheckpointId "before_unlock_20260110_120000"
#>
function Remove-Checkpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CheckpointId
    )

    try {
        $checkpointFile = Join-Path $script:CheckpointDirectory "$CheckpointId.json"
        
        if (Test-Path $checkpointFile) {
            Remove-Item -Path $checkpointFile -Force
            Write-Verbose "Checkpoint removed: $CheckpointId"
            return $true
        }

        return $false
    }
    catch {
        Write-Error "Failed to remove checkpoint: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Invokes a rollback operation

.PARAMETER CheckpointId
    Checkpoint ID to rollback to

.PARAMETER RollbackAction
    Custom rollback script block

.EXAMPLE
    Invoke-Rollback -CheckpointId "before_unlock_20260110_120000" -RollbackAction { param($data) 
        # Custom rollback logic
    }
#>
function Invoke-Rollback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CheckpointId,

        [Parameter(Mandatory=$false)]
        [scriptblock]$RollbackAction
    )

    try {
        $checkpoint = Get-Checkpoint -CheckpointId $CheckpointId
        
        if ($null -eq $checkpoint) {
            throw "Checkpoint not found: $CheckpointId"
        }

        Write-Warning "Initiating rollback to checkpoint: $($checkpoint.Name)"

        if ($null -ne $RollbackAction) {
            & $RollbackAction $checkpoint.Data
        }

        Write-Verbose "Rollback completed"
        return $true
    }
    catch {
        Write-Error "Rollback failed: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Handles an error with automatic rollback

.PARAMETER ErrorRecord
    Error record

.PARAMETER CheckpointId
    Checkpoint to rollback to

.PARAMETER RollbackAction
    Custom rollback action

.EXAMPLE
    try {
        # risky operation
    }
    catch {
        Handle-Error -ErrorRecord $_ -CheckpointId $checkpoint -RollbackAction { 
            # rollback logic
        }
    }
#>
function Handle-Error {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory=$false)]
        [string]$CheckpointId,

        [Parameter(Mandatory=$false)]
        [scriptblock]$RollbackAction
    )

    try {
        Write-Error "Error occurred: $($ErrorRecord.Exception.Message)"
        Write-Error "At: $($ErrorRecord.InvocationInfo.PositionMessage)"

        if (-not [string]::IsNullOrWhiteSpace($CheckpointId)) {
            Write-Warning "Attempting automatic rollback..."
            $rollbackResult = Invoke-Rollback -CheckpointId $CheckpointId -RollbackAction $RollbackAction
            
            if ($rollbackResult) {
                Write-Host "Rollback successful" -ForegroundColor Green
            }
            else {
                Write-Error "Rollback failed"
            }
        }
    }
    catch {
        Write-Error "Error handler failed: $_"
    }
}

<#
.SYNOPSIS
    Executes an operation with automatic checkpoint and rollback

.PARAMETER Name
    Operation name

.PARAMETER Operation
    Script block to execute

.PARAMETER RollbackAction
    Rollback script block

.PARAMETER CheckpointData
    Data to save with checkpoint

.EXAMPLE
    Invoke-SafeOperation -Name "unlock_bootloader" -Operation {
        # Unlock operation
    } -RollbackAction {
        # Restore locked state
    }
#>
function Invoke-SafeOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory=$false)]
        [scriptblock]$RollbackAction,

        [Parameter(Mandatory=$false)]
        [hashtable]$CheckpointData = @{}
    )

    $checkpointId = $null

    try {
        # Create checkpoint
        $checkpointId = New-Checkpoint -Name $Name -Data $CheckpointData

        # Execute operation
        Write-Verbose "Executing operation: $Name"
        $result = & $Operation

        # Remove checkpoint on success
        if ($null -ne $checkpointId) {
            Remove-Checkpoint -CheckpointId $checkpointId
        }

        return $result
    }
    catch {
        Write-Error "Operation failed: $Name"
        
        if ($null -ne $checkpointId -and $null -ne $RollbackAction) {
            Handle-Error -ErrorRecord $_ -CheckpointId $checkpointId -RollbackAction $RollbackAction
        }

        throw
    }
}

<#
.SYNOPSIS
    Cleans old checkpoints

.PARAMETER DaysOld
    Remove checkpoints older than specified days

.EXAMPLE
    Clear-OldCheckpoints -DaysOld 7
#>
function Clear-OldCheckpoints {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$DaysOld = 7
    )

    try {
        if ($null -eq $script:CheckpointDirectory) {
            return
        }

        $cutoffDate = (Get-Date).AddDays(-$DaysOld)
        $checkpointFiles = Get-ChildItem -Path $script:CheckpointDirectory -Filter "*.json"

        $removed = 0
        foreach ($file in $checkpointFiles) {
            if ($file.LastWriteTime -lt $cutoffDate) {
                Remove-Item -Path $file.FullName -Force
                $removed++
            }
        }

        Write-Verbose "Removed $removed old checkpoint(s)"
    }
    catch {
        Write-Error "Failed to clean old checkpoints: $_"
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-ErrorHandler',
    'New-Checkpoint',
    'Get-Checkpoint',
    'Get-CheckpointList',
    'Remove-Checkpoint',
    'Invoke-Rollback',
    'Handle-Error',
    'Invoke-SafeOperation',
    'Clear-OldCheckpoints'
)
