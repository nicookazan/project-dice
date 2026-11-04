@echo off
rem Modo de desarrollo: fuerza uno o varios jefes por id al entrar a su nivel.
rem Uso: Jugar-jefe.cmd l3_conde,l5_visitante   (ids en scripts/boss_catalog.gd)
setlocal
cd /d "%~dp0"
if "%~1"=="" (
  echo Uso: Jugar-jefe.cmd id[,id...]   por ejemplo: Jugar-jefe.cmd l2_cebador
  pause
  exit /b 1
)
for %%G in ("%USERPROFILE%\Desktop\Godot*_win64.exe") do (
  start "" "%%~fG" --path "%~dp0." -- --boss=%~1
  exit /b
)
echo No se encontro Godot en el escritorio. Abri project.godot desde Godot.
pause
