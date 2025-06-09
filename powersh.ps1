$logDir = "C:\loggy"
$logFile = "$logDir\powershell.log"

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
    Write-Log "PowerShell 7 is already installed at $($pwshPath.Source)."
} else {
    Write-Log "PowerShell 7 not found. Installing..."
    try {
        # Download and install PowerShell 7 using winget if available
        if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
            winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements -e
            Write-Log "PowerShell 7 installation attempted via winget."
        } else {
            Write-Log "winget not found. Please install PowerShell 7 manually."
        }
    } catch {
        Write-Log "Error during installation: $_"
    }
}

Write-Log "Script finished."