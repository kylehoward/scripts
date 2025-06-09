<#
.SYNOPSIS
    Checks if Greenshot is installed on the system. If not, installs Greenshot silently for all users using Chocolatey.
.DESCRIPTION
    - Verifies if Greenshot is installed by checking the registry and default install paths.
    - If Greenshot is not found, checks for Chocolatey and installs it if missing.
    - Uses Chocolatey to install Greenshot silently for all users.
    - Logs all actions and errors to c:\loggy\greenshot.log.
    - Displays a progress bar and user feedback for each step.
    - Requires PowerShell 7+ and administrative privileges.
.NOTES
    Author: [Your Name]
    Date:   2025-06-09
#>

# Ensure log directory exists
$logDir = "C:\loggy"
$logFile = "$logDir\greenshot.log"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -FilePath $logFile -Append
}

function Log-And-Host {
    param([string]$Message)
    Write-Log $Message
    Write-Host $Message
}

function Show-Progress {
    param([string]$Activity, [int]$Percent)
    Write-Progress -Activity $Activity -PercentComplete $Percent
    Write-Log "Progress: $Activity ($Percent%)"
}

Write-Log "Script started."

# Step 1: Check if Greenshot is installed
Show-Progress -Activity "Checking for Greenshot installation..." -Percent 10
Write-Log "STEP: Checking if Greenshot is installed by searching registry and default paths."
$greenshotInstalled = $false

# Check registry for installed apps
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($path in $regPaths) {
    try {
        Write-Log "Checking registry path: $path"
        $apps = Get-ChildItem $path -ErrorAction Stop | Get-ItemProperty -ErrorAction Stop
        foreach ($app in $apps) {
            Write-Log "Found registry entry: $($app.DisplayName)"
        }
        if ($apps | Where-Object { $_.DisplayName -like "*Greenshot*" }) {
            $greenshotInstalled = $true
            Write-Log "SUCCESS: Greenshot found in registry at $path."
            break
        }
    } catch {
        Write-Log ("ERROR: Could not access registry path {0}: {1}" -f $path, $_)
    }
}

# Check default install path if not found in registry
if (-not $greenshotInstalled) {
    Write-Log "Greenshot not found in registry, checking default install paths."
    $defaultPaths = @(
        "C:\Program Files\Greenshot\Greenshot.exe",
        "C:\Program Files (x86)\Greenshot\Greenshot.exe"
    )
    foreach ($exe in $defaultPaths) {
        if (Test-Path $exe) {
            $greenshotInstalled = $true
            Write-Log "Greenshot found at $exe."
            break
        }
    }
}

if ($greenshotInstalled) {
    Log-And-Host "Greenshot is already installed."
    Show-Progress -Activity "Greenshot already installed." -Percent 100
    exit 0
}

Log-And-Host "Greenshot not found. Proceeding with installation."
Show-Progress -Activity "Greenshot not found. Preparing to install..." -Percent 20

# Step 2: Check for Chocolatey
Show-Progress -Activity "Checking for Chocolatey..." -Percent 25
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Log-And-Host "Chocolatey not found. Installing Chocolatey."
    Show-Progress -Activity "Installing Chocolatey..." -Percent 30
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    try {
        $chocoInstallOutput = Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) 2>&1
        Write-Log "Chocolatey install output: $chocoInstallOutput"
        Log-And-Host "Chocolatey installed successfully."
    } catch {
        Log-And-Host "Failed to install Chocolatey: $_"
        exit 1
    }
} else {
    Log-And-Host "Chocolatey is already installed."
}

Show-Progress -Activity "Installing Greenshot via Chocolatey..." -Percent 50

# Step 3: Install Greenshot silently for all users
try {
    $installArgs = "install greenshot --yes"
    Write-Log "Running: choco $installArgs"
    $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$logDir\choco_output.log" -RedirectStandardError "$logDir\choco_error.log"
    Write-Log "choco exit code: $($process.ExitCode)"
    if (Test-Path "$logDir\choco_output.log") {
        Write-Log "choco output:`n$(Get-Content "$logDir\choco_output.log" -Raw)"
    }
    if (Test-Path "$logDir\choco_error.log") {
        Write-Log "choco error:`n$(Get-Content "$logDir\choco_error.log" -Raw)"
    }
    if ($process.ExitCode -eq 0) {
        Log-And-Host "Greenshot installed successfully."
        Show-Progress -Activity "Greenshot installed successfully." -Percent 100
    } else {
        Log-And-Host "Greenshot installation failed. Exit code: $($process.ExitCode)"
        exit 1
    }
} catch {
    Log-And-Host "Error during Greenshot installation: $_"
    exit 1
}

Write-Log "Script completed."
Show-Progress -Activity "Script completed." -Percent 100