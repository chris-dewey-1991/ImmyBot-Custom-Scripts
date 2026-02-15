<#
    .NOTES
    ===========================================================================
    Name:           Check for Driver Issues for Windows
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    This will check the system for any Driver related issues and will report back
    to immybot and indicate a non compliant if there is a driver issue. If there
    is no issues it will be marked as compliant
#>


param (
    [string]$LogPath = "C:\Source\Logs"
)

# -----------------------------
# Script Configuration
# -----------------------------
$Date = (Get-Date).ToString("yyyyMMdd")
$LogFileName = "${Date}_Driver-Error-Detection-Logs-$env:COMPUTERNAME.txt"
$LogFilePath = Join-Path -Path $LogPath -ChildPath $LogFileName

# -----------------------------
# Helper: Ensure Log Directory
# -----------------------------
function Ensure-LogFolder {
    if (-not (Test-Path -Path $LogPath)) {
        Write-Host "Creating log directory: $LogPath"
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
}

# -----------------------------
# Helper: Get Problem Devices
# -----------------------------
function Get-ProblemDevices {

    # ConfigManagerErrorCode > 0 indicates device/driver issue
    $devices = Get-CimInstance -ClassName Win32_PnpEntity -Namespace root\cimv2 |
        Where-Object { $_.ConfigManagerErrorCode -gt 0 }

    return $devices
}

# -----------------------------
# Helper: Write Log Output
# -----------------------------
function Write-DriverLog {

    Ensure-LogFolder

    $devices = Get-ProblemDevices

    "===================================================" | Out-File $LogFilePath -Append
    "Driver Error Detection Report"                      | Out-File $LogFilePath -Append
    "Computer : $env:COMPUTERNAME"                       | Out-File $LogFilePath -Append
    "Date     : $(Get-Date)"                             | Out-File $LogFilePath -Append
    "===================================================" | Out-File $LogFilePath -Append
    ""                                                   | Out-File $LogFilePath -Append

    if ($devices) {

        "ERRORS FOUND IN DEVICE MANAGER" | Out-File $LogFilePath -Append
        "-------------------------------------------" | Out-File $LogFilePath -Append

        $devices |
            Select-Object Name, ConfigManagerErrorCode |
            Format-Table -AutoSize |
            Out-String |
            Out-File $LogFilePath -Append

        "" | Out-File $LogFilePath -Append
        "ACTION: Please review driver issues manually." | Out-File $LogFilePath -Append

        Write-Host "NOT COMPLIANT - Driver/device errors found."
        Write-Host "Log written to: $LogFilePath"

        return $false
    }
    else {

        "No driver/device errors detected." | Out-File $LogFilePath -Append
        Write-Host "COMPLIANT - No Device Manager errors found."
        Write-Host "Log written to: $LogFilePath"

        return $true
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

        $devices = Get-ProblemDevices

        Write-Host "Log Path: $LogFilePath"
        Write-Host "Problem Devices Found: $($devices.Count)"

        # Return device list for visibility
        $devices | Select-Object Name, ConfigManagerErrorCode
        break
    }

    # -------------------------
    # TEST MODE (Detect/Verify)
    # -------------------------
    "Test" {

        Write-Host "=== TEST MODE (Detect / Verify) ==="

        $devices = Get-ProblemDevices

        if ($devices.Count -gt 0) {
            Write-Host "Result: NOT COMPLIANT - Device errors detected."
            $false
        }
        else {
            Write-Host "Result: COMPLIANT - No device errors detected."
            $true
        }

        break
    }

    # -------------------------
    # SET MODE (Execute)
    # -------------------------
    "Set" {

        Write-Host "=== SET MODE (Execute) ==="
        Write-Host "Generating driver error report..."

        $ok = Write-DriverLog

        if ($ok) {
            Write-Host "SET Result: Success (No errors present)"
            $true
        }
        else {
            Write-Host "SET Result: Completed (Errors logged for review)"
            $true   # Still return true because remediation is logging/reporting
        }

        break
    }

    default {
        Write-Host "ERROR: Unknown `$Method value: $Method"
        $false
        break
    }
}

