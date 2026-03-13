param(
  [string]$Message = "Update site"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $scriptRoot "prepare-images.ps1")

git add .gitignore deploy.ps1 prepare-images.ps1 index.html styles.css script.js image/web

$hasChanges = git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
  Write-Output "No staged changes to deploy."
  exit 0
}

git commit -m $Message
git push origin main

Write-Output "Deployment pushed to GitHub Pages."
