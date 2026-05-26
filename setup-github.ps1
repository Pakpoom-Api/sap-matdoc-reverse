#Requires -Version 5.1
<#
.SYNOPSIS
    One-click GitHub setup for SAP Fiori — Reverse Material Document (ZMM_MATDOCREV_V1)

.DESCRIPTION
    This script will:
      1. Configure git user (name + email)
      2. Create a new GitHub repository via GitHub API  (requires PAT)
      3. Set up SSH remote  (requires SSH key added to GitHub)
      4. Initialize git, commit all files, and push to main branch

.NOTES
    Prerequisites:
      - git installed  (https://git-scm.com/download/win)
      - SSH key generated and added to GitHub account
        (https://github.com/settings/keys)
      - GitHub Personal Access Token (PAT) with repo scope
        (https://github.com/settings/tokens/new  — select: repo)

    Run this script from PowerShell:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\setup-github.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─────────────────────────────────────────────────────────────
# ANSI colors
# ─────────────────────────────────────────────────────────────
function Write-Green  { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Yellow { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Red    { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }
function Write-Step   { param($msg) Write-Host "`n── $msg ──" -ForegroundColor Cyan }

# ─────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────
Clear-Host
Write-Host @"

  ╔══════════════════════════════════════════════════════════╗
  ║   SAP Fiori — Reverse Material Document                  ║
  ║   ZMM_MATDOCREV_V1 · GitHub Setup Script                   ║
  ╚══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ─────────────────────────────────────────────────────────────
# PREREQUISITES CHECK
# ─────────────────────────────────────────────────────────────
Write-Step "Checking prerequisites"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Red "git is not installed. Download from: https://git-scm.com/download/win"
    exit 1
}
Write-Green "git found: $(git --version)"

# ─────────────────────────────────────────────────────────────
# USER INPUT
# ─────────────────────────────────────────────────────────────
Write-Step "Configuration"

$githubUser  = Read-Host "  GitHub username"
$repoName    = Read-Host "  Repository name (default: sap-matdoc-reverse)"
if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = "sap-matdoc-reverse" }

$repoDesc    = "SAP Fiori Elements app for Reverse Material Document (MBST/MIGO Cancel) using RAP + OData V4"
$repoPrivate = Read-Host "  Make repository private? (y/N)"
$isPrivate   = ($repoPrivate.ToLower() -eq 'y')

Write-Host ""
Write-Host "  Repository will be created at:" -ForegroundColor White
Write-Host "  https://github.com/$githubUser/$repoName" -ForegroundColor Yellow
Write-Host "  Visibility: $(if ($isPrivate) { 'Private' } else { 'Public' })" -ForegroundColor Yellow

# PAT — needed ONLY for GitHub API (repo creation)
Write-Host ""
Write-Host "  Enter your GitHub Personal Access Token (PAT)" -ForegroundColor White
Write-Host "  Needed to create the repo via API. Not stored anywhere." -ForegroundColor DarkGray
Write-Host "  Create at: https://github.com/settings/tokens/new (scope: repo)" -ForegroundColor DarkGray
$patSecure = Read-Host "  PAT" -AsSecureString
$pat = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
         [Runtime.InteropServices.Marshal]::SecureStringToBSTR($patSecure))

# ─────────────────────────────────────────────────────────────
# STEP 1 — CREATE GITHUB REPO VIA API
# ─────────────────────────────────────────────────────────────
Write-Step "Creating GitHub repository"

$body = @{
    name        = $repoName
    description = $repoDesc
    private     = $isPrivate
    auto_init   = $false
} | ConvertTo-Json

$headers = @{
    Authorization = "token $pat"
    Accept        = "application/vnd.github.v3+json"
    "User-Agent"  = "ZMM-Setup-Script/1.0"
}

try {
    $response = Invoke-RestMethod `
        -Uri     "https://api.github.com/user/repos" `
        -Method  Post `
        -Headers $headers `
        -Body    $body `
        -ContentType "application/json"

    Write-Green "Repository created: $($response.html_url)"
    $sshUrl = $response.ssh_url   # git@github.com:user/repo.git
}
catch {
    $errMsg = $_.Exception.Message
    if ($errMsg -like "*422*") {
        Write-Yellow "Repository may already exist — attempting to use existing repo."
        $sshUrl = "git@github.com:$githubUser/$repoName.git"
    } else {
        Write-Red "Failed to create repository: $errMsg"
        Write-Host "  Create it manually at https://github.com/new then re-run this script." -ForegroundColor DarkGray
        exit 1
    }
}

# Clear PAT from memory
$pat = $null
[System.GC]::Collect()

# ─────────────────────────────────────────────────────────────
# STEP 2 — GIT INIT + CONFIG
# ─────────────────────────────────────────────────────────────
Write-Step "Initialising git repository"

$repoRoot = $PSScriptRoot   # Folder where this script lives (D:\AI\Reverse1)
Set-Location $repoRoot

if (Test-Path ".git") {
    Write-Yellow ".git already exists — skipping git init"
} else {
    git init -b main
    Write-Green "git init done (branch: main)"
}

# Configure git identity (local to this repo only)
$gitName  = Read-Host "  Your name for git commits (e.g. Ta)"
$gitEmail = Read-Host "  Your email for git commits (e.g. naypac00@gmail.com)"

git config user.name  "$gitName"
git config user.email "$gitEmail"
Write-Green ("git identity set: {0} <{1}>" -f $gitName, $gitEmail)

# ─────────────────────────────────────────────────────────────
# STEP 3 — SSH TEST
# ─────────────────────────────────────────────────────────────
Write-Step "Testing SSH connection to GitHub"

$sshTest = & ssh -T git@github.com 2>&1
if ($sshTest -like "*successfully authenticated*") {
    Write-Green "SSH authentication OK"
} else {
    Write-Yellow "SSH test returned: $sshTest"
    Write-Host  "  If push fails, add your SSH key at: https://github.com/settings/keys" -ForegroundColor DarkGray
}

# ─────────────────────────────────────────────────────────────
# STEP 4 — ADD REMOTE
# ─────────────────────────────────────────────────────────────
Write-Step "Setting up remote origin (SSH)"

$existingRemote = git remote 2>&1
if ($existingRemote -contains "origin") {
    git remote set-url origin $sshUrl
    Write-Yellow "Remote 'origin' updated to: $sshUrl"
} else {
    git remote add origin $sshUrl
    Write-Green "Remote 'origin' added: $sshUrl"
}

# ─────────────────────────────────────────────────────────────
# STEP 5 — STAGE + COMMIT + PUSH
# ─────────────────────────────────────────────────────────────
Write-Step "Staging all files"

git add --all
$status = git status --short
Write-Host "  Files staged:" -ForegroundColor White
$status | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

Write-Step "Creating initial commit"
$commitMsg = @"
feat: initial commit - ZMM_MATDOCREV_V1 Reverse Material Document RAP app

- ZI_MM_MATDOCREV + ZI_MM_MATDOCREV_ITEM
- ZC_MM_MATDOCREV + ZC_MM_MATDOCREV_ITEM
- Metadata Extensions
- Behavior Definitions
- Behavior Implementation Class
- Service Definition
- Service Binding

Source: I_MaterialDocumentTP + I_MaterialDocumentItem_2
Action: MODIFY ENTITIES OF i_materialdocumenttp EXECUTE Cancel
"@

git commit -m $commitMsg
Write-Green "Commit created"

Write-Step "Pushing to GitHub (SSH)"
git push -u origin main

# ─────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────
Write-Host @"

  ╔══════════════════════════════════════════════════════════╗
  ║   ✅  All done!                                          ║
  ╠══════════════════════════════════════════════════════════╣
  ║                                                          ║
  ║   Repository : https://github.com/$githubUser/$repoName
  ║   Branch     : main                                      ║
  ║   Files      : 13 SAP artifacts + README + .gitignore   ║
  ║                                                          ║
  ╚══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "  Next steps in SAP ADT:" -ForegroundColor White
Write-Host "  1. Create package ZMM_MATDOCREV_V1" -ForegroundColor DarkGray
Write-Host "  2. Copy each artifact from /app/*.txt into ADT objects" -ForegroundColor DarkGray
Write-Host "  3. Activate in the order shown in README.md" -ForegroundColor DarkGray
Write-Host "  4. Publish ZSB_MM_MATDOCREV_UI service binding" -ForegroundColor DarkGray
Write-Host "  5. Deploy ZMMF001 via Fiori Generator or BAS" -ForegroundColor DarkGray
Write-Host ""
