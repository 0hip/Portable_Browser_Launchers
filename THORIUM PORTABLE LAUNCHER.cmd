@echo off
::   check for updates
::         0   no check
::         1   auto
::         2   ask first
::
set "check=2"
::
::
title "THORIUM PORTABLE LAUNCHER"
set "repo=/Alex313031/Thorium-Win"
cd /d "%~dp0"
if not exist bin\ (call :brandnew rel& goto auto)
if not "%check%"=="1" if not "%check%"=="2" goto run
if %check%==1 goto auto
echo:
choice /m "... CHECK FOR UPDATE AND INSTALL IT?"
cls
if %ERRORLEVEL% EQU 2 goto run
:auto
if exist "bin\thor_ver" set /P rel=<"bin\thor_ver"
if not defined rel (echo error: NOT A THORIUM RELEASE! Move THORIUM LAUNCHER to a new folder and try again. & pause & exit)
set "rel=%rel:*-=%"
if %rel%==Win set "rel=AVX" 
echo ..    RELEASE TYPE : %rel%
type nul >latest || (echo error: NO WRITE ACCESS & pause & exit)
CURL -s https://api.github.com/repos%repo%/releases/latest>latest
set "v="
for /f "delims=" %%G in ('type latest ^|find /i "tag_name"') do set "v=%%G"
if not defined v (echo error: NOTHING FOUND! REPO CHANGED? & pause & exit)
set "v=%v:*"M=%"
set "v=%v:",=%"
if not exist bin\ goto install
set "c="
for /f "delims=" %%G in ('dir /b /ad bin ^| findstr /r /v [a-Z] ^| findstr /r \.') do set "c=%%G"
if not defined c goto install
if %c%==%v% (echo No new version found ... & goto run)
echo NEW VERSION FOUND! Updating ...
:install
echo Setting up DOWNLOAD LINK ...
set "c="
for /f "delims=" %%G in ('type latest ^|find /i "browser_download_url" ^|find /i "_%rel%_" ^|find /i ".zip"') do set "c=%%G"
if not defined c (echo error: DOWNLOAD LINK NOT FOUND. REPO CHANGED?  & pause & exit)
set "c=%c:*"https="https%"
echo Downloading THORIUM PORTABLE ...
@echo on
CURL -L -o new.zip %c% || (echo error: DOWNLOAD FAILED. Launcher will exit & pause & exit)
@echo off
cls
if exist bin/ (echo Backup bin to _bin ... & move /y bin _bin >nul)
echo Unzipping THORIUM ...
tar -xf new.zip && del new.zip
echo ... SUCCESS!
:run
if exist _bin/ rd /s /q _bin
if exist latest del latest
echo Starting THORIUM PORTABLE ...
start "" "%~dp0bin\Thorium" --user-data-dir="%~dp0USER_DATA" --allow-outdated-plugins --disable-logging --disable-breakpad
ping -n 2 127.0.0.1>nul
exit


:brandnew
SETLOCAL ENABLEDELAYEDEXPANSION
echo:
choice /m "... THORIUM PORTABLE WILL BE INSTALLED FOR THE FIST TIME. CONTINUE?"
if !ERRORLEVEL! EQU 2 exit
cls
set "a1=AVX2"
set "a2=AVX"
set "a3=SSE3"
ECHO:########   RELEASE TYPES   ########
ECHO: 1: %a1%    Most Intel/AMD CPUs since 2017
ECHO: 2: %a2%     Intel/AMD CPUs since 2012
ECHO: 3: %a3%    For CPUs that lack AVX. Generally CPUs older than 2012.
CHOICE /C 123 /N /M ".. PICK ONE [1,2,3]: "
set "n=!a%ERRORLEVEL%!"
ENDLOCAL& set %~1=%n%
