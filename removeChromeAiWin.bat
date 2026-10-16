@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Chrome AI Cleaner

:: ============================================================
:: ADMIN CHECK / AUTO ELEVATION (done first, so the intro
:: screen is shown only once, in the elevated window)
:: ============================================================

fltmc >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Administrator rights are not active.
    echo Launching the script as Administrator...
    echo.

    set "BATFILE=%~f0"
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try { Start-Process -FilePath $env:BATFILE -Verb RunAs -Wait; exit 0 } catch { exit 1 }"

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
        echo Please try again and click "Yes" on the UAC prompt,
        echo or right-click this .bat file and select
        echo "Run as administrator".
        echo.
        pause
        exit /b 1
    )
    exit /b 0
)

:: ============================================================
:: INTRO
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
echo   [3] Disable the local Chrome AI model, Gemini and AI Mode
echo   [4] Find and delete existing local AI models
echo   [5] Verify the result
echo.
echo Bookmarks, passwords, history and extensions are NOT touched.
echo.
pause

:: ============================================================
:: VARIABLES
:: ============================================================

set "CHROMEUSER=%LOCALAPPDATA%\Google\Chrome\User Data"
set "BACKUPDIR=%USERPROFILE%\Desktop\Chrome_AI_Backup"
set "POLKEY=HKLM\SOFTWARE\Policies\Google\Chrome"

if not exist "%BACKUPDIR%" mkdir "%BACKUPDIR%"

:: ============================================================
:: [1/5] CLOSE CHROME
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
:: [2/5] REGISTRY BACKUP
:: An existing backup is NEVER overwritten, so re-running the
:: script cannot replace your original settings with modified ones.
:: ============================================================

echo.
echo ============================================================
echo [2/5] Registry backup
echo ============================================================
echo.

call :BACKUP "HKLM\SOFTWARE\Policies\Google\Chrome" "%BACKUPDIR%\Chrome_HKLM_Backup.reg" HKLM
call :BACKUP "HKCU\Software\Policies\Google\Chrome" "%BACKUPDIR%\Chrome_HKCU_Backup.reg" HKCU

:: ============================================================
:: [3/5] CHROME POLICIES
:: ============================================================

echo.
echo ============================================================
echo [3/5] Disabling Chrome AI features
echo ============================================================
echo.

call :SETPOL GenAILocalFoundationalModelSettings "Local GenAI model"
call :SETPOL GeminiSettings "Gemini"
call :SETPOL AIModeSettings "AI Mode"

:: ============================================================
:: [4/5] DELETE LOCAL AI MODELS
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

for %%N in (OptGuideOnDeviceModel OnDeviceModel) do (
    echo Searching: %%N
    for /f "delims=" %%D in ('dir /s /b /ad "%CHROMEUSER%\%%N" 2^>nul') do (
        if exist "%%D" (
            echo [FOUND]  %%D
            rmdir /s /q "%%D" 2>nul
            if not exist "%%D" (
                echo [OK] Deleted.
            ) else (
                echo [WARNING] Could not delete.
            )
            echo.
        )
    )
)

:: Safety net: weights.bin that is still inside a recognised AI folder
echo Searching: leftover weights.bin
for /f "delims=" %%F in ('dir /s /b /a-d "%CHROMEUSER%\weights.bin" 2^>nul ^| findstr /I "OptGuideOnDeviceModel OnDeviceModel"') do (
    if exist "%%F" (
        echo [FOUND]  %%F
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
:: [5/5] VERIFICATION
:: ============================================================

:FINISH

echo.
echo ============================================================
echo [5/5] Verification
echo ============================================================
echo.

reg query "%POLKEY%" /v GenAILocalFoundationalModelSettings 2>nul
reg query "%POLKEY%" /v GeminiSettings 2>nul
reg query "%POLKEY%" /v AIModeSettings 2>nul

echo.
echo ============================================================
echo                       DONE
echo ============================================================
echo.
echo Registry backup is located at:
echo   %BACKUPDIR%
echo.
echo Now start Chrome, open chrome://policy and click "Reload policies".
echo Each of these must have the value 1:
echo   GenAILocalFoundationalModelSettings
echo   GeminiSettings
echo   AIModeSettings
echo.
echo ============================================================
echo   PS. install linux    :P
echo.
pause
endlocal
exit /b 0

:: ============================================================
:: SUBROUTINES
:: ============================================================

:BACKUP
:: %1 = registry key, %2 = target .reg file, %3 = label
if exist %2 (
    echo [INFO] %~3 backup already exists, keeping the original.
    exit /b 0
)
reg export %1 %2 /y >nul 2>&1
if exist %2 (
    echo [OK] %~3 backup created.
) else (
    echo [INFO] No previous %~3 Chrome policies existed, nothing to back up.
)
exit /b 0

:SETPOL
:: %1 = policy name, %~2 = description
reg add "%POLKEY%" /v %1 /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Could not set %1
) else (
    echo [OK] %~2: %1 = 1
)
exit /b 0
