@echo off
REM Run migrate-ollama-shared.ps1 as Administrator with one double-click.
REM The .ps1 will trigger UAC if not already elevated.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','%~dp0migrate-ollama-shared.ps1'"
