@echo off
:: TextureResizer Launcher
:: Double-click this file OR drag images onto it to resize textures.

:: Allow drag-and-drop: pass all args to the PowerShell script
set SCRIPT=%~dp0TextureResizer.ps1

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%" %*

