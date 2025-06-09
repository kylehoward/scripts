<#
    cygwin.ps1
    This script checks if Cygwin is installed and installs it if missing.
    All actions and errors are logged to C:\loggy\cygwin.log.
    A progress bar is shown during setup steps.
#>

# --- Logging setup ---
$logPath = "C:\loggy\cygwin.log"
if (!(Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}
function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $msg" | Out-File -FilePath $logPath -Append
}

Write-Log "=== Starting Cygwin install/check ==="

# --- Variables ---
$cygwinRoot = "C:\cygwin64"
$cygwinBash = "$cygwinRoot\bin\bash.exe"
$cygwinInstaller = "$env:TEMP\cygwin-setup-x86_64.exe"
$cygwinUrl = "https://www.cygwin.com/setup-x86_64.exe"

# --- Cygwin install/check with progress bar ---
if (-not (Test-Path $cygwinBash)) {
    Write-Log "Cygwin not found at $cygwinBash. Installing..."
    Write-Progress -Activity "Cygwin Setup" -Status "Downloading installer..." -PercentComplete 10
    if (-not (Test-Path $cygwinInstaller)) {
        Invoke-WebRequest -Uri $cygwinUrl -OutFile $cygwinInstaller
        Write-Log "Downloaded Cygwin installer."
    }
    Write-Progress -Activity "Cygwin Setup" -Status "Running installer..." -PercentComplete 60
    Start-Process -FilePath $cygwinInstaller -ArgumentList "--quiet-mode --root $cygwinRoot" -Wait
    Write-Log "Cygwin installed to $cygwinRoot."
    Write-Progress -Activity "Cygwin Setup" -Completed
    Write-Host "Cygwin installation complete."
} else {
    Write-Log "Cygwin is already installed at $cygwinRoot."
    Write-Host "Cygwin is already installed at $cygwinRoot."
}

<#
-------------------------------
Instructions for Use:
-------------------------------
- Run this script as Administrator in PowerShell 7.
- It will check if Cygwin is installed and install it if missing.
- All actions and errors are logged to C:\loggy\cygwin.log.
- A progress bar is shown during setup steps.

-------------------------------
Theory of Operation:
-------------------------------
- The script checks for the Cygwin bash executable at the default location.
- If missing, it downloads the official Cygwin installer and runs it in quiet mode.
- All steps and errors are logged for auditing and troubleshooting.
- The progress bar provides user feedback during download and installation.
#>