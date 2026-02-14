param(
    [bool]$EnableWebSignIn
)

$regPath = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Authentication'
$name    = 'EnableWebSignIn'

# Ensure key exists
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

if ($EnableWebSignIn -eq $true) {
    Write-Host "TRUE block running... (Enable Web Sign-In)"

    $Desired = 1

    # Set DWORD to 1 (Enable)
    New-ItemProperty -Path $regPath -Name $name -PropertyType DWord -Value $Desired -Force | Out-Null
}

if ($EnableWebSignIn -eq $false) {
    Write-Host "FALSE block running... (Disable Web Sign-In)"

    $Desired = 0

    # Set DWORD to 0 (Disable)
    New-ItemProperty -Path $regPath -Name $name -PropertyType DWord -Value $Desired -Force | Out-Null
}

# Verify
try {
    $current = (Get-ItemProperty -Path $regPath -Name $name -ErrorAction Stop).$name
} catch {
    $current = $null
}

if ($current -eq $Desired) {
    Write-Host "PASS: Web Sign-In set correctly (Value=$current)" -ForegroundColor Green
    Write-Output $true
}
else {
    Write-Host "FAIL: Web Sign-In incorrect (Value=$current, Desired=$Desired)" -ForegroundColor Red
    Write-Output $false
}

