Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host " GitHub Setup Script" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

$githubUser = Read-Host "GitHub Username"
$repoName   = Read-Host "Repository Name"

if ([string]::IsNullOrWhiteSpace($repoName)) {
    $repoName = "sap-matdoc-reverse"
}

Set-Location $PSScriptRoot

if (!(Test-Path ".git")) {
    git init -b main
    Write-Host "git init completed" -ForegroundColor Green
}
else {
    Write-Host ".git already exists" -ForegroundColor Yellow
}

$gitName  = Read-Host "Git Name"
$gitEmail = Read-Host "Git Email"

git config user.name $gitName
git config user.email $gitEmail

Write-Host "git identity configured" -ForegroundColor Green

git add .

$commitMsg = @"
feat: initial commit - ZMM_MATDOCREV
"@

git commit -m $commitMsg

try {
    git remote remove origin 2>$null
}
catch {
}

git remote add origin "git@github.com:$githubUser/$repoName.git"

Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Cyan

git push -u origin main

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "Repository: https://github.com/$githubUser/$repoName"
