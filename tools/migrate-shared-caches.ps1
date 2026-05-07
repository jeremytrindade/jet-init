<#
.SYNOPSIS
  Move every account's npm globals, uv cache, and pip wheel cache into
  shared locations and set the machine-wide env vars + PATH so all
  current and future accounts on this PC share the same caches.

.DESCRIPTION
  Sister tool to migrate-ollama-shared.ps1. Run as Administrator. For
  each of the three tools (npm / uv / pip):

    1. Discover per-user cache directories under C:\Users\*.
    2. Pick a shared target on the largest non-system disk
       (D:\shared\npm-global, D:\shared\uv-cache, D:\shared\pip-cache
       by default).
    3. Set the corresponding Machine-scope env var so every account
       points at the shared location:
         NPM_CONFIG_PREFIX, UV_CACHE_DIR, PIP_CACHE_DIR
    4. Append the npm prefix to Machine PATH so installed CLIs
       (claude code, codex, ...) are runnable from any account.
    5. Set Modify ACL for BUILTIN\Users on each shared dir.
    6. robocopy each per-user source into the shared target with
       /E /XC /XN /XO so existing files in the target are preserved
       (no destructive overwrites). Sources are kept until the user
       removes them, robocopy /MOVE is intentionally NOT used because
       version conflicts between accounts would fragment the move.

  Idempotent. Safe to re-run.

.PARAMETER NpmPrefix
.PARAMETER UvCache
.PARAMETER PipCache
  Override the shared target paths.

.PARAMETER WhatIf
  Show what would happen without changing anything.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [string] $NpmPrefix,
  [string] $UvCache,
  [string] $PipCache
)

function Test-Admin {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object System.Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-LargestNonSystemDisk {
  $d = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
       Where-Object { $_.Size -gt 0 -and $_.DeviceID -ne "C:" } |
       Sort-Object FreeSpace -Descending | Select-Object -First 1
  if (-not $d) {
    $d = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
         Where-Object { $_.Size -gt 0 } |
         Sort-Object FreeSpace -Descending | Select-Object -First 1
  }
  return $d.DeviceID
}

function Get-DirSizeGB {
  param([string] $Path)
  if (-not (Test-Path $Path)) { return 0 }
  try {
    $b = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    return [math]::Round($b / 1GB, 2)
  } catch { return 0 }
}

function Get-PerUserDirs {
  param([Parameter(Mandatory)] [string] $RelativePath)
  $found = @()
  Get-ChildItem "C:\Users" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $candidate = Join-Path $_.FullName $RelativePath
    if (Test-Path $candidate) {
      $size = Get-DirSizeGB $candidate
      $found += [pscustomobject]@{
        Owner  = $_.Name
        Path   = $candidate
        SizeGB = $size
      }
    }
  }
  return $found
}

