@echo off
chcp 65001 >nul
PowerShell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0rotation_gui.ps1" %*
