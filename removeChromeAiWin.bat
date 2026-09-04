@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Chrome AI Cleaner

:: ============================================================
:: DISABLE QUICKEDIT MODE
:: (prevents clicking/selection in the window from freezing the script)
:: ============================================================

reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d 0 /f >nul 2>&1

:: ============================================================
:: GOOGLE CHROME AI CLEANER
:: ============================================================

echo.
echo ============================================================
echo             GOOGLE CHROME - AI CLEANER - by Sveto
echo ============================================================
echo.
echo This script will:
echo.
echo   [1] Close Chrome
echo   [2] Create a Registry backup
echo   [3] Disable the local Chrome AI model
echo   [4] Disable Gemini / AI Mode
echo   [5] Find and delete existing local AI models
echo.
echo Bookmarks, passwords, history and extensions are NOT touched.
echo.
pause

:: ============================================================
:: ADMIN CHECK / AUTO ELEVATION
:: ============================================================

net session >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo Administrator rights are not active.
    echo Launching the script as Administrator...
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try { Start-Process -FilePath '%~f0' -Verb RunAs -Wait; exit 0 } catch { exit 1 }"

    if !errorlevel! neq 0 (
        echo.
        echo ============================================================
        echo [ERROR] Elevation failed.
        echo ============================================================
        echo.
        echo Possible reasons:
        echo   - You clicked "No" on the UAC prompt
        echo   - The UAC prompt was blocked or opened behind other windows
        echo   - Antivirus / SmartScreen blocked PowerShell
        echo.
        echo Please try again and this time click "Yes" on the UAC prompt,
        echo or right‑click this .bat file and select
        echo "Run as administrator".
        echo.
        pause
        exit /b 1
    )

    echo.
    echo The elevated window has finished. Closing this window in 3 seconds...
    timeout /t 3 /nobreak >nul
    exit /b 0
)

echo.
echo [OK] Administrator rights confirmed.

:: ============================================================
:: VARIABLES
:: ============================================================

set "CHROMEUSER=%LOCALAPPDATA%\Google\Chrome\User Data"
set "BACKUPDIR=%USERPROFILE%\Desktop\Chrome_AI_Backup"

if not exist "%BACKUPDIR%" (
    mkdir "%BACKUPDIR%"
)

:: ============================================================
:: CLOSE CHROME
:: ============================================================

echo.
echo ============================================================
echo [1/5] Closing Chrome
echo ============================================================
echo.

taskkill /F /IM chrome.exe >nul 2>&1

timeout /t 3 /nobreak >nul

echo [OK] Chrome has been closed.

:: ============================================================
:: REGISTRY BACKUP
:: ============================================================

echo.
echo ============================================================
echo [2/5] Registry backup
echo ============================================================
echo.

reg export "HKLM\SOFTWARE\Policies\Google\Chrome" ^
"%BACKUPDIR%\Chrome_HKLM_Backup.reg" /y >nul 2>&1

if exist "%BACKUPDIR%\Chrome_HKLM_Backup.reg" (
    echo [OK] HKLM backup created.
) else (
    echo [INFO] No previous Chrome policy registry existed.
)

reg export "HKCU\Software\Policies\Google\Chrome" ^
"%BACKUPDIR%\Chrome_HKCU_Backup.reg" /y >nul 2>&1

if exist "%BACKUPDIR%\Chrome_HKCU_Backup.reg" (
    echo [OK] HKCU backup created.
) else (
    echo [INFO] No previous Chrome policy registry existed.
)

:: ============================================================
:: CHROME POLICIES
:: ============================================================

echo.
echo ============================================================
echo [3/5] Disabling Chrome AI features
echo ============================================================
echo.

reg add "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v GenAILocalFoundationalModelSettings ^
 /t REG_DWORD ^
 /d 1 ^
 /f

echo.
echo [OK] Local GenAI model:
echo      GenAILocalFoundationalModelSettings = 1

reg add "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v GeminiSettings ^
 /t REG_DWORD ^
 /d 1 ^
 /f

