@echo off
setlocal
cd /d "%~dp0"
for %%G in ("%USERPROFILE%\Desktop\Godot*_win64.exe") do (
  start "" "%%~fG" --path "%~dp0." -- --validation-profile
  exit /b
)
echo No se encontro Godot en el escritorio. Abri project.godot desde Godot.
pause
