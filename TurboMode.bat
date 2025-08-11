@echo off
setlocal enabledelayedexpansion

echo [1/4] Detecting Balanced power plan GUID...
for /f "tokens=2 delims=:" %%G in ('powercfg /list ^| findstr /i "Balanced"') do (
    for /f "tokens=1 delims= " %%H in ("%%G") do set "BALGUID=%%H"
)

if not defined BALGUID (
    echo ERROR: Could not detect Balanced plan. Aborting.
    pause
    exit /b
)

echo Found Balanced GUID: %BALGUID%

echo [2/4] Duplicating Balanced to create TurboMode...
for /f "tokens=2 delims=:" %%G in ('powercfg -duplicatescheme %BALGUID% ^| findstr /i "GUID"') do (
    for /f "tokens=1 delims= " %%H in ("%%G") do set "TURBOGUID=%%H"
)

if not defined TURBOGUID (
    echo ERROR: Could not detect new plan GUID.
    pause
    exit /b
)

echo New TurboMode GUID: %TURBOGUID%

echo [3/4] Renaming and describing TurboMode plan...
powercfg -changename %TURBOGUID% "TurboMode" "Maximum performance for gaming and heavy workloads."

echo [4/4] Applying TurboMode settings (skipping missing ones)...

REM CPU always at 100%
call :setSafe SUB_PROCESSOR PROCTHROTTLEMAX 100
call :setSafe SUB_PROCESSOR PROCTHROTTLEMIN 100
call :setSafe SUB_PROCESSOR PERFBOOSTMODE 0

REM Disable idle timers
call :setSafe SUB_VIDEO VIDEOIDLE 0 0
call :setSafe SUB_SLEEP STANDBYIDLE 0 0
call :setSafe SUB_SLEEP HIBERNATEIDLE 0 0
call :setSafe SUB_DISK DISKIDLE 0

REM Disable USB suspend
call :setSafe SUB_USB USBSELECTSUSPEND 0

REM Maximize graphics performance
call :setSafe SUB_GRAPHICS GPUPOWER 0

REM (Optional) Disable adaptive display brightness if present
call :setSafe SUB_VIDEO ADAPTBRIGHT 0

echo.
echo TurboMode power plan created successfully!
echo To enable it now, run:
echo   powercfg -setactive %TURBOGUID%
pause
exit /b

:setSafe
set "SUB=%~1"
set "SET=%~2"
set "ACVAL=%~3"
set "DCVAL=%~4"
if "%DCVAL%"=="" set "DCVAL=%ACVAL%"
powercfg -setacvalueindex %TURBOGUID% %SUB% %SET% %ACVAL% >nul 2>&1
powercfg -setdcvalueindex %TURBOGUID% %SUB% %SET% %DCVAL% >nul 2>&1
exit /b
