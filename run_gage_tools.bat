@echo off
title GAGE Control Center & DevTools
cd /d "%~dp0\gage-tools"
start "" http://localhost:4055
python server.py
pause
