@echo off
powershell.exe -NoProfile -File "%~dp0Open-Vivado.ps1"
if errorlevel 1 pause
