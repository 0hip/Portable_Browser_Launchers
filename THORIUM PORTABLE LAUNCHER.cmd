@echo off
title "THORIUM PORTABLE LAUNCHER"
set "repo=/Alex313031/Thorium-Win"
cd /d "%~dp0"

if not exist bin\ (
echo FIRST TIME RUNNING THORIUM PORTABLE LAUNCHER ...
call :brandnew rel
call :getweb
call :download
call :install
call :run
)
if exist new.zip (
echo Applying the UPDATE ...
goto resume
)
if not exist "bin\thor_ver" (
echo error: Current Version NOT A THORIUM RELEASE!
echo Move THORIUM PORTABLE LAUNCHER to another folder and try again.
pause
exit
)
set "rel=none"
set /P rel=<"bin\thor_ver"
set "rel=%rel:*-=%"
if %rel%==Win set "rel=AVX" 
echo .. RELEASE TYPE: %rel%
call :getlocal
echo current version: %local%
call :getweb
echo _latest version: %tag%
if %local%==%tag% (
echo No new version found ...
goto run
)
echo NEW VERSION FOUND!
call :download
:resume
::MOVING BIN TO _BIN as backup...
2>nul (move /y bin _bin >nul) || (
echo THORIUM PORTABLE IS CURRENTLY RUNNING [BIN folder is being used]
echo Will apply the UPDATE on the next LAUNCH!
ping -n 5 127.0.0.1>nul
exit
)
call :install
:run
if exist latest del latest
set test="%~dp0USER_DATA\Default\Cache\Cache_Data\index"
if exist %test% (2>nul (type nul>%test%) || goto norun)
echo Starting THORIUM PORTABLE ...
start "" "%~dp0bin\Thorium" --user-data-dir="%~dp0USER_DATA" --allow-outdated-plugins --disable-logging --disable-breakpad
:norun
ping -n 2 127.0.0.1>nul
exit

:getlocal
set "local=0"
for /f "delims=" %%G in (
'dir /b /ad bin ^| findstr /r /v [a-Z] ^| findstr /r \.'
) do set "local=%%G"
exit /b

:getweb
type nul>latest || (echo error: NO WRITE ACCESS & pause & exit)
CURL -s https://api.github.com/repos%repo%/releases/latest>latest
::VERSION TAG
set "tag="
for /f "delims=" %%G in ('type latest ^|find /i "tag_name"') do set "tag=%%G"
if not defined tag (echo error: NOTHING FOUND! REPO CHANGED? & pause & exit)
set "tag=%tag:*"M=%"
set "tag=%tag:",=%"
::DOWNLOAD URL
set "url="
for /f "delims=" %%G in (
'type latest ^|find /i "browser_download_url" ^|find /i "_%rel%_" ^|find /i ".zip"'
) do set "url=%%G"
if not defined url (echo error: DOWNLOAD URL NOT FOUND. REPO CHANGED? & pause & exit)
set "url=%url:*"https="https%"
exit /b

:download
echo Downloading latest THORIUM PORTABLE ...
CURL -L -o new.zip %url% || (echo error: DOWNLOAD FAILED & pause & exit)
cls
exit /b

:install
echo Unzipping THORIUM ...
tar -xf new.zip && del new.zip && if exist _bin/ rd /s /q _bin
echo ... SUCCESS!
exit /b

:brandnew
setlocal enabledelayedexpansion
choice /m "... THORIUM PORTABLE WILL BE INSTALLED. CONTINUE?"
if !ERRORLEVEL! EQU 2 exit
cls
set "a1=AVX2"
set "a2=AVX"
set "a3=SSE3"
echo:########   RELEASE TYPES   ########
echo: 1: %a1%    Most Intel/AMD CPUs since 2017
echo: 2: %a2%     Intel/AMD CPUs since 2012
echo: 3: %a3%    For CPUs that lack AVX. Generally CPUs older than 2012.
echo:
choice /C 123 /N /M ".. PICK ONE [1,2,3]: "
set "n=!a%ERRORLEVEL%!"
endlocal& set %~1=%n%
