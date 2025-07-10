@ECHO OFF
SET "repo=api.github.com/repos/Alex313031/Thorium-Win"
SET "_dl=CURL --connect-timeout 7 -s https://%repo%/releases/latest"
:: User data directory
SET "user_dir=USER_DATA"
:: https://peter.sh/experiments/chromium-command-line-switches/
SET "flags=--no-default-browser-check --disable-logging --disable-breakpad"
:: Solving "print preview failed" issue
SET "flags=%flags% --disable-features=PrintCompositorLPAC"

MODE CON: COLS=90 LINES=12 & COLOR 9F
TITLE THORIUM PORTABLE LAUNCHER
CD /D "%~dp0"

SET "lnk=%1"
SET test="%~dp0%user_dir%\lockfile"
IF EXIST %test% (
   IF NOT DEFINED lnk SET "lnk=about:blank"
   GOTO newtab
)
IF NOT EXIST BIN\ (
   ECHO FIRST TIME RUNNING THORIUM PORTABLE LAUNCHER ...
   CALL :brandnew
   CALL :unzip
   CALL :getlocal
   GOTO run
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
CALL :getweb
IF NOT DEFINED tag GOTO run
CALL :getlocal
ECHO: Release: %rel%
ECHO: Current: %local%
ECHO: Latest : %tag%
IF %local%==%tag% (
   ECHO: . . .
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
:newtab
START "" "%~dp0BIN\Thorium" --user-data-dir="%~dp0%user_dir%" %flags% %lnk%
IF NOT DEFINED lnk PING -n 3 127.0.0.1>NUL
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
ping -n 1 github.com>nul || exit /b
echo: %rel% RELEASE : SEARCH FOR LATEST VERSION
for /f "delims=" %%G in (
   '%_dl% ^|find "browser_download_url" ^|find ".zip" ^|find "_%rel%_"'
)do set "url=%%G"
if defined url (
   call :url_tag
) else echo: %rel% RELEASE : NOT FOUND. REPO CHANGED? 
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
set shell="%~dp0bin\%local%\thorium_shell.exe"
:: CACHE CLEANING
call :cc "%~dp0%a%\Cache\"
call :cc "%~dp0%a%\Code Cache\"
:: FURTHER CLEANING
call :cc "%~dp0%a%\Service Worker\"
call :cc "%~dp0%a%\File System\"
rem call :cc "%~dp0%a%\IndexedDB\"
:: GET RID OF thorium_shell.exe
if exist %shell% (del %shell% && echo deleted %shell%)
exit /b
:cc
set "_="
if exist %1 (2>NUL rd /s /q %1 || set "_=NOT ")
echo %_%REMOVED: %1
exit /b

:brandnew
setlocal enabledelayedexpansion
choice /m "... THORIUM PORTABLE WILL BE DOWNLOADED AND LAUNCHED. CONTINUE?"
if !ERRORLEVEL! EQU 2 exit
cls
ping -n 1 github.com>nul || ( echo NO GITHUB RESPONSE & pause & exit )
echo ##########   PORTABLE RELEASE(S)   ##########
set "x=0"
set "a="
for /f "delims=" %%G in ('%_dl% ^|find "browser_download_url" ^|find ".zip"') do (
   set /a "x+=1"
   set "_u=%%G"
   set "u!x!=!_u:*"https="https!"
   set "_u=!_u:*/download/=!"
   set "_u=!_u:*/=!"
   set "_u=!_u:"=!"
   echo: !x!: !_u!
   set "a=!a!!x!"
)
set /a "x+=1"
set "a=!a!!x!"
echo: !x!: . . . I have URL (I know what I'm doing)
echo:
choice /c !a! /n /m ".. CHOOSE ONE: "
set "_x=%ERRORLEVEL%"
if !_x! EQU !x! (
   set /p "u!_x!=Paste URL here: " || exit /b
   set "_u=!u%_x%!"
   set "_u=!_u:"=!"
   if not "!_u:~-4!"==".zip" ( echo Invalid URL & pause & exit )
)
cls
set "_u=!u%_x%!"
set "_u=!_u:*/download/=!"
set "_u=!_u:*/="!"
echo: DOWNLOADING: !_u!
echo:
CURL -L -o new.zip !u%_x%!
endlocal
cls
