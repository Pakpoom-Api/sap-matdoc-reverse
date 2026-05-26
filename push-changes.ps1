#Requires -Version 5.1
<#
.SYNOPSIS
    Push latest changes to GitHub (use this after setup-github.ps1 was already run)

.DESCRIPTION
    Stages all changes, commits, and force-pushes to origin/main.
    Use this script when the repo already exists on GitHub
    and you want to sync local changes.

.NOTES
    Run from PowerShell:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\push-changes.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Green  { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Yellow { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Red    { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }
function Write-Step   { param($msg) Write-Host "`n── $msg ──" -ForegroundColor Cyan }

Clear-Host
Write-Host @"

  ╔══════════════════════════════════════════════════════════╗
  ║   ZMM_MATDOCREV_V1 — Push Changes to GitHub              ║
  ╚══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ── Navigate to repo root ──────────────────────────────────
$repoRoot = $PSScriptRoot
Set-Location $repoRoot

# ── Check git repo ─────────────────────────────────────────
Write-Step "Checking git status"

if (-not (Test-Path ".git")) {
    Write-Red "No .git folder found. Please run setup-github.ps1 first."
    exit 1
}

$remote = git remote get-url origin 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Red "No remote 'origin' configured. Please run setup-github.ps1 first."
    exit 1
}
Write-Green "Remote origin: $remote"

# ── Show what changed ──────────────────────────────────────
Write-Step "Files changed"

git status --short
$changed = git status --short | Measure-Object -Line
Write-Host ""
Write-Host "  $($changed.Lines) file(s) changed" -ForegroundColor White

if ($changed.Lines -eq 0) {
    Write-Yellow "Nothing to commit — working tree is clean."
    Write-Host "  Your GitHub repo is already up to date." -ForegroundColor DarkGray
    exit 0
}

# ── Stage all ─────────────────────────────────────────────
Write-Step "Staging all changes"
git add --all
Write-Green "All changes staged"

# ── Commit ────────────────────────────────────────────────
Write-Step "Creating commit"

$commitMsg = @"
chore: rename file extensions + update package to ZMM_MATDOCREV_V1

- .txt → .ddls  (CDS Interface/Projection Views)
- .txt → .ddlx  (CDS Metadata Extensions)
- .txt → .bdef  (Behavior Definitions)
- .txt → .abap  (ABAP Classes — Behavior Pool + Logic Class)
- .txt → .srvd  (Service Definition)
- .txt → .md    (Service Binding notes)
- .txt → .json  (Fiori App Manifest)
- Package renamed: ZMM_MATDOCREV → ZMM_MATDOCREV_V1
"@

git commit -m $commitMsg
Write-Green "Commit created"

# ── Push ──────────────────────────────────────────────────
Write-Step "Pushing to GitHub"

# Try normal push first
$pushResult = git push origin main 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Green "Push successful!"
} else {
    Write-Yellow "Normal push failed — trying force push..."
    Write-Host "  Reason: $pushResult" -ForegroundColor DarkGray

    $confirm = Read-Host "  Force push will overwrite remote history. Continue? (y/N)"
    if ($confirm.ToLower() -eq 'y') {
        git push --force origin main
        if ($LASTEXITCODE -eq 0) {
            Write-Green "Force push successful!"
        } else {
            Write-Red "Push failed. Check your SSH key and remote URL."
            exit 1
        }
    } else {
        Write-Yellow "Push cancelled."
        exit 0
    }
}

# ── Done ──────────────────────────────────────────────────
Write-Host @"

  ╔══════════════════════════════════════════════════════════╗
  ║   ✅  GitHub updated successfully!                       ║
  ╚══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "  Remote: $remote" -ForegroundColor White
Write-Host "  Branch: main" -ForegroundColor White
Write-Host ""
Write-Host "  Open your repository on GitHub to verify." -ForegroundColor DarkGray
