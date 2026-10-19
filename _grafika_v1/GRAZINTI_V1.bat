@echo off
cd /d "%~dp0"
echo Grazinama 1-oji 3D grafikos versija (apvalios saleles)...
xcopy /Y /E /I "art" "..\art"
xcopy /Y /I "scripts\*.gd" "..\scripts"
echo.
echo Baigta. Atidaryk Godot - jis pats perimportuos paveiksliukus.
pause
