<#
    .NOTES
    ===========================================================================
    Name:           Delete Provisioning Admin User
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    In the provisioning stage the immybot tool create's a Provisioning-Admin this
    is used just incase the immybot process fails and is deleted at the first couple
    of stages. This deletes the profile when it is no longer used. 
#>

# -----------------------------
# Target User to Remove
# -----------------------------
$username = "Provisioning-Admin"

# -----------------------------
# Helper: Get Current State
# -----------------------------
function Get-State {

    $user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    return @{
        UserName = $username
        Exists   = [bool]$user
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

        Write-Host "User Checked: $($state.UserName)"
        Write-Host "Exists      : $($state.Exists)"

        $state
        break
    }

    # -------------------------
    # TEST MODE (Detect/Verify)
    # -------------------------
    "Test" {

        Write-Host "=== TEST MODE (Detect / Verify) ==="

        $state = Get-State

        if ($state.Exists) {
            Write-Host "Result: NOT COMPLIANT - User '$username' still exists."
            $false
        }
        else {
            Write-Host "Result: COMPLIANT - User '$username' is not present."
            $true
        }

        break
    }

    # -------------------------
    # SET MODE (Execute)
    # -------------------------
    "Set" {

        Write-Host "=== SET MODE (Execute) ==="
        Write-Host "Attempting to remove user: $username"

        $state = Get-State

        if ($state.Exists) {

            try {
                Remove-LocalUser -Name $username -ErrorAction Stop
                Write-Host "User '$username' removed successfully."
            }
            catch {
                Write-Host "ERROR: Failed to remove user '$username'"
                Write-Host $_.Exception.Message
                $false
                break
            }

        }
        else {
            Write-Host "User '$username' not found. Nothing to remove."
        }

        # Return TRUE so Execute shows 100%
        $true
        break
    }
}
