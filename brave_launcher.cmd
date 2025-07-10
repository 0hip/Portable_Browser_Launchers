@ECHO OFF
SET "app=BRAVE"
SET "repo=api.github.com/repos/brave/brave-browser"
SET "_dl=CURL --connect-timeout 7 -s https://%repo%/releases/latest"
:: User data directory
SET "user_dir=USER_DATA"
:: https://peter.sh/experiments/chromium-command-line-switches/
SET "flags=--no-default-browser-check --disable-logging --disable-breakpad"
:: Solving "print preview failed" issue
rem SET "flags=%flags% --disable-features=PrintCompositorLPAC"

MODE CON: COLS=90 LINES=12 & COLOR 60
TITLE %app% PORTABLE LAUNCHER
CD /D "%~dp0"

SET "lnk=%1"
SET test="%~dp0%user_dir%\lockfile"
IF EXIST %test% (
   IF NOT DEFINED lnk SET "lnk=about:blank"
   GOTO newtab
)
SET "arch="
IF %PROCESSOR_ARCHITECTURE%==x86 SET "arch=ia32"
IF %PROCESSOR_ARCHITECTURE%==AMD64 SET "arch=x64"
IF %PROCESSOR_ARCHITECTURE%==ARM64 SET "arch=arm64"
IF NOT DEFINED arch (
   ECHO error: %PROCESSOR_ARCHITECTURE% CPU not suported
   PAUSE
   EXIT
) 
IF NOT EXIST BIN\ (
   ECHO FIRST TIME RUNNING %app% PORTABLE LAUNCHER ...
   CALL :brandnew
   CALL :getweb
   CALL :download
   CALL :unzip
   GOTO run
)
IF NOT EXIST "BIN\%app%.exe" (
   ECHO error: Current Version NOT A %app% RELEASE!
   ECHO Move %app% PORTABLE LAUNCHER to another folder and try again.
   PAUSE
   EXIT
)
IF EXIST new.zip (
   ECHO Applying the UPDATE ...
   GOTO resume
)
CALL :getweb
IF NOT DEFINED tag GOTO run
CALL :getlocal
ECHO: Arch   : %arch%
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
:run
CALL :cleanup
ECHO Launching %app% PORTABLE ...
:newtab
START "" "%~dp0BIN\%app%" --user-data-dir="%~dp0%user_dir%" %flags% %lnk%
IF NOT DEFINED lnk PING -n 3 127.0.0.1>NUL
EXIT


:getlocal
set "local=0"
for /f "delims=" %%G in (
   'dir /b /ad BIN ^| findstr /r /v [a-Z] ^| findstr /r \.'
)do set "local=%%G"
set "local=%local:*.=%"
exit /b

:getweb
set "tag="
set "url="
ping -n 1 github.com>nul || exit /b
echo: %arch% RELEASE : SEARCH FOR LATEST VERSION
for /f "delims=" %%G in (
   '%_dl% ^|find "browser_download_url" ^|find "win32-%arch%.zip" ^|find /v ".sha"'
)do set "url=%%G"
if defined url (
   call :url_tag
) else echo: %rel% RELEASE : NOT FOUND. REPO CHANGED? 
exit /b
:url_tag
set "url=%url:*"https="https%"
setlocal enabledelayedexpansion
set "_t=!url:*brave-v=!"
set "_t=!_t:-win32-%arch%.zip"=!"
endlocal& set tag=%_t%
exit /b

:download
if not defined url (
   pause
   exit
)
echo Downloading latest %app% PORTABLE ... %rel%
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
   echo %app% PORTABLE IS CURRENTLY RUNNING [BIN folder is being used]
   echo UPDATE will be applied on next LAUNCH!
   ping -n 5 127.0.0.1>nul
   exit
)
exit /b

:unzip
echo Unzipping %app% ...
md BIN
tar -xf new.zip -C BIN || (
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
rem call :cc "%~dp0%a%\Service Worker\"
rem call :cc "%~dp0%a%\File System\"
rem call :cc "%~dp0%a%\IndexedDB\"
exit /b
:cc
set "_="
if exist %1 (2>NUL rd /s /q %1 || set "_=NOT ")
echo %_%REMOVED: %1
exit /b

:brandnew
choice /m "... %app% PORTABLE WILL BE DOWNLOADED AND LAUNCHED. CONTINUE?"
if !ERRORLEVEL! EQU 2 exit
cls
