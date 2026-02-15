<#
    .NOTES
    ===========================================================================
    Name:           Configure Auto-Run for Windows
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    This allows the enable and disable of windows auto-run. 
#>


param (
    [bool]$DisableAutoRun = $true
)

# Registry location
$RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$RegName = "NoDriveTypeAutoRun"

# Values
$DisabledValue = 255   # Disable AutoRun on all drives
$EnabledValue  = 91    # Windows default

# -----------------------------
# Helper: Get Current State
# -----------------------------
function Get-State {

    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }

    $current = Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue

    $value = if ($null -ne $current) { $current.$RegName } else { $null }

    $isDisabled = ($value -eq $DisabledValue)

    [pscustomobject]@{
        DisableAutoRunRequested = $DisableAutoRun
        CurrentValue            = $value
        AutoRunDisabled         = $isDisabled
        RegistryPath            = $RegPath
    }
}

# -----------------------------
# Helper: Apply Setting
# -----------------------------
function Set-AutoRunState {

    $desiredValue = if ($DisableAutoRun) { $DisabledValue } else { $EnabledValue }

    Write-Host "Setting AutoRun value to: $desiredValue"
    Write-Host "Registry Path: $RegPath"

    try {
        if (-not (Test-Path $RegPath)) {
            New-Item -Path $RegPath -Force | Out-Null
        }

        Set-ItemProperty -Path $RegPath -Name $RegName -Value $desiredValue -Type DWord -Force

        Write-Host "Registry updated successfully."
        return $true
    }
    catch {
        Write-Host "ERROR: Failed to update registry."
        Write-Host $_.Exception.Message
        return $false
    }
}

# -----------------------------
# ImmyBot Required Switch
# -----------------------------
switch ($Method) {

    # -------------------------
    # GET MODE
    # -------------------------
    "Get" {

        Write-Host "=== GET MODE ==="

        $state = Get-State

        Write-Host "Requested DisableAutoRun : $($state.DisableAutoRunRequested)"
        Write-Host "Current Registry Value   : $($state.CurrentValue)"
        Write-Host "AutoRun Disabled         : $($state.AutoRunDisabled)"

        $state
        break
    }

    # -------------------------
    # TEST MODE (Detect/Verify)
    # -------------------------
    "Test" {

        Write-Host "=== TEST MODE (Detect / Verify) ==="

        $state = Get-State

        if ($DisableAutoRun) {
            if ($state.CurrentValue -eq $DisabledValue) {
                Write-Host "Result: COMPLIANT - AutoRun is disabled."
                $true
            }
            else {
                Write-Host "Result: NOT COMPLIANT - AutoRun is enabled."
                $false
            }
        }
        else {
            if ($state.CurrentValue -eq $EnabledValue) {
                Write-Host "Result: COMPLIANT - AutoRun is enabled."
                $true
            }
            else {
                Write-Host "Result: NOT COMPLIANT - AutoRun is disabled."
                $false
            }
        }

        break
    }

    # -------------------------
    # SET MODE (Execute)
    # -------------------------
    "Set" {

        Write-Host "=== SET MODE (Execute) ==="

        $ok = Set-AutoRunState

        if ($ok) {
            Write-Host "SET Result: Success"
            $true
        }
        else {
            Write-Host "SET Result: Failed"
            $false
        }

        break
    }

    default {
        Write-Host "ERROR: Unknown `$Method value: $Method"
        $false
        break
    }
}


