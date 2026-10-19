@echo off
cd /d "%~dp0"
echo Grazinama sena grafika ir skriptai...
xcopy /Y /E /I "art" "..\art"
xcopy /Y /I "scripts\*.gd" "..\scripts"
echo.
echo Baigta. Atidaryk Godot - jis pats perimportuos paveiksliukus.
pause
