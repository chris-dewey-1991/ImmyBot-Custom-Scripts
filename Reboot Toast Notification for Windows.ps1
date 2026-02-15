<#
    .NOTES
    ===========================================================================
    Name:           Reboot Toast Notification for Windows
    Purpose:        Use with immybot
    Created by:     Chris Dewey
    Updated:        2026.02.15
    Version:        1.0
    ===========================================================================
    .DESCRIPTION
    This creates a task schdule that runs and if the computer's uptime is more than
    a certain amount of days. It will trigger a popup called toast on the users side
    it then will ask them to reboot. 
#>


# Parameters
param (
    [string]$Reboottoast_url,
    [string]$Reboottoast_output,
    [string]$ExtractPath,
    [string]$TaskName,
    [int]$SleepDuration
)

# -----------------------------
# Helper: Internet Check
# -----------------------------
function Test-InternetConnection {
    try {
        $request = [System.Net.WebRequest]::Create("http://www.google.com")
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch {
        return $false
    }
}

# -----------------------------
# Helper: Get State
# -----------------------------
function Get-State {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    [pscustomobject]@{
        TaskName          = $TaskName
        TaskExists        = [bool]$task
        DownloadUrl       = $Reboottoast_url
        ZipOutput         = $Reboottoast_output
        ExtractPath       = $ExtractPath
        TaskXmlPath       = (Join-Path $ExtractPath 'NP Pending Reboot Request Task.xml')
        SleepDurationSecs = $SleepDuration
    }
}

# -----------------------------
# Helper: Install / Remediate
# -----------------------------
function Install-RebootToast {
    Write-Host "Checking internet connectivity..."
    if (-not (Test-InternetConnection)) {
        Write-Host "ERROR: No internet connection. Cannot download package."
        return $false
    }
    Write-Host "Internet connectivity OK."

    # Ensure parent folder exists
    $parentDir = Split-Path -Path $Reboottoast_output -Parent
    if (-not (Test-Path $parentDir)) {
        Write-Host "Creating folder: $parentDir"
        try {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        } catch {
            Write-Host "ERROR: Failed to create folder: $parentDir"
            Write-Host $_.Exception.Message
            return $false
        }
    }

    $start = Get-Date
    Write-Host "Start time: $start"

    # Download ZIP
    Write-Host "Downloading ZIP..."
    Write-Host " - URL : $Reboottoast_url"
    Write-Host " - To  : $Reboottoast_output"

    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Reboottoast_url, $Reboottoast_output)
        Write-Host "Download completed."
    } catch {
        Write-Host "ERROR: Download failed."
        Write-Host $_.Exception.Message
        return $false
    }

    # Extract
    Write-Host "Extracting ZIP..."
    if (-not (Test-Path $ExtractPath)) {
        Write-Host "Creating extract folder: $ExtractPath"
        New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null
    }

    try {
        Expand-Archive -Path $Reboottoast_output -DestinationPath $ExtractPath -Force -ErrorAction Stop
        Write-Host "Extraction completed."
    } catch {
        Write-Host "ERROR: Extraction failed."
        Write-Host $_.Exception.Message
        return $false
    }

    # Sleep
    Write-Host "Sleeping for $SleepDuration seconds..."
    Start-Sleep -Seconds $SleepDuration

    # Register scheduled task
    $taskXmlPath = Join-Path $ExtractPath 'NP Pending Reboot Request Task.xml'
    Write-Host "Registering scheduled task..."
    Write-Host " - Task Name: $TaskName"
    Write-Host " - XML Path : $taskXmlPath"

    if (-not (Test-Path $taskXmlPath)) {
        Write-Host "ERROR: Task XML file not found."
        return $false
    }

    try {
        Register-ScheduledTask -Xml (Get-Content $taskXmlPath | Out-String) -TaskName $TaskName -Force
        Write-Host "Scheduled Task '$TaskName' created/updated successfully."
    } catch {
        Write-Host "ERROR: Failed to register scheduled task."
        Write-Host $_.Exception.Message
        return $false
    }

    # Cleanup ZIP
    Write-Host "Cleaning up ZIP file: $Reboottoast_output"
    try {
        Remove-Item $Reboottoast_output -Force -ErrorAction SilentlyContinue
        Write-Host "Cleanup completed."
    } catch {
        Write-Host "WARNING: Cleanup failed (ZIP may remain)."
        Write-Host $_.Exception.Message
        # Not failing compliance due to cleanup
    }

    $end = Get-Date
    Write-Host "Completed at: $end"
    Write-Host "Duration   : $($end - $start)"
    Write-Host "Reboot Toast Notification has been enabled."

    return $true
}

# -----------------------------
# ImmyBot Required Switch
# -----------------------------
switch ($Method) {

    "Get" {
        Write-Host "=== GET MODE ==="
        $state = Get-State
        Write-Host "TaskName   : $($state.TaskName)"
        Write-Host "TaskExists : $($state.TaskExists)"
        Write-Host "ZipOutput  : $($state.ZipOutput)"
        Write-Host "Extract    : $($state.ExtractPath)"
        Write-Host "TaskXml    : $($state.TaskXmlPath)"
        $state
        break
    }

    "Test" {
        Write-Host "=== TEST MODE (Detect / Verify) ==="
        $state = Get-State

        if ($state.TaskExists) {
            Write-Host "Result: COMPLIANT - Scheduled Task '$TaskName' exists."
            $true
        } else {
            Write-Host "Result: NOT COMPLIANT - Scheduled Task '$TaskName' is missing."
            $false
        }

        break
    }

    "Set" {
        Write-Host "=== SET MODE (Execute) ==="

        $ok = Install-RebootToast
        if ($ok) {
            Write-Host "SET Result: Success"
            $true
        } else {
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