function Set-SharedFolderAcl {
  param([Parameter(Mandatory)] [string] $Path)
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
  try {
    $acl  = Get-Acl $Path
    $sid  = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-32-545"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      $sid, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl -Path $Path -AclObject $acl
    Write-Host "    [OK] $Path grants Modify to BUILTIN\Users"
  } catch {
    Write-Host "    [warn] Could not set ACL on ${Path}: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

function Add-ToMachinePath {
  param([Parameter(Mandatory)] [string] $Path)
  $current = [System.Environment]::GetEnvironmentVariable("Path","Machine")
  if ($current -split ";" -contains $Path) {
    Write-Host "    [OK] PATH already contains $Path"
    return
  }
  $new = "$current;$Path"
  [System.Environment]::SetEnvironmentVariable("Path", $new, "Machine")
  Write-Host "    [OK] Appended $Path to Machine PATH"
}

function Migrate-CacheTool {
  param(
    [Parameter(Mandatory)] [string] $Label,
    [Parameter(Mandatory)] [string] $RelativePath,
    [Parameter(Mandatory)] [string] $Target,
    [Parameter(Mandatory)] [string] $EnvVar,
    [switch] $AddToPath
  )
  Write-Host ""
  Write-Host "  [$Label]" -ForegroundColor White

  $sources = @(Get-PerUserDirs -RelativePath $RelativePath)
  if ($sources.Count -eq 0) {
    Write-Host "    No per-user $Label directories found, nothing to consolidate."
  } else {
    foreach ($s in $sources) {
      Write-Host ("    {0,-15}  {1,6:N2} GB  {2}" -f $s.Owner, $s.SizeGB, $s.Path)
    }
  }

  if (-not (Test-Path $Target)) {
    if ($PSCmdlet.ShouldProcess($Target, "Create directory")) {
      New-Item -ItemType Directory -Path $Target -Force | Out-Null
      Write-Host "    [OK] Created $Target"
    }
  }

  if ($PSCmdlet.ShouldProcess($Target, "Grant BUILTIN\Users Modify")) {
    Set-SharedFolderAcl -Path $Target
  }

  if ($PSCmdlet.ShouldProcess("$EnvVar (Machine)", "Set to $Target")) {
    [System.Environment]::SetEnvironmentVariable($EnvVar, $Target, "Machine")
    Set-Item -Path "Env:$EnvVar" -Value $Target
    Write-Host "    [OK] $EnvVar = $Target  (Machine scope)"
  }

  if ($AddToPath -and $PSCmdlet.ShouldProcess("Machine PATH", "Append $Target")) {
    Add-ToMachinePath -Path $Target
  }

  foreach ($s in $sources) {
    if ($s.Path.ToLowerInvariant() -eq $Target.ToLowerInvariant()) {
      Write-Host ("    [skip] {0} is already the target" -f $s.Path)
      continue
    }
    if ($s.SizeGB -lt 0.01) {
      Write-Host ("    [skip] {0} is empty" -f $s.Path)
      continue
    }
    if ($PSCmdlet.ShouldProcess($s.Path, "robocopy merge into $Target")) {
      Write-Host ("    Merging {0}'s {1} into {2}..." -f $s.Owner, $Label, $Target) -ForegroundColor Cyan
      # /E /XC /XN /XO = recurse, skip files that exist (any version comparison) so we never overwrite.
      & robocopy $s.Path $Target /E /XC /XN /XO /NFL /NDL /NJH /NJS /NC /NS /NP /R:2 /W:2 | Out-Null
      Write-Host ("    [OK] {0}'s {1} merged" -f $s.Owner, $Label) -ForegroundColor Green
    }
  }
}

# --- preflight ---

if (-not (Test-Admin)) {
  Write-Host ""
  Write-Host "  ERROR: This script must run as Administrator." -ForegroundColor Red
  Write-Host "  Right-click migrate-shared-caches.bat -> Run as administrator." -ForegroundColor Yellow
  Write-Host ""
  Read-Host "  Press Enter to close"
  exit 1
}

Write-Host ""
Write-Host "  +-------------------------------------------------------+"
Write-Host "  |  migrate-shared-caches (Machine-scope, cross-account) |"
Write-Host "  +-------------------------------------------------------+"
Write-Host ""

$drive = (Get-LargestNonSystemDisk)
if (-not $NpmPrefix) { $NpmPrefix = "$drive\shared\npm-global" }
if (-not $UvCache)   { $UvCache   = "$drive\shared\uv-cache"   }
if (-not $PipCache)  { $PipCache  = "$drive\shared\pip-cache"  }

Write-Host "  Targets:"
Write-Host "    npm prefix : $NpmPrefix"
Write-Host "    uv cache   : $UvCache"
Write-Host "    pip cache  : $PipCache"
Write-Host ""

Write-Host "  Close any open terminals using npm globals before continuing." -ForegroundColor Yellow
Write-Host "  (otherwise files may be locked and the merge will skip them)" -ForegroundColor DarkGray
$reply = Read-Host "  Proceed? [Y/n]"
if ($reply -eq "n" -or $reply -eq "N") {
  Write-Host "  Aborted by user." -ForegroundColor Yellow
  exit 0
}

Migrate-CacheTool -Label "npm globals" `
                  -RelativePath "AppData\Roaming\npm" `
                  -Target $NpmPrefix `
                  -EnvVar "NPM_CONFIG_PREFIX" `
                  -AddToPath

Migrate-CacheTool -Label "uv cache" `
                  -RelativePath "AppData\Local\uv\cache" `
                  -Target $UvCache `
                  -EnvVar "UV_CACHE_DIR"

Migrate-CacheTool -Label "pip cache" `
                  -RelativePath "AppData\Local\pip\Cache" `
                  -Target $PipCache `
                  -EnvVar "PIP_CACHE_DIR"

Write-Host ""
Write-Host "  Done. New shells (and other accounts after they re-login) will pick up:" -ForegroundColor Green
Write-Host "    NPM_CONFIG_PREFIX = $NpmPrefix  (also in PATH)"
Write-Host "    UV_CACHE_DIR      = $UvCache"
Write-Host "    PIP_CACHE_DIR     = $PipCache"
Write-Host ""
Write-Host "  Per-user source directories were merged with /XC /XN /XO so nothing was" -ForegroundColor DarkGray
Write-Host "  overwritten. Conflicts (same package in multiple accounts) leave the file" -ForegroundColor DarkGray
Write-Host "  in source. Once you've verified things work, you can delete the per-user" -ForegroundColor DarkGray
Write-Host "  cache directories manually to recover the rest of the disk space." -ForegroundColor DarkGray
Write-Host ""
Read-Host "  Press Enter to close"
