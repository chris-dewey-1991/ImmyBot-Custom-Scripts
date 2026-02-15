<#
    .NOTES
    ===========================================================================
    Name:           Configure Password Policy for Windows
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    This has been created to customise the certain sections of the password policy
    this waill cover weather the password is to be complex, Password history and the
    minimum lenght
#>


# -----------------------------
# Desired Settings
# -----------------------------
$DesiredComplexity     = $PasswordComplexity
$DesiredHistorySize    = $PasswordHistorySize
$DesiredMinLength      = $MinimumPasswordLength

$SecEditPath = "C:\secpol.cfg"

# -----------------------------
# Helper: Export Policy
# -----------------------------
function Export-Policy {
    Write-Host "Exporting current security policy..."
    if (Test-Path $SecEditPath) {
        Remove-Item $SecEditPath -Force -ErrorAction SilentlyContinue
    }

    secedit /export /cfg $SecEditPath | Out-Null
}

# -----------------------------
# Helper: Get Current Values
# -----------------------------
function Get-CurrentState {

    Export-Policy

    $content = Get-Content $SecEditPath -ErrorAction Stop

    $complexity = ($content | Select-String "^PasswordComplexity").ToString().Split("=")[1].Trim()
    $history    = ($content | Select-String "^PasswordHistorySize").ToString().Split("=")[1].Trim()
    $minLength  = ($content | Select-String "^MinimumPasswordLength").ToString().Split("=")[1].Trim()

    Remove-Item $SecEditPath -Force -ErrorAction SilentlyContinue

    return @{
        Complexity = [int]$complexity
        History    = [int]$history
        MinLength  = [int]$minLength
    }
}

# -----------------------------
# Required Switch
# -----------------------------
switch ($Method) {

    "Get" {
        Write-Host "=== GET MODE ==="
        $state = Get-CurrentState

        Write-Host "Current Policy Values:"
        Write-Host " - PasswordComplexity     : $($state.Complexity)"
        Write-Host " - PasswordHistorySize    : $($state.History)"
        Write-Host " - MinimumPasswordLength  : $($state.MinLength)"

        $state
        break
    }

    "Test" {

        Write-Host "=== TEST MODE (Detect / Verify) ==="

        $state = Get-CurrentState

        $desiredComplexityInt = if ($DesiredComplexity) { 1 } else { 0 }

        Write-Host "Current Values:"
        Write-Host " - Complexity     : $($state.Complexity)"
        Write-Host " - History        : $($state.History)"
        Write-Host " - MinLength      : $($state.MinLength)"

        Write-Host "Desired Values:"
        Write-Host " - Complexity     : $desiredComplexityInt"
        Write-Host " - History        : $DesiredHistorySize"
        Write-Host " - MinLength      : $DesiredMinLength"

        if (
            $state.Complexity -eq $desiredComplexityInt -and
            $state.History -eq $DesiredHistorySize -and
            $state.MinLength -eq $DesiredMinLength
        ) {
            Write-Host "Result: COMPLIANT"
            $true
        }
        else {
            Write-Host "Result: NOT COMPLIANT"
            $false
        }

        break
    }

    "Set" {

        Write-Host "=== SET MODE (Execute) ==="
        Write-Host "Applying desired password policy settings..."

        Export-Policy
        $content = Get-Content $SecEditPath

        $desiredComplexityInt = if ($DesiredComplexity) { 1 } else { 0 }

        $content = $content -replace "PasswordComplexity = \d+", "PasswordComplexity = $desiredComplexityInt"
        $content = $content -replace "PasswordHistorySize = \d+", "PasswordHistorySize = $DesiredHistorySize"
        $content = $content -replace "MinimumPasswordLength = \d+", "MinimumPasswordLength = $DesiredMinLength"

        Set-Content $SecEditPath $content

        Write-Host "Configuring security database..."
        secedit /configure /db C:\Windows\security\local.sdb /cfg $SecEditPath /areas SECURITYPOLICY | Out-Null

        Remove-Item $SecEditPath -Force -ErrorAction SilentlyContinue

        Write-Host "Password policy applied successfully."

        # Return true so Execute shows 100%
        $true

        break
    }
}
