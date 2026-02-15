<#
    .NOTES
    ===========================================================================
    Name:           Create CID-Admin Local Account
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        2.0
    ===========================================================================
    .DESCRIPTION
    Create the CID-Admin local account for the computer. This uses the $TenantSlug
    to obtain the clients CID and applies this to the username. 
    This then adds this user to the Administrator group.
#>

# -----------------------------
# Hardcoded values (edit these)
# -----------------------------
$UserName     = "$TenantSlug-Admin"
$Password     = "PASSWORD" # Replace PASSWORD with the temp password you would like to use. IMPORTANT this should be rotated. We use CyberQP to do this for us.
$FullName     = $UserName
$Description  = "IT Support Local Admin Account"
$AdminGroup   = "Administrators"

$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

# -----------------------------
# Helper: Get Current State
# -----------------------------
function Get-State {

    $user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

    $exists = [bool]$user
    $isAdmin = $false

    if ($exists) {
        try {
            $members = Get-LocalGroupMember -Group $AdminGroup -ErrorAction Stop
            $isAdmin = $members.Name -contains $UserName -or
                       $members.Name -contains "$env:COMPUTERNAME\$UserName"
        } catch {
            $isAdmin = $false
        }
    }

    return [pscustomobject]@{
        UserName = $UserName
        Exists   = $exists
        IsAdmin  = $isAdmin
    }
}

# -----------------------------
# ImmyBot Required Switch
# -----------------------------
switch ($Method) {

    "Get" {
        Get-State
        break
    }

    "Test" {
        $state = Get-State
        return ($state.Exists -and $state.IsAdmin)
    }

    "Set" {

        $state = Get-State

        # Create user if missing
        if (-not $state.Exists) {
            New-LocalUser `
                -Name $UserName `
                -Password $SecurePassword `
                -FullName $FullName `
                -Description $Description `
                -ErrorAction Stop | Out-Null

            Write-Host "Created local user: $UserName"
        }
        else {
            Write-Host "User already exists: $UserName"
        }

        # Ensure Administrators membership
        if (-not $state.IsAdmin) {
            try {
                Add-LocalGroupMember -Group $AdminGroup -Member $UserName -ErrorAction Stop
                Write-Host "Added $UserName to $AdminGroup"
            }
            catch {
                if ($_.Exception.Message -notmatch "already a member") {
                    throw $_
                }
                Write-Host "$UserName already in $AdminGroup"
            }
        }
        else {
            Write-Host "$UserName already compliant"
        }

        break
    }
}
