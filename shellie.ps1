<#
    shellie.ps1
    This script checks if oh-my-posh is configured as the default prompt for PowerShell 7 (all users).
    If not, it installs oh-my-posh, sets up a theme, and updates the all-users profile.
    All progress and results are logged to C:\loggy\shellie.log.
    A progress bar is shown during setup steps.
#>

# --- Logging setup ---
$logPath = "C:\loggy\shellie.log"
if (!(Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}
function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $msg" | Out-File -FilePath $logPath -Append
}

Write-Log "=== Starting oh-my-posh default shell check ==="

# --- Variables and remarks ---
$profilePath = $PROFILE.AllUsersAllHosts
$themeDir = "C:\ProgramData\ohmyposh\themes"
$themeFile = "$themeDir\jandedobbeleer.omp.json"
$initBlock = @'
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Import-Module oh-my-posh -ErrorAction SilentlyContinue
}
oh-my-posh init pwsh --config "C:\ProgramData\ohmyposh\themes\jandedobbeleer.omp.json" | Invoke-Expression
'@

# --- Check if oh-my-posh is already the default shell ---
$profileContent = ""
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
}

if ($profileContent -match "oh-my-posh init pwsh") {
    Write-Log "oh-my-posh is already set as the default shell in $profilePath."
    Write-Host "oh-my-posh is already the default shell."
} else {
    Write-Log "oh-my-posh not found in $profilePath. Proceeding with setup..."

    $steps = @(
        @{ Name = "Install oh-my-posh"; Action = {
            if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
                Write-Log "oh-my-posh not found. Installing module for all users..."
                Install-Module oh-my-posh -Scope AllUsers -Force -ErrorAction Stop
                Write-Log "oh-my-posh module installed successfully."
            } else {
                Write-Log "oh-my-posh is already installed."
            }
        }},
        @{ Name = "Create theme directory"; Action = {
            if (!(Test-Path $themeDir)) {
                New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
                Write-Log "Created theme directory: $themeDir"
            }
        }},
        @{ Name = "Download theme"; Action = {
            if (!(Test-Path $themeFile)) {
                Invoke-WebRequest -Uri "https://ohmyposh.dev/themes/jandedobbeleer.omp.json" -OutFile $themeFile
                Write-Log "Downloaded oh-my-posh theme to $themeFile"
            }
        }},
        @{ Name = "Update all-users profile"; Action = {
            if (-not (Test-Path $profilePath)) {
                New-Item -ItemType File -Path $profilePath -Force | Out-Null
                Write-Log "Created profile file: $profilePath"
            }
            if (-not (Get-Content $profilePath -Raw | Select-String "oh-my-posh init pwsh" -Quiet)) {
                Add-Content -Path $profilePath -Value $initBlock
                Write-Log "Added oh-my-posh init block to $profilePath"
            }
        }}
    )

    $stepCount = $steps.Count
    for ($i = 0; $i -lt $stepCount; $i++) {
        $percent = [int](($i / $stepCount) * 100)
        Write-Progress -Activity "Configuring oh-my-posh as default shell" -Status $steps[$i].Name -PercentComplete $percent
        try {
            & $steps[$i].Action
        } catch {
            Write-Log "Error during step '$($steps[$i].Name)': $_"
            Write-Host "Error during step '$($steps[$i].Name)': $_"
        }
    }
    Write-Progress -Activity "Configuring oh-my-posh as default shell" -Completed
    Write-Log "oh-my-posh setup complete. It is now the default shell for all users."
    Write-Host "oh-my-posh is now set as the default shell for all users."
}

<#
-------------------------------
Instructions for Use:
-------------------------------
- Run this script as Administrator in PowerShell 7.
- It will check if oh-my-posh is the default shell for all users.
- If not, it will install oh-my-posh, download a theme, and update the all-users profile.
- Progress and results are logged to C:\loggy\shellie.log.

-------------------------------
Theory of Operation:
-------------------------------
- The script checks the AllUsersAllHosts profile for the oh-my-posh init line.
- If missing, it installs oh-my-posh (PowerShell module), ensures a theme is present,
  and appends an init block to the all-users profile.
- This ensures every PowerShell 7 session for all users loads oh-my-posh by default.
- All actions and errors are logged for auditing and troubleshooting.
#>