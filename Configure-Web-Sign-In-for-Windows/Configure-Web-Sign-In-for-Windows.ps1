param(
    [Parameter(Position=0, Mandatory=$false)]
    [ValidateSet('0','1')]
    [string]$EnableWebSignIn = '1'
)

Get-WindowsRegistryValue `
    -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Authentication" `
    -Name "EnableWebSignIn" `
    -AllowedType DWord |
    RegistryShould-Be -Value $EnableWebSignIn
