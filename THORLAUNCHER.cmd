@ECHO OFF
SET "repo=api.github.com/repos/Alex313031/Thorium-Win"
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
   CALL :getlocal
   CALL :run
)
IF NOT EXIST "BIN\thor_ver" (
   ECHO error: Current Version NOT A THORIUM RELEASE!
   ECHO Move THORIUM PORTABLE LAUNCHER to another folder and try again.
   PAUSE
   EXIT
)
IF EXIST new.zip (
   ECHO Applying the UPDATE ...
   GOTO resume
)
SET "rel="
FOR /f "skip=1" %%G IN (BIN\thor_ver) DO IF NOT DEFINED rel SET "rel=%%G"
ECHO: CHECK FOR UPDATE ...
CALL :getweb
IF NOT DEFINED tag GOTO run
CALL :getlocal
ECHO: Release: %rel%
ECHO: Current: %local%
ECHO: Latest : %tag%
IF %local%==%tag% (
   ECHO: NO NEW VERSION FOUND
   GOTO run
)
ECHO: NEW VERSION FOUND!
CALL :download
:resume
CALL :backup
CALL :unzip
CALL :getlocal
:run
CALL :cleanup
ECHO Launching THORIUM PORTABLE ...
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
set "tag="
set "url="
set "_dl=CURL --connect-timeout 7 -s https://%repo%/releases/latest"
for /f "delims=" %%G in (
   '%_dl% ^|find "browser_download_url" ^|find ".zip" ^|find "_%rel%_"'
)do set "url=%%G"
if defined url (
   call :url_tag
) else echo error: DOWNLOAD URL NOT FOUND. REPO CHANGED? 
exit /b
:url_tag
set "url=%url:*"https="https%"
setlocal enabledelayedexpansion
set "_t=!url:*_%rel%_=!"
endlocal& set tag=%_t%
set "tag=%tag:.zip"=%"
exit /b

:download
if not defined url (
   pause
   exit
)
echo Downloading latest THORIUM PORTABLE ... %rel%
CURL -L -o new.zip %url% || (
   echo error: DOWNLOAD FAILED
   pause
   exit
)
cls
exit /b

:backup
echo Backup BIN TO _BIN ...
2>nul (move /Y BIN _BIN >nul) || (
   echo THORIUM PORTABLE IS CURRENTLY RUNNING [BIN folder is being used]
   echo UPDATE will be applied on next LAUNCH!
   ping -n 5 127.0.0.1>nul
   exit
)
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
rem call :cc "%~dp0%a%\Cache\"
rem call :cc "%~dp0%a%\Code Cache\"
:: FURTHER CLEANING
rem call :cc "%~dp0%a%\IndexedDB\"
rem call :cc "%~dp0%a%\Service Worker\"
rem call :cc "%~dp0%a%\File System\"
:: GET RID OF thorium_shell.exe
set shell="%~dp0bin\%local%\thorium_shell.exe"
rem if exist %shell% (del %shell% && echo deleted %shell%)
exit /b
:cc
if exist %1 (rd /s /q %1 && echo removed %1)
exit /b

:brandnew
setlocal enabledelayedexpansion
choice /m "... THORIUM PORTABLE WILL BE DOWNLOADED AND LAUNCHED. CONTINUE?"
if !ERRORLEVEL! EQU 2 exit
cls
set "a1=AVX2"
set "a2=AVX"
set "a3=SSE3"
echo:########   RELEASE TYPES   ########
echo: 1: %a1%    For most Intel/AMD CPUs since 2017.
echo: 2: %a2%     For Intel/AMD CPUs since 2012.
echo: 3: %a3%    For CPUs that lack AVX. Generally CPUs older than 2012.
echo:
choice /C 123 /N /M ".. CHOOSE ONE [1,2,3]: "
set "n=!a%ERRORLEVEL%!"
endlocal& set %~1=%n%
