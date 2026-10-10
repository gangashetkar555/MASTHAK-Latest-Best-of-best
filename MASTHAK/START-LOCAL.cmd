@echo off
setlocal
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
 echo Install Node.js 22 LTS or newer from https://nodejs.org and reopen this file.
 pause
 exit /b 1
)
where npm >nul 2>nul
if errorlevel 1 (
 echo npm is missing. Reinstall Node.js with npm included.
 pause
 exit /b 1
)
if not exist "node_modules\next\package.json" (
 echo Installing the locked project dependencies. Internet is required for this step.
 call npm ci
 if errorlevel 1 (
  echo Installation failed. Check your internet connection and read readme.txt.
  pause
  exit /b 1
 )
)
echo Open http://localhost:3000 after the server says Ready.
echo Keep this window open while using the website. Press Ctrl+C to stop it.
call npm run dev
if errorlevel 1 pause
