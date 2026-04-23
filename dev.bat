@echo off
REM FitTrack local dev runner: verifies the toolchain, runs all checks,
REM then boots an Android emulator and launches flutter run.
REM Logs go to .\logs\run-<timestamp>.log. On failure, the script prints
REM the failing step's log tail and exits non-zero.
REM
REM Usage:
REM   dev.bat         -> full flow (checks + emulator + flutter run)
REM   dev.bat check   -> checks only

chcp 65001 >nul
setlocal EnableDelayedExpansion

set ROOT=%~dp0
cd /d "%ROOT%"

set MODE=full
if /I "%~1"=="check" set MODE=check
if /I "%~1"=="--check" set MODE=check

if not exist "%ROOT%logs" mkdir "%ROOT%logs"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set STAMP=%%i
set LOG=%ROOT%logs\run-!STAMP!.log

set PG_BIN=C:\Program Files\PostgreSQL\17\bin
set PGDATA=%USERPROFILE%\dev\pgdata
set PGLOG=%USERPROFILE%\dev\pg.log
set FLUTTER_BIN=%USERPROFILE%\dev\flutter\bin
if exist "%FLUTTER_BIN%\flutter.bat" set PATH=%PATH%;%FLUTTER_BIN%

echo ==========================================>>"%LOG%"
echo  FitTrack dev runner @ %date% %time%>>"%LOG%"
echo ==========================================>>"%LOG%"

echo.
echo [FitTrack] Log: %LOG%
echo.

REM ---- 0. Toolchain check ----
echo [1/7] Toolchain...
echo ----- toolchain ----->>"%LOG%"
where node    >nul 2>&1 || (call :fail "node yok - Node.js 20+ kur." & goto :end)
where pnpm    >nul 2>&1 || (call :fail "pnpm yok - 'npm install -g pnpm'." & goto :end)
where flutter >nul 2>&1 || (call :fail "flutter PATH'te degil. Yeni bir CMD ac ya da PATH'i kontrol et." & goto :end)

REM ---- 1. PostgreSQL ----
echo [2/7] PostgreSQL...
echo ----- postgres ----->>"%LOG%"
"%PG_BIN%\pg_ctl.exe" -D "%PGDATA%" status >>"%LOG%" 2>&1
if errorlevel 1 (
  echo        not running - starting...
  "%PG_BIN%\pg_ctl.exe" -D "%PGDATA%" -l "%PGLOG%" start >>"%LOG%" 2>&1
  if errorlevel 1 (call :fail "PostgreSQL baslatilamadi." & goto :end)
) else (
  echo        already running.
)

REM ---- 2. Install deps if missing ----
if not exist "%ROOT%node_modules" (
  echo [deps] pnpm install
  echo ----- pnpm install ----->>"%LOG%"
  call pnpm install >>"%LOG%" 2>&1 || (call :fail "pnpm install basarisiz." & goto :end)
)

REM ---- 3. Typecheck ----
echo [3/7] pnpm typecheck...
echo ----- typecheck ----->>"%LOG%"
call pnpm typecheck >>"%LOG%" 2>&1 || (call :fail "pnpm typecheck basarisiz." & goto :end)

REM ---- 4. Backend vitest ----
echo [4/7] Backend tests (vitest)...
echo ----- vitest ----->>"%LOG%"
call pnpm --filter @fittrack/api test >>"%LOG%" 2>&1 || (call :fail "vitest basarisiz." & goto :end)

REM ---- 5. Flutter analyze ----
echo [5/7] flutter analyze...
echo ----- flutter analyze ----->>"%LOG%"
pushd "%ROOT%apps\mobile"
call flutter analyze >>"%LOG%" 2>&1
set RC=!ERRORLEVEL!
popd
if !RC! NEQ 0 (call :fail "flutter analyze lint hatasi buldu." & goto :end)

REM ---- 6. Flutter test ----
echo [6/7] flutter test...
echo ----- flutter test ----->>"%LOG%"
pushd "%ROOT%apps\mobile"
call flutter test >>"%LOG%" 2>&1
set RC=!ERRORLEVEL!
popd
if !RC! NEQ 0 (call :fail "flutter test basarisiz." & goto :end)

echo.
echo [OK] Tum kontroller yesil.
echo.
echo ----- all checks OK ----->>"%LOG%"

if "%MODE%"=="check" (
  echo [check] Sadece kontrol modu - emulator acilmiyor. Tam calistirma icin: dev.bat
  echo ----- check mode exit ----->>"%LOG%"
  endlocal
  exit /b 0
)

REM ---- 7. Device: reuse running one or launch emulator ----
echo [7/7] Android cihaz / emulator...
echo ----- device ----->>"%LOG%"
flutter devices >>"%LOG%" 2>&1

flutter devices 2>nul | findstr /I "android" | findstr /V /I "web windows linux macos" >nul
if not errorlevel 1 (
  echo        zaten bagli bir Android cihaz var.
  goto :run_app
)

set EMUID=
for /f "usebackq delims=" %%L in (`powershell -NoProfile -Command "(& flutter emulators) 2>$null | Where-Object { $_ -match [char]0x2022 } | ForEach-Object { ($_ -split [char]0x2022)[0].Trim() } | Select-Object -First 1"`) do set EMUID=%%L

if "!EMUID!"=="" (
  echo        AVD yok - yeni bir tane olusturuyorum ^(fittrack^)...
  call flutter emulators --create --name fittrack >>"%LOG%" 2>&1
  if errorlevel 1 (
    call :fail "AVD olusturulamadi. Android Studio ^> Virtual Device Manager ile manuel kur."
    goto :end
  )
  set EMUID=fittrack
)

echo        Launching !EMUID! ^(yeni pencerede^)...
start "FitTrack Emulator" cmd /c "flutter emulators --launch !EMUID!"

echo        Emulatorun boot olmasini bekliyorum ^(maks 240 sn^)...
set WAITED=0
:waitloop
powershell -NoProfile -Command "Start-Sleep -Seconds 5" >nul
flutter devices 2>nul | findstr /I "android" | findstr /V /I "web windows linux macos" >nul
if not errorlevel 1 goto :emu_ready
set /a WAITED=!WAITED!+5
if !WAITED! GEQ 240 (call :fail "Emulator 240 sn icinde hazir olmadi." & goto :end)
echo        ...!WAITED!s
goto :waitloop

:emu_ready
echo        cihaz hazir.

:run_app
echo.
echo [api] Backend ayri bir pencerede baslatiliyor...
start "FitTrack API" cmd /k "cd /d %ROOT% && pnpm dev:api"

echo [mobile] flutter run --dart-define=API_URL=http://10.0.2.2:3000
echo.
pushd "%ROOT%apps\mobile"
flutter run --dart-define=API_URL=http://10.0.2.2:3000
popd

echo.
echo [done] flutter run kapandi. Backend penceresi hala acik; Ctrl+C ile kapatabilirsin.
endlocal
exit /b 0

REM ============================================================
:fail
echo.
echo [FAIL] %~1
echo --- log tail ---
powershell -NoProfile -Command "Get-Content -Path '%LOG%' -Tail 30"
echo ----------------
echo Tam log: %LOG%
exit /b 0

:end
endlocal
exit /b 1
