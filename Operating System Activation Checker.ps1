<#
    .NOTES
    ===========================================================================
    Name:           Operating System Activation Checker
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    This will check if the OS is activated. If its not it will mark as not 
    compliant.
#>
param (
    [string]$LogPath = "C:\Source\Logs"
)

# -----------------------------
# Script Configuration
# -----------------------------
$Date = (Get-Date).ToString("yyyyMMdd")
$LogFileName = "${Date}_Activation-Check-$env:COMPUTERNAME.txt"
$LogFilePath = Join-Path -Path $LogPath -ChildPath $LogFileName

# -----------------------------
# Helper: Ensure Log Directory
# -----------------------------
function Ensure-LogFolder {
    if (-not (Test-Path $LogPath)) {
        Write-Host "Creating log folder: $LogPath"
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
}

# -----------------------------
# Helper: Get Activation Status
# -----------------------------
function Get-ActivationState {

    $products = Get-CimInstance SoftwareLicensingProduct `
        -Filter "Name like 'Windows%'" |
        Where-Object { $_.PartialProductKey }

    # LicenseStatus meanings:
    # 0 = Unlicensed
    # 1 = Licensed (Activated)
    # Other values = Grace/Notification states

    $activated = $products | Where-Object { $_.LicenseStatus -eq 1 }

    return [pscustomobject]@{
        Activated = [bool]$activated
        Products  = $products | Select-Object Name, ProductKeyChannel, LicenseStatus
        LogFile   = $LogFilePath
    }
}

# -----------------------------
# Helper: Write Activation Log
# -----------------------------
function Write-ActivationLog {

    Ensure-LogFolder

    $state = Get-ActivationState

    "===================================================" | Out-File $LogFilePath -Append
    "Windows Activation Status Report"                    | Out-File $LogFilePath -Append
    "Computer : $env:COMPUTERNAME"                        | Out-File $LogFilePath -Append
    "Date     : $(Get-Date)"                              | Out-File $LogFilePath -Append
    "===================================================" | Out-File $LogFilePath -Append
    ""                                                    | Out-File $LogFilePath -Append

    $state.Products |
        Format-Table -AutoSize |
        Out-String |
        Out-File $LogFilePath -Append

    "" | Out-File $LogFilePath -Append

    if ($state.Activated) {
        "******************** Device is ACTIVATED ********************" |
            Out-File $LogFilePath -Append
        Write-Host "COMPLIANT - Device is Activated."
    }
    else {
        "******************** Device is NOT Activated ********************" |
            Out-File $LogFilePath -Append
        Write-Host "NOT COMPLIANT - Device is NOT Activated."
    }

    Write-Host "Log written to: $LogFilePath"

    return $state.Activated
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

        $state = Get-ActivationState

        Write-Host "Activated : $($state.Activated)"
        Write-Host "Log File  : $($state.LogFile)"

        # Return activation details
        $state.Products
        break
    }

    # -------------------------
    # TEST MODE (Detect/Verify)
    # -------------------------
    "Test" {

        Write-Host "=== TEST MODE (Detect / Verify) ==="

        $state = Get-ActivationState

        if ($state.Activated) {
            Write-Host "Result: COMPLIANT - Windows is Activated."
            $true
        }
        else {
            Write-Host "Result: NOT COMPLIANT - Windows is NOT Activated."
            $false
        }

        break
    }

    # -------------------------
    # SET MODE (Execute)
    # -------------------------
    "Set" {

        Write-Host "=== SET MODE (Execute) ==="
        Write-Host "Generating activation status report..."

        $activated = Write-ActivationLog

        if ($activated) {
            Write-Host "SET Result: Device already activated."
        }
        else {
            Write-Host "SET Result: Activation required - manual remediation needed."
        }

        # Return TRUE because Set cannot fix activation automatically
        $true
        break
    }

    default {
        Write-Host "ERROR: Unknown `$Method value: $Method"
        $false
        break
    }
}
