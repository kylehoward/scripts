<#
    git.ps1
    This script checks if Git is installed on the system and installs it if missing.
    All actions and errors are logged to C:\loggy\git.log.
    Inline remarks describe each step.
    See the end of the file for usage instructions and theory of operation.
#>

# --- Logging setup ---
$logPath = "C:\loggy\git.log"
if (!(Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}
function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $msg" | Out-File -FilePath $logPath -Append
}

Write-Log "=== Starting Git install/check ==="

# --- Check if Git is installed ---
Write-Log "Checking for Git installation..."
$gitInstalled = $false
try {
    $gitVersion = git --version 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitVersion) {
        $gitInstalled = $true
        Write-Log "Git is already installed: $gitVersion"
        Write-Host "Git is already installed: $gitVersion"
    }
} catch {
    Write-Log "Git not found in PATH."
}

# --- Install Git if not installed ---
if (-not $gitInstalled) {
    Write-Log "Git not found. Installing via winget..."
    Write-Progress -Activity "Git Setup" -Status "Installing Git..." -PercentComplete 50

    # Try to use winget if available
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements -h
            Write-Log "Git installation attempted via winget."
        } catch {
            Write-Log "Error installing Git via winget: $_"
        }
    } else {
        Write-Log "winget not found. Please install Git manually."
        Write-Host "winget not found. Please install Git manually."
    }

    Write-Progress -Activity "Git Setup" -Completed

    # Re-check installation
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitVersion) {
            Write-Log "Git installed successfully: $gitVersion"
            Write-Host "Git installed successfully: $gitVersion"
        } else {
            Write-Log "Git installation failed or not found in PATH after install."
            Write-Host "Git installation failed or not found in PATH after install."
        }
    } catch {
        Write-Log "Git installation failed or not found in PATH after install."
        Write-Host "Git installation failed or not found in PATH after install."
    }
}

<#
-------------------------------
Instructions for Use:
-------------------------------
- Run this script as Administrator in PowerShell 7.
- It will check if Git is installed and install it if missing (using winget).
- All actions and errors are logged to C:\loggy\git.log.

-------------------------------
Theory of Operation:
-------------------------------
- The script checks for Git by running 'git --version'.
- If not found, it attempts to install Git using winget.
- All steps and errors are logged for auditing and troubleshooting.
- The progress bar provides user feedback during installation.
- If winget is not available, the script will prompt for manual installation.
#>