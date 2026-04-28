@echo off
REM Fittrack local dev runner: verifies the toolchain, ensures Postgres is up,
REM runs typecheck + vitest, then boots the API in this window.
REM Logs go to .\logs\run-<timestamp>.log. On failure, prints the failing step's
REM log tail and exits non-zero.
REM
REM Usage:
REM   dev.bat         -> full flow (checks + start api)
REM   dev.bat check   -> checks only (typecheck + vitest)

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

echo ==========================================>>"%LOG%"
echo  fittrack dev runner @ %date% %time%>>"%LOG%"
echo ==========================================>>"%LOG%"

echo.
echo [fittrack] Log: %LOG%
echo.

REM ---- 0. Toolchain check ----
echo [1/5] Toolchain...
echo ----- toolchain ----->>"%LOG%"
where node >nul 2>&1 || (call :fail "node yok - Node.js 20+ kur." & goto :end)
where pnpm >nul 2>&1 || (call :fail "pnpm yok - 'npm install -g pnpm'." & goto :end)

REM ---- 1. PostgreSQL ----
echo [2/5] PostgreSQL...
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
echo [3/5] pnpm typecheck...
echo ----- typecheck ----->>"%LOG%"
call pnpm typecheck >>"%LOG%" 2>&1 || (call :fail "pnpm typecheck basarisiz." & goto :end)

REM ---- 4. Backend vitest ----
echo [4/5] Backend tests (vitest)...
echo ----- vitest ----->>"%LOG%"
call pnpm --filter @fittrack/api test >>"%LOG%" 2>&1 || (call :fail "vitest basarisiz." & goto :end)

echo.
echo [OK] Tum kontroller yesil.
echo.
echo ----- all checks OK ----->>"%LOG%"

if "%MODE%"=="check" (
  echo [check] Sadece kontrol modu - api baslatilmiyor. Tam calistirma icin: dev.bat
  echo ----- check mode exit ----->>"%LOG%"
  endlocal
  exit /b 0
)

REM ---- 5. Start API ----
echo [5/5] API baslatiliyor (http://localhost:3000)...
echo ----- api dev ----->>"%LOG%"
call pnpm dev:api

echo.
echo [done] api kapandi.
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
