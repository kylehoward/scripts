# Requires: PowerShell 7+, git CLI
#
# This script automatically generates a README.md file documenting all PowerShell scripts (.ps1)
# tracked by git in the repository. For each script, it attempts to extract the first documentation
# block (between <# and #>) and includes it in the README. If no documentation block is found,
# "No Info" is listed for that script.
#
# The script then commits and pushes the updated README.md to the remote repository.
# 
# How it works:
# 1. Pulls the latest changes from the remote repository.
# 2. Uses 'git ls-files' to find all tracked .ps1 files.
# 3. For each file, reads its content and extracts the first documentation block if present.
# 4. Builds a Markdown README listing each script and its documentation.
# 5. Overwrites README.md with the new content.
# 6. Commits and pushes the README.md to the remote repository.

# Update local repository
git pull

# Get all .ps1 files tracked by git in the repo
$ps1Files = git ls-files "*.ps1" | ForEach-Object { Get-Item $_ }

# Prepare documentation lines
$docLines = @()
foreach ($file in $ps1Files) {
    # Read the file content
    $lines = Get-Content $file.FullName

    # Try to extract the first documentation block (<# ... #>)
    $docBlock = @()
    $inDocBlock = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*<#$') {
            $inDocBlock = $true
            continue
        }
        if ($inDocBlock) {
            if ($line -match '^\s*#>$') {
                break
            }
            $docBlock += $line.Trim()
        }
    }

    if ($docBlock.Count -gt 0) {
        $doc = $docBlock -join ' '
    } else {
        $doc = "No Info"
    }
    $docLines += "* **$($file.Name)**: $doc"
}

# Add timestamp and message to the top of the README
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$lastChangeMsg = "README last updated on $timestamp by autoREADME.ps1 script.`n"
$shortMsg = "This file lists all PowerShell scripts and their documentation blocks as of the last commit.`n"

# Always overwrite README.md with new documentation
$readmePath = "README.md"
$header = "# PowerShell Scripts Documentation`n"
$intro = $lastChangeMsg + $shortMsg + "`nEach script and its documentation block are listed below:`n"
$content = $header + $intro + ($docLines -join "`n") + "`n"

Set-Content $readmePath $content

# Commit and push changes
git add $readmePath
git commit -m "Regenerate README with PS1 file documentation blocks"
git push