@echo off
setlocal
pushd "%~dp0"
where py.exe >nul 2>nul
if not errorlevel 1 (
    py -3 "%~dp0serve_preview.py" %*
) else if exist "C:\Python314\python.exe" (
    "C:\Python314\python.exe" "%~dp0serve_preview.py" %*
) else (
    python "%~dp0serve_preview.py" %*
)
if errorlevel 1 pause
popd
endlocal
