<#
    .NOTES
    ===========================================================================
    Name:           Configure Web Sign-In for Windows
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    Changes in v1.0:
      - Initial release
    ===========================================================================
    .DESCRIPTION
    This will enable Web Sign-in on Windows to allow users to sign in with TAP or there Office 365 details.
    This is used for our Technical Setup as we do not keep clients passwords. This allows us to utilize the TAP
    to onboard the device to intunes and configure the device for the user.
#>

# Param are used within immybot as a selection on a form
param(
    [Parameter(Position=0, Mandatory=$false)]
    [ValidateSet('0','1')]
    [string]$EnableWebSignIn = '1'
)

# This is Get, Set and Test all in one and is the actual deployment
Get-WindowsRegistryValue `
    -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Authentication" `
    -Name "EnableWebSignIn" `
    -AllowedType DWord |
    RegistryShould-Be -Value $EnableWebSignIn

