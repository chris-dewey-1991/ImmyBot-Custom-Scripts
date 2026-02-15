<#
    .NOTES
    ===========================================================================
    Name:           Create CID-Admin Local Account
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    Create the CID-Admin local account for the computer. This uses the $TenantSlug
    to obtain the clients CID and applies this to the username. 
    This then adds this user to the Administrator group.
#>

# -----------------------------
# Hardcoded values (edit these)
# -----------------------------
$UserNamePlain = "$TenantSlug-Admin"  # e.g. "acme-Admin" or "TenantSlug-Admin"
$PasswordPlain = "PASSWORD" # Replace PASSWORD with the temp password you would like to use. IMPORTANT this should be rotated. We use CyberQP to do this for us.
$FullName      = $UserNamePlain
$Description   = "Administrator Account"
$AdminGroup    = "Administrators"

# Convert password to SecureString
$SecurePassword = ConvertTo-SecureString $PasswordPlain -AsPlainText -Force

function Get-TargetResource {
    $user = Get-LocalUser -Name $UserNamePlain -ErrorAction SilentlyContinue

    $isAdmin = $false
    if ($user) {
        try {
            $members = Get-LocalGroupMember -Group $AdminGroup -ErrorAction Stop
            # Depending on how Windows reports it, it may be "User" or "COMPUTER\User"
            $isAdmin = $members.Name -contains $UserNamePlain -or $members.Name -contains "$env:COMPUTERNAME\$UserNamePlain"
        } catch {
            $isAdmin = $false
        }
    }

    [pscustomobject]@{
        UserName = $UserNamePlain
        Exists   = [bool]$user
        IsAdmin  = [bool]$isAdmin
    }
}

function Test-TargetResource {
    $state = Get-TargetResource
    return ($state.Exists -and $state.IsAdmin)
}

function Set-TargetResource {
    $state = Get-TargetResource

    if (-not $state.Exists) {
        try {
            New-LocalUser `
                -Name $UserNamePlain `
                -Password $SecurePassword `
                -FullName $FullName `
                -Description $Description `
                -ErrorAction Stop | Out-Null

            Write-Host "Created local user: $UserNamePlain"
        } catch {
            throw "Failed to create user '$UserNamePlain': $($_.Exception.Message)"
        }
    } else {
        Write-Host "User '$UserNamePlain' already exists. Skipping creation."
    }

    # Re-check before group add (user may have just been created)
    $state = Get-TargetResource

    if (-not $state.IsAdmin) {
        try {
            Add-LocalGroupMember -Group $AdminGroup -Member $UserNamePlain -ErrorAction Stop
            Write-Host "Added '$UserNamePlain' to '$AdminGroup'."
        } catch {
            $msg = $_.Exception.Message
            if ($msg -match "already a member") {
                Write-Host "'$UserNamePlain' is already in '$AdminGroup'."
            } else {
                throw "Failed to add '$UserNamePlain' to '$AdminGroup': $msg"
            }
        }
    } else {
        Write-Host "'$UserNamePlain' is already a member of '$AdminGroup'."
    }
}

# -----------------------------
# ImmyBot compliance execution
# -----------------------------
$state = Get-TargetResource
Write-Host ("Current State: " + ($state | ConvertTo-Json -Compress))

if (-not (Test-TargetResource)) {
    Set-TargetResource
}

# Return final compliance result
Test-TargetResource
