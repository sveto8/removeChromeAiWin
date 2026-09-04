@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Chrome AI Cleaner

:: ============================================================
:: DISABLE QUICKEDIT MODE
:: (sprjecava da klik/selekcija u prozoru zamrzne skriptu)
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
echo Ova skripta ce:
echo.
echo   [1] Zatvoriti Chrome
echo   [2] Napraviti Registry backup
echo   [3] Onemoguciti lokalni Chrome AI model
echo   [4] Onemoguciti Gemini / AI Mode
echo   [5] Pronaci i obrisati postojece lokalne AI modele
echo.
echo Bookmarki, lozinke, povijest i ekstenzije se NE diraju.
echo.
pause

:: ============================================================
:: ADMIN CHECK / AUTO ELEVATION
:: ============================================================

net session >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo Administrator prava nisu aktivna.
    echo Pokrecem skriptu kao Administrator...
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try { Start-Process -FilePath '%~f0' -Verb RunAs -Wait; exit 0 } catch { exit 1 }"

    if !errorlevel! neq 0 (
        echo.
        echo ============================================================
        echo [GRESKA] Elevacija nije uspjela.
        echo ============================================================
        echo.
        echo Moguci razlozi:
        echo   - Kliknuo/la si "No" na UAC prompt
        echo   - UAC prompt je blokiran ili se otvorio iza drugih prozora
        echo   - Antivirus / SmartScreen je blokirao PowerShell
        echo.
        echo Pokusaj ponovno i ovaj put klikni "Yes" na UAC prompt,
        echo ili desni klik na ovu .bat datoteku i odaberi
        echo "Run as administrator".
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Elevirani prozor je zavrsio. Zatvaram ovaj prozor za 3 sekunde...
    timeout /t 3 /nobreak >nul
    exit /b 0
)

echo.
echo [OK] Administrator prava potvrdena.

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
echo [1/5] Zatvaranje Chromea
echo ============================================================
echo.

taskkill /F /IM chrome.exe >nul 2>&1

timeout /t 3 /nobreak >nul

echo [OK] Chrome je zatvoren.

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
    echo [OK] HKLM backup napravljen.
) else (
    echo [INFO] Nije postojao prethodni Chrome policy registry.
)

reg export "HKCU\Software\Policies\Google\Chrome" ^
"%BACKUPDIR%\Chrome_HKCU_Backup.reg" /y >nul 2>&1

if exist "%BACKUPDIR%\Chrome_HKCU_Backup.reg" (
    echo [OK] HKCU backup napravljen.
) else (
    echo [INFO] Nije postojao prethodni Chrome policy registry.
)

:: ============================================================
:: CHROME POLICIES
:: ============================================================

echo.
echo ============================================================
echo [3/5] Onemogucavanje Chrome AI funkcija
echo ============================================================
echo.

reg add "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v GenAILocalFoundationalModelSettings ^
 /t REG_DWORD ^
 /d 1 ^
 /f

echo.
echo [OK] Lokalni GenAI model:
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
echo [4/5] Trazenje i brisanje lokalnih AI modela
echo ============================================================
echo.

if not exist "%CHROMEUSER%" (
    echo [INFO] Chrome User Data mapa nije pronadena.
    goto FINISH
)

echo Chrome User Data:
echo %CHROMEUSER%
echo.

:: ------------------------------------------------------------
:: OptGuideOnDeviceModel
:: ------------------------------------------------------------

echo Trazenje: OptGuideOnDeviceModel
echo.

for /d /r "%CHROMEUSER%" %%D in (OptGuideOnDeviceModel) do (
    if exist "%%D" (
        echo [FOUND] %%D
        echo [DELETE] Brisem...
        rmdir /s /q "%%D" 2>nul

        if not exist "%%D" (
            echo [OK] Obrisano.
        ) else (
            echo [WARNING] Nije moguce obrisati.
        )

        echo.
    )
)

:: ------------------------------------------------------------
:: OnDeviceModel
:: ------------------------------------------------------------

echo Trazenje: OnDeviceModel
echo.

for /d /r "%CHROMEUSER%" %%D in (OnDeviceModel) do (
    if exist "%%D" (
        echo [FOUND] %%D
        echo [DELETE] Brisem...
        rmdir /s /q "%%D" 2>nul

        if not exist "%%D" (
            echo [OK] Obrisano.
        ) else (
            echo [WARNING] Nije moguce obrisati.
        )

        echo.
    )
)

:: ------------------------------------------------------------
:: OptimizationGuide model directories
:: ------------------------------------------------------------

echo Trazenje: OptimizationGuide
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
echo Trazenje weights.bin AI modela...
echo.

for /r "%CHROMEUSER%" %%F in (weights.bin) do (

    echo %%F | findstr /I ^
    "OptGuideOnDeviceModel OnDeviceModel OptimizationGuide" >nul

    if !errorlevel! equ 0 (
        echo [FOUND AI MODEL] %%F
        echo [DELETE] Brisem...
        del /f /q "%%F" >nul 2>&1

        if not exist "%%F" (
            echo [OK] Obrisano.
        ) else (
            echo [WARNING] Nije moguce obrisati.
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
echo [5/5] Provjera
echo ============================================================
echo.

echo.
echo Provjera Chrome policies:
echo.

reg query "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v GenAILocalFoundationalModelSettings 2>nul

reg query "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v GeminiSettings 2>nul

reg query "HKLM\SOFTWARE\Policies\Google\Chrome" ^
 /v AIModeSettings 2>nul

echo.
echo ============================================================
echo                       GOTOVO
echo ============================================================
echo.

echo Registry backup nalazi se ovdje:
echo.
echo %BACKUPDIR%
echo.

echo Sada pokreni Chrome i otvori:
echo.
echo chrome://policy
echo.
echo Klikni:
echo.
echo     Reload policies
echo.
echo.
echo Za lokalni AI model provjeri:
echo.
echo     GenAILocalFoundationalModelSettings
echo.
echo Vrijednost mora biti:
echo.
echo     1
echo.

echo ============================================================
echo		PS.	instaliraj linux    :P
echo.
pause

endlocal