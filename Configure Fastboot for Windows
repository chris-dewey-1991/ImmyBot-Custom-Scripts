<#
    .NOTES
    ===========================================================================
    Name:           Configure Fastboot for Windows
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    Changes in v1.0:
      - Initial release
    ===========================================================================
    .DESCRIPTION
    This will look to update the fastboot settings within windows and by default
    turns it off. Changing the value from 0 to 1 enables fastboot
#>

# Param are used within immybot as a selection on a form
    param(
    [Parameter(
        Position=0,
        Mandatory=$false,
        HelpMessage=@'
Choose whether Fast Boot should be Disabled or Enabled.
'@
    )]
    [ValidateSet('Yes','No')]
    [string]$DisableFastBoot = 'Yes'
)

# Map friendly choice to the registry DWORD value
$dwordValue = switch ($DisableFastBoot) {
    'Yes' { 0 }
    'No'  { 1 }
}

Get-WindowsRegistryValue `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
    -Name "HiberbootEnabled" `
    -AllowedType DWord |
    RegistryShould-Be -Value $dwordValue
