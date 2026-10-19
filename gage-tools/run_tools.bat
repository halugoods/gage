@echo off
title GAGE Control Center & DevTools
cd /d "%~dp0"
echo ========================================================
echo   Launching GAGE Local Control Tools (Zero-Terminal Pos)
echo   URL: http://localhost:4055
echo ========================================================
start "" http://localhost:4055
python server.py
pause
