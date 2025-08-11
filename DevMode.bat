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

echo [2/4] Duplicating Balanced to create DevMode...
for /f "tokens=2 delims=:" %%G in ('powercfg -duplicatescheme %BALGUID% ^| findstr /i "GUID"') do (
    for /f "tokens=1 delims= " %%H in ("%%G") do set "DEVGUID=%%H"
)

if not defined DEVGUID (
    echo ERROR: Could not detect new plan GUID.
    pause
    exit /b
)

echo New DevMode GUID: %DEVGUID%

echo [3/4] Renaming and describing DevMode plan...
powercfg -changename %DEVGUID% "DevMode" "Long battery life, optimized for coding/programming."

echo [4/4] Applying DevMode settings (skipping missing ones)...

REM Helper macro to set value and suppress "Invalid Parameters"
set "_setval=for %%P in (ac dc) do for %%X in (!SUB! !SET! !VAL!) do @"
setlocal

call :setSafe SUB_PROCESSOR PROCTHROTTLEMAX 80
call :setSafe SUB_PROCESSOR PROCTHROTTLEMIN 5
call :setSafe SUB_PROCESSOR PERFBOOSTMODE 1

call :setSafe SUB_VIDEO VIDEOIDLE 300 120
call :setSafe SUB_SLEEP STANDBYIDLE 600 300

call :setSafe SUB_DISK DISKIDLE 300
call :setSafe SUB_USB USBSELECTSUSPEND 1
call :setSafe SUB_GRAPHICS GPUPOWER 2

echo.
echo DevMode power plan created successfully!
echo To enable it, run:
echo   powercfg -setactive %DEVGUID%
pause
exit /b

:setSafe
set "SUB=%~1"
set "SET=%~2"
set "ACVAL=%~3"
set "DCVAL=%~4"
if "%DCVAL%"=="" set "DCVAL=%ACVAL%"
powercfg -setacvalueindex %DEVGUID% %SUB% %SET% %ACVAL% >nul 2>&1
powercfg -setdcvalueindex %DEVGUID% %SUB% %SET% %DCVAL% >nul 2>&1
exit /b
