<#
.SYNOPSIS
  Move every account's Ollama models into one shared location and set
  OLLAMA_MODELS Machine-wide so all current and future accounts share it.

.DESCRIPTION
  Run this script as Administrator. It will:
    1. Stop the Ollama daemon (if running).
    2. Discover every C:\Users\*\.ollama\models directory.
    3. robocopy /MOVE each one into the chosen shared location (default
       D:\ollama\models, configurable with -Target).
    4. Grant BUILTIN\Users Modify on the shared folder so every account
       on this PC can read and write.
    5. Set OLLAMA_MODELS at Machine scope so every account points there.
    6. Restart the Ollama daemon.

  Idempotent: safe to run multiple times. If the env var is already
  pointing at the right place and there are no other-account dirs to
  consolidate, the script reports the state and exits.

  Run with:
    Right-click -> Run with PowerShell  (and approve UAC)
    OR
    Start-Process pwsh -Verb RunAs -ArgumentList "-File D:\aijetlabs\github\startupjet\tools\migrate-ollama-shared.ps1"

.PARAMETER Target
  Destination directory. Default: D:\ollama\models. Auto-falls-back to
  the largest non-system disk if D: is missing.

.PARAMETER WhatIf
  Show what would happen without moving anything.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [string] $Target
)

function Test-Admin {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object System.Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FixedDisks {
  Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Where-Object { $_.Size -gt 0 } |
    Sort-Object FreeSpace -Descending
}

function Get-AllUserModelDirs {
  $dirs = @()
  Get-ChildItem "C:\Users" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $candidate = Join-Path $_.FullName ".ollama\models"
    if (Test-Path $candidate) {
      $size = 0
      try { $size = (Get-ChildItem $candidate -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {}
      $dirs += [pscustomobject]@{
        Owner  = $_.Name
        Path   = $candidate
        SizeGB = [math]::Round($size / 1GB, 2)
      }
    }
  }
  return $dirs
}

# --- preflight ---

if (-not (Test-Admin)) {
  Write-Host ""
  Write-Host "  ERROR: This script must run as Administrator." -ForegroundColor Red
  Write-Host "  Right-click the .ps1 -> Run with PowerShell, then approve UAC." -ForegroundColor Yellow
  Write-Host "  Or:" -ForegroundColor Yellow
  Write-Host "    Start-Process pwsh -Verb RunAs -ArgumentList '-File `"$PSCommandPath`"'" -ForegroundColor DarkGray
  Write-Host ""
  Read-Host "  Press Enter to close"
  exit 1
}

Write-Host ""
Write-Host "  +-------------------------------------------------------+"
Write-Host "  |  migrate-ollama-shared (Machine-scope, cross-account) |"
Write-Host "  +-------------------------------------------------------+"
Write-Host ""

# --- choose target ---

if (-not $Target) {
  $disks = @(Get-FixedDisks | Where-Object { $_.DeviceID -ne "C:" -and $_.FreeSpace -gt 20GB })
  if ($disks.Count -gt 0) {
    $Target = "$($disks[0].DeviceID)\ollama\models"
  } else {
    $Target = "D:\ollama\models"
  }
}

Write-Host "  Target:  $Target"
Write-Host ""

# --- discover sources ---

$sources = @(Get-AllUserModelDirs)
if ($sources.Count -eq 0) {
  Write-Host "  No per-user .ollama\models directories found." -ForegroundColor Yellow
} else {
  Write-Host "  Per-user model directories detected:" -ForegroundColor Cyan
  foreach ($s in $sources) {
    Write-Host ("    {0,-15}  {1,6:N1} GB  {2}" -f $s.Owner, $s.SizeGB, $s.Path)
  }
}

$totalGB = ($sources | Measure-Object -Property SizeGB -Sum).Sum
if (-not $totalGB) { $totalGB = 0 }
Write-Host ""
Write-Host ("  Total to consolidate: {0:N2} GB" -f $totalGB)
Write-Host ""

# --- confirm ---

$reply = Read-Host "  Proceed? [Y/n]"
if ($reply -eq "n" -or $reply -eq "N") {
  Write-Host "  Aborted by user." -ForegroundColor Yellow
  exit 0
}

# --- stop ollama ---

Write-Host ""
Write-Host "  Stopping Ollama daemon..." -ForegroundColor DarkGray
Get-Process -Name "ollama" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# --- ensure target exists with shared ACL ---

if (-not (Test-Path $Target)) {
  if ($PSCmdlet.ShouldProcess($Target, "Create directory")) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    Write-Host "  [OK] Created $Target"
  }
}

try {
  $acl  = Get-Acl $Target
  $sid  = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-32-545"  # BUILTIN\Users
  $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $sid, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
  )
  $acl.SetAccessRule($rule)
  if ($PSCmdlet.ShouldProcess($Target, "Grant BUILTIN\Users Modify")) {
    Set-Acl -Path $Target -AclObject $acl
    Write-Host "  [OK] $Target grants Modify to BUILTIN\Users"
  }
} catch {
  Write-Host "  [warn] Could not set ACL on ${Target}: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- robocopy each source ---

foreach ($s in $sources) {
  if ($s.Path.ToLowerInvariant() -eq $Target.ToLowerInvariant()) {
    Write-Host ("  [skip] {0} is already the target" -f $s.Path) -ForegroundColor DarkGray
    continue
  }
  if ($s.SizeGB -lt 0.01) {
    Write-Host ("  [skip] {0} is empty" -f $s.Path) -ForegroundColor DarkGray
    continue
  }
  Write-Host ""
  Write-Host ("  Migrating {0}'s models from {1} ..." -f $s.Owner, $s.Path) -ForegroundColor Cyan
  if ($PSCmdlet.ShouldProcess($s.Path, "robocopy /MOVE to $Target")) {
    & robocopy $s.Path $Target /E /MOVE /NFL /NDL /NJH /NJS /NC /NS /NP /R:2 /W:2 | Out-Null
    Write-Host ("  [OK] {0}'s models moved" -f $s.Owner) -ForegroundColor Green
  }
}

# --- set OLLAMA_MODELS Machine-wide ---

if ($PSCmdlet.ShouldProcess("OLLAMA_MODELS (Machine)", "Set to $Target")) {
  [System.Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $Target, "Machine")
  $env:OLLAMA_MODELS = $Target
  Write-Host ""
  Write-Host "  [OK] OLLAMA_MODELS = $Target  (Machine scope)" -ForegroundColor Green
}

# --- restart ollama ---

Write-Host "  Starting Ollama daemon..." -ForegroundColor DarkGray
if (Get-Command "ollama" -ErrorAction SilentlyContinue) {
  Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 3
  Write-Host "  Models visible to ollama:"
  $list = ollama list 2>&1
  Write-Host $list
} else {
  Write-Host "  [warn] 'ollama' not on PATH; start the daemon manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Done. New shells (and other accounts after they re-login) will see OLLAMA_MODELS = $Target" -ForegroundColor Green
Write-Host ""
Read-Host "  Press Enter to close"
