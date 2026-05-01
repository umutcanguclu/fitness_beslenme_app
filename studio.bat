@echo off
REM Android Studio + emulator + flutter run launcher.
REM 1) Detects Android Studio and opens it (offers winget install if missing).
REM 2) Detects Android SDK + AVDs and starts the first available virtual device.
REM 3) Waits for the emulator to finish booting, then runs `flutter run` against
REM    apps/mobile in a separate cmd window (hot reload friendly).
REM
REM Usage:
REM   studio.bat              -> studio + AVD + flutter run
REM   studio.bat --check      -> report studio + SDK + AVD status (no actions)
REM   studio.bat --install    -> skip detection, run installer
REM   studio.bat --no-emu     -> open studio only (skip AVD + flutter run)
REM   studio.bat --no-app     -> open studio + AVD, skip flutter run
REM   studio.bat --avd <name> -> start a specific AVD by name

chcp 65001 >nul
setlocal EnableDelayedExpansion

set "ROOT=%~dp0"
set "MODE=open"
set "SKIP_EMU=0"
set "SKIP_APP=0"
set "FORCE_AVD="

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--install" ( set "MODE=install" & shift & goto parse_args )
if /I "%~1"=="--check"   ( set "MODE=check"   & shift & goto parse_args )
if /I "%~1"=="--no-emu"  ( set "SKIP_EMU=1"   & set "SKIP_APP=1" & shift & goto parse_args )
if /I "%~1"=="--no-app"  ( set "SKIP_APP=1"   & shift & goto parse_args )
if /I "%~1"=="--avd"     ( set "FORCE_AVD=%~2" & shift & shift & goto parse_args )
shift
goto parse_args
:args_done

REM ---- 1. Studio detection ----
set "STUDIO_EXE="
for %%P in (
  "%ProgramFiles%\Android\Android Studio\bin\studio64.exe"
  "%ProgramFiles%\Android\Android Studio\bin\studio.exe"
  "%ProgramFiles(x86)%\Android\Android Studio\bin\studio64.exe"
  "%ProgramFiles(x86)%\Android\Android Studio\bin\studio.exe"
  "%LOCALAPPDATA%\Programs\Android Studio\bin\studio64.exe"
  "%LOCALAPPDATA%\Programs\Android Studio\bin\studio.exe"
) do (
  if not defined STUDIO_EXE if exist %%P set "STUDIO_EXE=%%~P"
)
if not defined STUDIO_EXE (
  for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Android Studio" /v Path 2^>nul ^| findstr /I "Path"') do (
    if exist "%%~b\bin\studio64.exe" set "STUDIO_EXE=%%~b\bin\studio64.exe"
  )
)
if not defined STUDIO_EXE (
  for /f "tokens=2,*" %%a in ('reg query "HKCU\SOFTWARE\Android Studio" /v Path 2^>nul ^| findstr /I "Path"') do (
    if exist "%%~b\bin\studio64.exe" set "STUDIO_EXE=%%~b\bin\studio64.exe"
  )
)

REM ---- 2. SDK + emulator + adb detection ----
set "SDK_ROOT="
set "EMU_EXE="
set "ADB_EXE="
for %%S in (
  "%ANDROID_HOME%"
  "%ANDROID_SDK_ROOT%"
  "%LOCALAPPDATA%\Android\Sdk"
) do (
  if not defined SDK_ROOT if not "%%~S"=="" if exist "%%~S\emulator\emulator.exe" (
    set "SDK_ROOT=%%~S"
    set "EMU_EXE=%%~S\emulator\emulator.exe"
    if exist "%%~S\platform-tools\adb.exe" set "ADB_EXE=%%~S\platform-tools\adb.exe"
  )
)

if "%MODE%"=="install" set "STUDIO_EXE="

