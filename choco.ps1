<#
.SYNOPSIS
Installs Chocolatey using PowerShell 7, with logging.

.DESCRIPTION
This script checks for PowerShell 7 and Chocolatey on the system. 
If PowerShell 7 is present but Chocolatey is not, it installs Chocolatey for all users.
All actions and errors are logged to C:\loggy\2choco.log.
If PowerShell 7 is missing, the script prompts the user to run 1powershell.ps1 first.

.NOTES
Requires administrative privileges to install Chocolatey.
#>

$logDir = "C:\loggy"
$logFile = "$logDir\2choco.log"

# Ensure log directory exists
if (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}

function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
}

Write-Log "Script started."

# Check if PowerShell 7 is installed
$pwshPath = Get-Command pwsh.exe -ErrorAction SilentlyContinue

if ($pwshPath) {
    Write-Log "PowerShell 7 detected at $($pwshPath.Source)."
    # Check if Chocolatey is installed
    $chocoPath = Get-Command choco.exe -ErrorAction SilentlyContinue
    if ($chocoPath) {
        Write-Log "Chocolatey is already installed at $($chocoPath.Source). Nothing to do."
        Write-Log "Script finished."
        exit
    } else {
        Write-Log "Chocolatey not found. Installing Chocolatey for all users..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Log "Chocolatey installation attempted."
        } catch {
            Write-Log "Error during Chocolatey installation: $_"
        }
    }
} else {
    $msg = "PowerShell 7 not found. Please run 1powershell.ps1 first."
    Write-Log $msg
    Write-Host $msg -ForegroundColor Yellow
}

Write-Log "Script finished."