@echo off
setlocal EnableDelayedExpansion

:: ===============================================================
:: Safe Power Plan Cleanup
:: - Restores default power plans
:: - Deletes only custom ones (no SYSTEM escalation)
:: - If Windows refuses deletion, it skips that plan
:: ===============================================================

echo.
echo === Restoring default Windows power schemes...
powercfg -restoredefaultschemes

:: Get default GUIDs
set "keepList="
for /f "tokens=2 delims=:" %%A in ('powercfg -list ^| findstr /i "Balanced"') do (
    for /f "tokens=1 delims= " %%B in ("%%A") do set "keepList=!keepList! %%B"
)
for /f "tokens=2 delims=:" %%A in ('powercfg -list ^| findstr /i "High performance"') do (
    for /f "tokens=1 delims= " %%B in ("%%A") do set "keepList=!keepList! %%B"
)
for /f "tokens=2 delims=:" %%A in ('powercfg -list ^| findstr /i "Power saver"') do (
    for /f "tokens=1 delims= " %%B in ("%%A") do set "keepList=!keepList! %%B"
)

echo.
echo === Default schemes to keep:
for %%G in (%keepList%) do echo   %%G

:: Enumerate all plans and remove non-defaults
echo.
echo === Checking for custom schemes to remove...
for /f "tokens=2 delims=:" %%A in ('powercfg -list ^| findstr /i "Power Scheme GUID"') do (
    for /f "tokens=1 delims= " %%B in ("%%A") do (
        set "guid=%%B"
        set "skip=0"
        for %%K in (%keepList%) do (
            if /i "!guid!"=="%%K" set "skip=1"
        )
        if !skip! equ 0 (
            echo Removing custom plan !guid! ...
            powercfg -delete !guid! || echo   ^> Skipped (protected or in use)
        )
    )
)

echo.
echo === Setting Balanced as active...
for %%K in (%keepList%) do (
    powercfg -setactive %%K
    goto doneActivate
)
:doneActivate

echo.
echo === Cleanup complete.
pause
endlocal