REM ---- check mode: report and exit ----
if "%MODE%"=="check" (
  if defined STUDIO_EXE ( echo [studio] kurulu: !STUDIO_EXE! ) else ( echo [studio] kurulu degil. )
  if defined EMU_EXE (
    echo [sdk]    !SDK_ROOT!
    echo [emu]    !EMU_EXE!
    if defined ADB_EXE ( echo [adb]    !ADB_EXE! ) else ( echo [adb]    YOK - platform-tools kur. )
    echo --- AVDs ---
    "!EMU_EXE!" -list-avds 2>nul
  ) else (
    echo [sdk]    bulunamadi. Studio acildiginda SDK Manager kurar.
  )
  if exist "%ROOT%apps\mobile\pubspec.yaml" ( echo [app]    apps\mobile var. ) else ( echo [app]    apps\mobile YOK. )
  endlocal
  exit /b 0
)

REM ---- 3. Studio not found ----
if not defined STUDIO_EXE (
  echo [FAIL] Android Studio bulunamadi.
  echo        Manuel kur: https://developer.android.com/studio
  endlocal
  exit /b 1
)

REM ---- 4. Open Studio ----
echo [studio] aciliyor: !STUDIO_EXE!
start "" "!STUDIO_EXE!"

REM ---- 5. Emulator launch ----
set "EMU_ALREADY_RUNNING=0"
tasklist /NH 2>nul | findstr /I "qemu-system" >nul
if not errorlevel 1 set "EMU_ALREADY_RUNNING=1"

if "%SKIP_EMU%"=="1" (
  echo [emu]    --no-emu, atlandi.
  goto post_emu
)
if not defined EMU_EXE (
  echo [emu]    SDK bulunamadi. Studio - SDK Manager + Virtual Device Manager'dan kur, tekrar dene.
  goto post_emu
)
if "%EMU_ALREADY_RUNNING%"=="1" (
  echo [emu]    zaten calisan emulator var, yeniden baslatilmadi.
  goto post_emu
)

set "AVD_NAME=%FORCE_AVD%"
if not defined AVD_NAME (
  for /f "delims=" %%A in ('"!EMU_EXE!" -list-avds 2^>nul') do (
    if not defined AVD_NAME set "AVD_NAME=%%A"
  )
)
if not defined AVD_NAME (
  echo [emu]    AVD yok. Android Studio - More Actions - Virtual Device Manager - "+ Create" ile olustur.
  goto post_emu
)

echo [emu]    AVD baslatiliyor: !AVD_NAME!
start "" "!EMU_EXE!" -avd "!AVD_NAME!"

:post_emu

REM ---- 6. flutter run on emulator ----
if "%SKIP_APP%"=="1" (
  echo [app]    atlandi.
  endlocal & exit /b 0
)
if not exist "%ROOT%apps\mobile\pubspec.yaml" (
  echo [app]    apps\mobile yok, atlandi.
  endlocal & exit /b 0
)
where flutter >nul 2>&1
if errorlevel 1 (
  echo [app]    flutter PATH'te yok. Manuel: cd apps\mobile ^&^& flutter run
  endlocal & exit /b 0
)
if not defined ADB_EXE (
  echo [app]    adb yok, emulator bootunu bekleyemiyorum.
  echo          Boot olunca: cd apps\mobile ^&^& flutter run
  endlocal & exit /b 0
)

echo [app]    emulator boot bekleniyor (max 180s)...
set /a WAITED=0
:wait_loop
set "BOOTED="
for /f "delims=" %%B in ('"!ADB_EXE!" shell getprop sys.boot_completed 2^>nul') do set "BOOTED=%%B"
if "!BOOTED!"=="1" goto booted
"C:\Windows\System32\timeout.exe" /t 3 /nobreak >nul
set /a WAITED+=3
if !WAITED! GEQ 180 (
  echo [app]    timeout - emulator hazir degil. Boot olunca: cd apps\mobile ^&^& flutter run
  endlocal & exit /b 0
)
goto wait_loop

:booted
echo [app]    emulator hazir (boot completed). flutter run yeni pencerede...
start "fittrack -- flutter run" cmd /k "cd /d %ROOT%apps\mobile && flutter run"

endlocal
exit /b 0
