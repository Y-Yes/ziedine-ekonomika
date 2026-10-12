@echo off
title Ziedine ekonomika
cd /d "%~dp0"
echo Paleidziamas zaidimas "Ziedine ekonomika"...
echo Narsykle atsidarys automatiskai. Kol zaidi, NEUZDARYK sio lango.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serveris.ps1"
pause
