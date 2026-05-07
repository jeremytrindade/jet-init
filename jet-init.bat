@echo off
REM jet-init entry point. Runs the PowerShell orchestrator with execution policy bypass.
REM Usage:
REM   jet-init.bat                       Interactive install (default)
REM   jet-init.bat install               Same as above
REM   jet-init.bat fix                   Audit + offer to consolidate cross-account waste
REM   jet-init.bat doctor                Read-only health check
REM   jet-init.bat update                Upgrade installed tools
REM   jet-init.bat help                  Show full help
REM
REM PC type:
REM   jet-init.bat install -FullDev      Cross-account install (Machine scope)
REM   jet-init.bat install -Shared       Per-account install only
REM
REM Non-interactive:
REM   jet-init.bat install -FullDev -Yes  Accept all defaults

cd /d "%~dp0"
echo.
echo ============================================
echo  jet-init, fresh-PC bootstrap
echo ============================================
echo.

REM Prefer PowerShell 7 (pwsh) if available, fall back to Windows PowerShell 5.1
where pwsh >nul 2>&1
if not errorlevel 1 (
  echo Using PowerShell 7
  pwsh -ExecutionPolicy Bypass -NoProfile -File "%~dp0jet-init.ps1" %*
  goto :done
)

where powershell >nul 2>&1
if errorlevel 1 (
  echo ERROR: PowerShell not found. This script requires Windows PowerShell 5.1+.
  pause
  exit /b 1
)

echo Using Windows PowerShell 5.1
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0jet-init.ps1" %*

:done
echo.
echo Done. Check the log file for details.
pause
