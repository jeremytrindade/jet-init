@echo off
REM startupjet entry point. Runs the PowerShell orchestrator with execution policy bypass.
REM Usage:
REM   startupjet.bat              Normal install
REM   startupjet.bat -Update      Upgrade installed tools
REM   startupjet.bat -DryRun      Show what would happen without doing anything

cd /d "%~dp0"
echo.
echo ============================================
echo  startupjet, fresh-PC bootstrap
echo ============================================
echo.

REM Prefer PowerShell 7 (pwsh) if available, fall back to Windows PowerShell 5.1
where pwsh >nul 2>&1
if not errorlevel 1 (
  echo Using PowerShell 7
  pwsh -ExecutionPolicy Bypass -NoProfile -File "%~dp0startupjet.ps1" %*
  goto :done
)

where powershell >nul 2>&1
if errorlevel 1 (
  echo ERROR: PowerShell not found. This script requires Windows PowerShell 5.1+.
  pause
  exit /b 1
)

echo Using Windows PowerShell 5.1
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0startupjet.ps1" %*

:done
echo.
echo Done. Check the log file for details.
pause
