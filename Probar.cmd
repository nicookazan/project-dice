@echo off
setlocal
cd /d "%~dp0"
for %%G in ("%USERPROFILE%\Desktop\Godot*_console.exe") do (
  "%%~fG" --headless --path "%~dp0." --script res://tests/run_tests.gd
  goto :finished
)
echo No se encontro la version de consola de Godot en el escritorio.
pause
exit /b 1

:finished
set "test_result=%errorlevel%"
pause
exit /b %test_result%
