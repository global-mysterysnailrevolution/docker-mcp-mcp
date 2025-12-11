@echo off
title Docker MCP Gateway - One-Click Setup
color 0B

echo.
echo  ____             _               __  __  ____ ____  
echo ^|  _ \  ___   ___^| ^| _____ _ __  ^|  \/  ^|/ ___^|  _ \ 
echo ^| ^| ^| ^|/ _ \ / __^| ^|/ / _ \ '__^| ^| ^|\/^| ^| ^|   ^| ^|_^) ^|
echo ^| ^|_^| ^| (_) ^| (__^|   ^<  __/ ^|    ^| ^|  ^| ^| ^|___^|  __/ 
echo ^|____/ \___/ \___^|_^|\_\___^|_^|    ^|_^|  ^|_^|\____^|_^|    
echo.
echo        Gateway Setup - One MCP to Rule Them All
echo.
echo  This will set up Docker MCP Gateway for:
echo    - Claude Code
echo    - Cursor
echo    - Claude Desktop
echo.

:: Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Requesting administrator privileges...
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0one-click-setup.ps1"

if %errorLevel% neq 0 (
    echo.
    echo [!] Setup encountered an issue. Check the output above.
    echo.
    pause
)

