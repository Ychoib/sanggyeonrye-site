param(
  [string]$Message = "Update site"
)

$ErrorActionPreference = "Stop"

git add .gitignore index.html styles.css script.js

$hasChanges = git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
  Write-Output "No staged changes to deploy."
  exit 0
}

git commit -m $Message
git push origin main

Write-Output "Deployment pushed to GitHub Pages."