echo.
echo [OK] Gemini:
echo      GeminiSettings = 1

reg add "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v AIModeSettings ^
 /t REG_DWORD ^
 /d 1 ^
 /f

echo.
echo [OK] AI Mode:
echo      AIModeSettings = 1

:: ============================================================
:: DELETE LOCAL AI MODELS
:: ============================================================

echo.
echo ============================================================
echo [4/5] Searching for and deleting local AI models
echo ============================================================
echo.

if not exist "%CHROMEUSER%" (
    echo [INFO] Chrome User Data folder not found.
    goto FINISH
)

echo Chrome User Data:
echo %CHROMEUSER%
echo.

:: ------------------------------------------------------------
:: OptGuideOnDeviceModel
:: ------------------------------------------------------------

echo Searching: OptGuideOnDeviceModel
echo.

for /d /r "%CHROMEUSER%" %%D in (OptGuideOnDeviceModel) do (
    if exist "%%D" (
        echo [FOUND] %%D
        echo [DELETE] Deleting...
        rmdir /s /q "%%D" 2>nul

        if not exist "%%D" (
            echo [OK] Deleted.
        ) else (
            echo [WARNING] Could not delete.
        )

        echo.
    )
)

:: ------------------------------------------------------------
:: OnDeviceModel
:: ------------------------------------------------------------

echo Searching: OnDeviceModel
echo.

for /d /r "%CHROMEUSER%" %%D in (OnDeviceModel) do (
    if exist "%%D" (
        echo [FOUND] %%D
        echo [DELETE] Deleting...
        rmdir /s /q "%%D" 2>nul

        if not exist "%%D" (
            echo [OK] Deleted.
        ) else (
            echo [WARNING] Could not delete.
        )

        echo.
    )
)

:: ------------------------------------------------------------
:: OptimizationGuide model directories
:: ------------------------------------------------------------

echo Searching: OptimizationGuide
echo.

for /d /r "%CHROMEUSER%" %%D in (OptimizationGuide) do (
    if exist "%%D" (
        echo [FOUND] %%D
        echo.

        :: Only remove obvious model/cache subdirectories
        for /d %%M in ("%%D\*model*" "%%D\*Model*" "%%D\*optimization*") do (
            if exist "%%M" (
                echo [DELETE] %%M
                rmdir /s /q "%%M" 2>nul
            )
        )
    )
)

:: ------------------------------------------------------------
:: weights.bin - only if path clearly belongs to AI model
:: ------------------------------------------------------------

echo.
echo Searching for weights.bin AI models...
echo.

for /r "%CHROMEUSER%" %%F in (weights.bin) do (

    echo %%F | findstr /I ^
    "OptGuideOnDeviceModel OnDeviceModel OptimizationGuide" >nul

    if !errorlevel! equ 0 (
        echo [FOUND AI MODEL] %%F
        echo [DELETE] Deleting...
        del /f /q "%%F" >nul 2>&1

        if not exist "%%F" (
            echo [OK] Deleted.
        ) else (
            echo [WARNING] Could not delete.
        )

        echo.
    )
)

:: ============================================================
:: FINISH / POLICY VERIFICATION
:: ============================================================

:FINISH

echo.
echo ============================================================
echo [5/5] Verification
echo ============================================================
echo.

echo.
echo Checking Chrome policies:
echo.

reg query "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v GenAILocalFoundationalModelSettings 2>nul

reg query "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v GeminiSettings 2>nul

reg query "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v AIModeSettings 2>nul

echo.
echo ============================================================
echo                       DONE
echo ============================================================
echo.

echo Registry backup is located at:
echo.
echo %BACKUPDIR%
echo.

echo Now start Chrome and open:
echo.
echo chrome://policy
echo.
echo Click:
echo.
echo     Reload policies
echo.
echo.
echo For the local AI model, verify:
echo.
echo     GenAILocalFoundationalModelSettings
echo.
echo Its value must be:
echo.
echo     1
echo.

echo ============================================================
echo		PS. install linux    :P
echo.
pause

endlocal
