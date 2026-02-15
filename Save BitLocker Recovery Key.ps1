<#
    .NOTES
    ===========================================================================
    Name:           Save BitLocker Recovery Key
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    This will detect the BitLocker Recovery Key and saves this to a certain location
    on the computer. This allows us to save the txt file to the configureation on our
    documentation site. We also save direct to Microsoft but like two forms of the key
#>


param (
    [string]$FilePath = "C:\Source\BitLockerRecoveryKeys.txt",
    [string]$ComputerName = "localhost"
)

# -----------------------------
# Helper: Get Current State
# -----------------------------
function Get-State {

    $fileExists = Test-Path -Path $FilePath
    $hasContent = $false

    if ($fileExists) {
        $content = Get-Content -Path $FilePath -ErrorAction SilentlyContinue
        if ($content -match "\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}") {
            $hasContent = $true
        }
    }

    [pscustomobject]@{
        ComputerName = $ComputerName
        FilePath     = $FilePath
        FileExists   = $fileExists
        ContainsKey  = $hasContent
    }
}

# -----------------------------
# Helper: Export Keys
# -----------------------------
function Export-RecoveryKeys {

    Write-Host "Starting BitLocker recovery key export..."
    Write-Host "Target file: $FilePath"

    # Ensure directory exists
    $directory = Split-Path $FilePath
    if (-not (Test-Path $directory)) {
        Write-Host "Creating directory: $directory"
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    # Remove existing file
    if (Test-Path $FilePath) {
        Write-Host "Removing existing file..."
        Remove-Item -Path $FilePath -Force -ErrorAction SilentlyContinue
    }

    $success = $false

    try {
        Get-BitLockerVolume -ErrorAction Stop | ForEach-Object {

            $RecoveryKey = $_.KeyProtector |
                Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' } |
                Select-Object -ExpandProperty RecoveryPassword

            if ($RecoveryKey) {

                Write-Host "Found recovery key for volume: $($_.MountPoint)"

                $_ | Select-Object `
                    MountPoint,
                    VolumeStatus,
                    @{Name='RecoveryKey';Expression={$RecoveryKey}} |
                Format-Table -AutoSize |
                Out-File -Append -FilePath $FilePath

                $success = $true
            }
        }

        if ($success) {
            Write-Host "Recovery keys successfully written to file."
        }
        else {
            Write-Host "No recovery keys found."
        }

        return $success
    }
    catch {
        Write-Host "ERROR: Failed to retrieve BitLocker information."
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

        Write-Host "Computer Name : $($state.ComputerName)"
        Write-Host "File Path     : $($state.FilePath)"
        Write-Host "File Exists   : $($state.FileExists)"
        Write-Host "Contains Key  : $($state.ContainsKey)"

        $state
        break
    }

    # -------------------------
    # TEST MODE (Detect/Verify)
    # -------------------------
    "Test" {

        Write-Host "=== TEST MODE (Detect / Verify) ==="

        $state = Get-State

        if ($state.FileExists -and $state.ContainsKey) {
            Write-Host "Result: COMPLIANT - Recovery key file exists and contains key(s)."
            $true
        }
        else {
            Write-Host "Result: NOT COMPLIANT - Recovery key file missing or empty."
            $false
        }

        break
    }

    # -------------------------
    # SET MODE (Execute)
    # -------------------------
    "Set" {

        Write-Host "=== SET MODE (Execute) ==="

        $ok = Export-RecoveryKeys

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
