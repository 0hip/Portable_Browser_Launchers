@ECHO OFF
SET "repo=/Alex313031/Thorium-Win"
SET "user_dir=USER_DATA"
SET "flags=--no-default-browser-check --disable-logging --disable-breakpad"

MODE CON: COLS=90 LINES=12 & COLOR 9F
TITLE THORIUM PORTABLE LAUNCHER
CD /D "%~dp0"

SET test="%~dp0%user_dir%\Default\Cache\Cache_Data\index"
IF EXIST %test% (
   2>NUL (TYPE NUL>%test%) || (
      ECHO THORIUM PORTABLE CURRENTLY RUNNING ?
      GOTO norun
   )
)
IF NOT EXIST BIN\ (
   ECHO FIRST TIME RUNNING THORIUM PORTABLE LAUNCHER ...
   CALL :brandnew rel
   CALL :getweb
   CALL :download
   CALL :unzip
   CALL :run
)
IF EXIST new.zip (
   ECHO Applying the UPDATE ...
   GOTO resume
)
IF NOT EXIST "BIN\thor_ver" (
   ECHO error: Current Version NOT A THORIUM RELEASE!
   ECHO Move THORIUM PORTABLE LAUNCHER to another folder and try again.
   PAUSE
   EXIT
)
SET "rel=none"
SET /P rel=<"BIN\thor_ver"
SET "rel=%rel:*-=%"
IF %rel%==Win SET "rel=AVX" 
ECHO .. RELEASE TYPE: %rel%
CALL :getlocal
ECHO current version: %local%
CALL :getweb
ECHO _latest version: %tag%
IF %local%==%tag% (
   ECHO No new version found ...
   GOTO run
)
ECHO NEW VERSION FOUND!
CALL :download
:resume
ECHO Backup BIN TO _BIN ...
2>NUL (MOVE /Y BIN _BIN >NUL) || (
   ECHO THORIUM PORTABLE IS CURRENTLY RUNNING [BIN folder is being used]
   ECHO Will apply the UPDATE on the next LAUNCH!
   PING -n 5 127.0.0.1>NUL
   EXIT
)
CALL :unzip
:run
CALL :cleanup
ECHO Starting THORIUM PORTABLE ...
START "" "%~dp0BIN\Thorium" --user-data-dir="%~dp0%user_dir%" %flags%
:norun
PING -n 3 127.0.0.1>NUL
EXIT


:getlocal
set "local=0"
for /f "delims=" %%G in (
   'dir /b /ad BIN ^| findstr /r /v [a-Z] ^| findstr /r \.'
)do set "local=%%G"
exit /b

:getweb
type nul>latest || (
   echo error: NO WRITE ACCESS
   pause
   exit
)
CURL -s https://api.github.com/repos%repo%/releases/latest>latest
:: VERSION TAG
set "tag="
for /f "delims=" %%G in (
   'type latest ^|find /i "tag_name"'
)do set "tag=%%G"
if not defined tag (
   echo error: NOTHING FOUND! REPO CHANGED?
   pause
   exit
)
set "tag=%tag:*"M=%"
set "tag=%tag:",=%"
:: DOWNLOAD URL
set "url="
for /f "delims=" %%G in (
   'type latest ^|find "browser_download_url" ^|find "_%rel%_" ^|find ".zip"'
)do set "url=%%G"
if not defined url (
   echo error: DOWNLOAD URL NOT FOUND. REPO CHANGED?
   pause
   exit
)
set "url=%url:*"https="https%"
del latest
exit /b

:download
echo Downloading latest THORIUM PORTABLE ...
CURL -L -o new.zip %url% || (
   echo error: DOWNLOAD FAILED
   pause
   exit
)
cls
exit /b

:unzip
echo Unzipping THORIUM ...
tar -xf new.zip || (
   echo error: UNZIP failed. Corrupted ZIP file ? ... Cleaning up ...
   del new.zip
   if exist BIN/ rd /s /q BIN
   if exist _BIN/ (
      echo Restoring backup ...
      move /y _BIN BIN
      exit /b
   )
   exit
)
if exist _BIN/ rd /s /q _BIN
del new.zip
echo ... SUCCESS!
exit /b

:cleanup
set "a=%user_dir%\Default"
:: CACHE CLEANING
REM call :cc "%~dp0%a%\Cache\"
REM call :cc "%~dp0%a%\Code Cache\"
:: FURTHER CLEANING
REM call :cc "%~dp0%a%\IndexedDB\"
REM call :cc "%~dp0%a%\Service Worker\"
REM call :cc "%~dp0%a%\File System\"
:: GET RID OF thorium_shell.exe
REM set shell="%~dp0bin\%local%\thorium_shell.exe"
REM if exist %shell% (del %shell% & echo deleted %shell%)
exit /b
:cc
if exist %1 (rd /s /q %1 && echo removed %1)
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
