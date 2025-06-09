param(
    [switch]$Uninstall
)

$logPath = "C:\loggy\todoist.log"
$installerPath = "$env:TEMP\todoist-setup.exe"
$todoistUrl = "https://electron-dl.todoist.net/windows/Todoist-win32-9.15.0-latest.exe"

# All possible install locations for Todoist.exe and related folders
$todoistExePaths = @(
    "$env:LOCALAPPDATA\Programs\Todoist\Todoist.exe",
    "$env:ProgramFiles\Todoist\Todoist.exe",
    "$env:ProgramFiles(x86)\Todoist\Todoist.exe"
)
$todoistDirs = @(
    "$env:LOCALAPPDATA\Programs\Todoist",
    "$env:ProgramFiles\Todoist",
    "$env:ProgramFiles(x86)\Todoist"
)
# Known AppData and Start Menu artifacts
$appDataPaths = @(
    "$env:APPDATA\Todoist",
    "$env:LOCALAPPDATA\Todoist",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Todoist",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Todoist"
)
# Known registry keys (user and machine, if any)
$registryPaths = @(
    "HKCU:\Software\Todoist",
    "HKLM:\Software\Todoist",
    "HKLM:\Software\WOW6432Node\Todoist"
)

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $message" | Out-File -FilePath $logPath -Append
}

function Wait-For-TodoistExe {
    param([int]$TimeoutSeconds = 10)
    $startTime = Get-Date
    while ((Get-Date) - $startTime -lt (New-TimeSpan -Seconds $TimeoutSeconds)) {
        foreach ($exe in $todoistExePaths) {
            if (Test-Path $exe) { return $true }
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Is-TodoistInstalled {
    foreach ($exe in $todoistExePaths) {
        if (Test-Path $exe) { return $true }
    }
    return $false
}

function Show-Spinner {
    param(
        [string]$Message = "Processing",
        [scriptblock]$Action,
        [int]$TimeoutSeconds = 120, # Increased timeout to 120 seconds
        [string]$WaitFor = "operation"
    )
    $spinner = @('|','/','-','\')
    $i = 0
    $job = Start-Job -ScriptBlock $Action
    $startTime = Get-Date
    while ($true) {
        if ($job.State -eq 'Completed') { break }
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -ge $TimeoutSeconds) {
            Stop-Job $job | Out-Null
            Log "Timeout waiting for $WaitFor after $TimeoutSeconds seconds."
            Write-Host "`nTimeout waiting for $WaitFor after $TimeoutSeconds seconds."
            throw "Timeout waiting for $WaitFor after $TimeoutSeconds seconds."
        }
        Write-Host -NoNewline ("`r{0} {1}..." -f $spinner[$i % $spinner.Length], $Message)
        Start-Sleep -Milliseconds 200
        $i++
    }
    Write-Host "`r$Message...done.           "
    Receive-Job $job
    Remove-Job $job
}

if ($Uninstall) {
    try {
        Log "Uninstall started."
        Write-Output "Uninstalling Todoist..."

        # Attempt to uninstall via Chocolatey
        try {
            Show-Spinner -Message "Uninstalling Todoist with Chocolatey" -TimeoutSeconds 120 -WaitFor "choco uninstall" -Action {
                choco uninstall todoist -y --no-progress | Out-Null
            }
        } catch {
            Log "Chocolatey uninstall failed or Chocolatey not available: $_"
        }

        # Kill any running Todoist processes
        Get-Process -Name "Todoist" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

        # Remove installed files and folders from all known locations
        foreach ($exe in $todoistExePaths) {
            if (Test-Path $exe) {
                Remove-Item $exe -Force -ErrorAction SilentlyContinue
            }
        }
        foreach ($dir in $todoistDirs) {
            if (Test-Path $dir) {
                Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # Remove installer if present
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        }

        # Remove related AppData folders and Start Menu shortcuts (brute force)
        foreach ($path in $appDataPaths) {
            if (Test-Path $path) {
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # Remove registry keys if present
        foreach ($reg in $registryPaths) {
            if (Test-Path $reg) {
                Remove-Item $reg -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Log "Uninstall complete."
        Write-Output "Todoist and related files have been removed."
    } catch {
        Log "Unexpected error during uninstall: $_"
        Write-Output "Unexpected error during uninstall: $_"
    }
    exit
}

try {
    Log "Script started."

    if (Is-TodoistInstalled) {
        Log "Todoist is already installed."
        Write-Output "Todoist is already installed."
    } else {
        # Try Chocolatey first
        Log "Todoist not found. Attempting installation with Chocolatey."
        try {
            Show-Spinner -Message "Installing Todoist with Chocolatey" -TimeoutSeconds 120 -WaitFor "choco install" -Action {
                choco install todoist -y --no-progress | Out-Null
            }
        } catch {
            Log "Chocolatey install failed or Chocolatey not available: $_"
        }

        if (Wait-For-TodoistExe -TimeoutSeconds 20) {
            Log "Todoist installed successfully via Chocolatey."
            Write-Output "Todoist installed successfully via Chocolatey."
        } else {
            Log "Chocolatey install did not succeed. Proceeding with direct installer."
            try {
                Show-Spinner -Message "Downloading Todoist installer" -TimeoutSeconds 120 -WaitFor "download" -Action {
                    Invoke-WebRequest -Uri $using:todoistUrl -OutFile $using:installerPath -ErrorAction Stop
                }
                if (!(Test-Path $installerPath) -or ((Get-Item $installerPath).Length -eq 0)) {
                    Log "Download failed: Installer file not found or empty."
                    Write-Output "Download failed: Installer file not found or empty."
                    throw "Download failed."
                }
                Log "Download completed. Running installer."
                Show-Spinner -Message "Running Todoist installer" -TimeoutSeconds 120 -WaitFor "installation" -Action {
                    $process = Start-Process -FilePath $using:installerPath -ArgumentList "/S" -Wait -PassThru
                    return $process.ExitCode
                }
                if (Wait-For-TodoistExe -TimeoutSeconds 20) {
                    Log "Todoist installed successfully."
                    Write-Output "Todoist installed successfully."
                } else {
                    Log "Todoist installation failed: Executable not found."
                    Write-Output "Todoist installation failed: Executable not found."
                }
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                Log "Installer cleaned up."
            } catch {
                Log "Error during download or installation: $_"
                Write-Output "Error during download or installation: $_"
            }
        }
    }

    Log "Script finished."
} catch {
    Log "Unexpected error: $_"
    Write-Output "Unexpected error: $_"
}