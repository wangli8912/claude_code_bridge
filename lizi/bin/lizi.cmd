@echo off
setlocal
rem Lizi Windows outer entrypoint.
rem First version keeps the logic intentionally small:
rem 1. Stay in the lizi shell layer.
rem 2. Forward all arguments to lizi.ps1.
rem 3. Do not call or modify upstream core files here.

set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%lizi.ps1" %*
endlocal
