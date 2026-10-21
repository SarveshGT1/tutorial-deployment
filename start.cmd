@echo off
rem GT agent workshop: double-click to start. Finds Git Bash and opens the wizard in a 100 x 34 window.
setlocal
chcp 65001 >nul
set "HERE=%~dp0"
set "WORKSHOP_LAUNCHER=1"
set "CHERE_INVOKING=1"
set "GIT="
for %%G in ("%ProgramFiles%\Git" "%ProgramFiles(x86)%\Git" "%LocalAppData%\Programs\Git") do if not defined GIT if exist "%%~G\bin\bash.exe" set "GIT=%%~G"
if not defined GIT (
  echo.
  echo   Git Bash is not installed on this laptop.
  echo   Install "Git for Windows" from the Software Center, then double-click start.cmd again.
  echo.
  pause
  exit /b 1
)
cd /d "%HERE%"
if exist "%GIT%\usr\bin\mintty.exe" (
  start "" "%GIT%\usr\bin\mintty.exe" -s 100,34 -t "GT agent workshop" -h error /usr/bin/bash -l -o igncr ./start.sh
) else (
  "%GIT%\bin\bash.exe" -l -o igncr ./start.sh
  pause
)
