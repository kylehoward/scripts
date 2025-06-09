<#
    githubby.ps1
    This script pushes all scripts in the current directory to the GitHub repository
    https://github.com/kylehoward/setup_scripts.git, committing them if needed.
    It also updates the README.md file in the repository to document each script's purpose,
    function, and requirements (based on comments in each script).
    All actions and errors are logged to C:\loggy\githubby.log.
    Requires: git, and write access to the repository (SSH or HTTPS credentials set up).
#>

# --- Logging setup ---
$logPath = "C:\loggy\githubby.log"
if (!(Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}
function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $msg" | Out-File -FilePath $logPath -Append
}

Write-Log "=== Starting GitHub push ==="

# --- Variables ---
$repoUrl = "https://github.com/kylehoward/setup_scripts.git"
$repoName = "setup_scripts"
$cwd = Get-Location

# --- Ensure git is available ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "git is not installed or not in PATH. Aborting."
    Write-Log "git is not installed or not in PATH. Aborting."
    exit 1
}

# --- Ensure git user configuration is set ---
$userEmail = "nerdy@kyle.howard.com"
$userName = "Kyle Howard"

$currentEmail = git config --global user.email 2>$null
$currentName = git config --global user.name 2>$null

if ($currentEmail -ne $userEmail) {
    git config --global user.email $userEmail
    Write-Log "Set global git user.email to $userEmail"
}
if ($currentName -ne $userName) {
    git config --global user.name $userName
    Write-Log "Set global git user.name to $userName"
}

# --- Clone or use existing repo ---
if (-not (Test-Path ".git")) {
    Write-Log "No .git directory found. Cloning repository..."
    git clone $repoUrl . | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clone repository."
        Write-Log "Failed to clone repository."
        exit 1
    }
} else {
    Write-Log "Existing git repository found. Pulling latest changes..."
    git pull | Out-Null
}

# --- Ensure we are on the 'main' branch ---
$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
if ($currentBranch -ne "main") {
    Write-Log "Current branch is '$currentBranch'. Switching to 'main' branch."
    # Try to checkout main, or create it if it doesn't exist
    git checkout main 2>$null
    if ($LASTEXITCODE -ne 0) {
        git checkout -b main
        Write-Log "Created and switched to 'main' branch."
    } else {
        Write-Log "Switched to 'main' branch."
    }
}

# --- Ensure git upstream is correct ---
$remoteUrl = git remote get-url origin 2>$null
if ($remoteUrl -ne $repoUrl) {
    if ($remoteUrl) {
        git remote set-url origin $repoUrl
        Write-Log "Updated git remote 'origin' URL to $repoUrl"
    } else {
        git remote add origin $repoUrl
        Write-Log "Set git remote 'origin' URL to $repoUrl"
    }
} else {
    Write-Log "Git remote 'origin' URL is already correct."
}

# --- Add all scripts in current directory and log diffs for new files ---
$scriptFiles = Get-ChildItem -Path $cwd -Filter "*.ps1" -File
foreach ($file in $scriptFiles) {
    $status = git status --short $file.Name
    if ($status -match "^\?\?") {
        git add $file.Name
        Write-Log "Added NEW file $($file.Name) to git staging."
        # Log the full file content as the diff for a new file
        $fileContent = Get-Content $file.FullName | Out-String
        Write-Log "Diff for $($file.Name):`n$fileContent"
    } elseif ($status -match "^ M") {
        git add $file.Name
        Write-Log "Updated file $($file.Name) staged."
        # Log the diff for the modified file
        $diff = git diff --cached $file.Name
        Write-Log "Diff for $($file.Name):`n$diff"
    }
}

# --- Update README.md ---
$readmePath = Join-Path $cwd "README.md"
$readmeContent = @("# setup_scripts", "", "This repository contains PowerShell scripts for system setup and automation.", "")

foreach ($file in $scriptFiles) {
    $lines = Get-Content $file.FullName
    $desc = ""
    $reqs = ""
    $inBlock = $false
    foreach ($line in $lines) {
        if ($line -match "<#") { $inBlock = $true; continue }
        if ($line -match "#>") { $inBlock = $false; break }
        if ($inBlock) {
            if ($line -match "require" -or $line -match "Require") { $reqs += ($line.Trim() + " ") }
            else { $desc += ($line.Trim() + " ") }
        }
    }
    $descText = if ($desc) { $desc.Trim() } else { "No description found." }
    $reqsText = if ($reqs) { $reqs.Trim() } else { "None specified." }
    $readmeContent += @(
        "## $($file.Name)",
        "",
        "**Purpose & Function:**",
        $descText,
        "",
        "**Requirements:**",
        $reqsText,
        ""
    )
}

Set-Content -Path $readmePath -Value $readmeContent
git add README.md
Write-Log "Updated README.md with script documentation."

# --- Commit and push ---
$commitMsg = "Add/update scripts and README on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m "$commitMsg"
if ($LASTEXITCODE -eq 0) {
    Write-Log "Committed changes: $commitMsg"

    # Ensure the main branch is tracking the remote
    $tracking = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    if (-not $tracking) {
        Write-Log "No upstream set for 'main'. Setting upstream to origin/main."
        git push --set-upstream origin main
    } else {
        git push
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Scripts and README pushed to GitHub successfully."
        Write-Log "Scripts and README pushed to GitHub successfully."
        Write-Host "`nSummary:"
        Write-Host " - All .ps1 scripts in the current directory have been added to the repository."
        Write-Host " - README.md was updated to document each script's purpose and requirements."
        Write-Host " - Changes were committed and pushed to https://github.com/kylehoward/setup_scripts.git."
        Write-Host " - All actions and diffs were logged to $logPath."
        Write-Host "`nRecent git log:"
        git log --oneline -n 10
    } else {
        Write-Host "Failed to push to GitHub."
        Write-Log "Failed to push to GitHub."
    }
} else {
    Write-Host "No changes to commit."
    Write-Log "No changes to commit."
    Write-Host "`nSummary:"
    Write-Host " - No new or changed scripts to add."
    Write-Host " - README.md was checked and updated if needed."
    Write-Host " - All actions were logged to $logPath."
    Write-Host "`nRecent git log:"
    git log --oneline -n 10
}

<#
-------------------------------
Instructions for Use:
-------------------------------
- Place this script in the directory with your .ps1 scripts.
- Run as a user with git and GitHub push access.
- The script will add all .ps1 files, update the README.md, commit, and push.

-------------------------------
Theory of Operation:
-------------------------------
- The script ensures a git repo is present and up to date.
- It stages all PowerShell scripts, updates the README.md with descriptions and requirements
  (parsed from comment blocks), commits, and pushes to the remote repository.
- All actions and errors are logged to C:\loggy\githubby.log.
#>