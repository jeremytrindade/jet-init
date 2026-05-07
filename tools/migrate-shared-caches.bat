@echo off
REM Run migrate-shared-caches.ps1 as Administrator with one double-click.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','%~dp0migrate-shared-caches.ps1'"
