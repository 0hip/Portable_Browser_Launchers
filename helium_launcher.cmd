:: https://github.com/imputnet/helium-windows
::
@ECHO OFF
SET "app=chrome.exe"
SET "repo=api.github.com/repos/imputnet/helium-windows"
SET "_dl=curl.exe --connect-timeout 7 -s https://%repo%/releases/latest"
::
:: https://peter.sh/experiments/chromium-command-line-switches/
:: User data directory
SET "user_dir=%USERNAME%_DATA"
:: Basic flags
SET "flags=--no-default-browser-check --disable-logging --disable-breakpad"
:: Flags to make Helium truly "PORTABLE"
SET "flags=%flags% --disable-encryption --disable-machine-id" & SET "user_dir=USER_DATA"

MODE CON: COLS=90 LINES=12 & COLOR 17
TITLE Helium PORTABLE LAUNCHER
CD /D "%~dp0"

SET "arch="
IF %PROCESSOR_ARCHITECTURE%==AMD64 SET "arch=x64"
IF %PROCESSOR_ARCHITECTURE%==ARM64 SET "arch=arm64"
IF NOT DEFINED arch (
   ECHO error: %PROCESSOR_ARCHITECTURE% CPU not suported
   PAUSE
   EXIT
) 
SET "BIN="
FOR /f "delims=" %%G IN (
   'dir /b /ad ^| find "helium_" ^| find "_%arch%-windows"'
)DO SET "BIN=%%G"

SET "lnk=%1"
SET test="%~dp0%user_dir%\lockfile"
IF EXIST %test% (
   IF NOT DEFINED lnk SET "lnk=about:blank"
   GOTO newtab
)
IF NOT DEFINED BIN (
   ECHO FIRST TIME RUNNING Helium PORTABLE LAUNCHER ...
   CALL :brandnew
   CALL :getweb
   CALL :download
   CALL :unzip
   GOTO run
)
IF NOT EXIST "%BIN%\%app%" (
   ECHO error: Current Version NOT A Helium RELEASE!
   ECHO Move "helium_launcher.cmd" to another folder and try again.
   PAUSE
   EXIT
)
IF EXIST new.zip (
   ECHO Applying the UPDATE ...
   GOTO resume
)
CALL :getweb
IF NOT DEFINED tag GOTO run
ECHO: Current: %BIN%
ECHO: Latest : %tag%
ECHO: . . .
IF %BIN%==%tag% GOTO run
ECHO: NEW VERSION FOUND!
CALL :download
:resume
CALL :backup
CALL :unzip
:run
CALL :cleanup
ECHO Launching Helium PORTABLE ...
:newtab
START "" "%~dp0%BIN%\%app%" --user-data-dir="%~dp0%user_dir%" %flags% %lnk%
IF NOT DEFINED lnk ping.exe -n 3 127.0.0.1>NUL
EXIT


:getweb
set "tag="
set "url="
ping.exe -n 1 github.com>nul || exit /b
echo: SEARCH FOR LATEST VERSION
for /f "delims=" %%G in (
   '%_dl% ^|find "browser_download_url" ^|find "_%arch%-windows.zip"'
)do set "url=%%G"
if defined url (
   call :url_tag
) else echo: RELEASE : NOT FOUND. REPO CHANGED? 
exit /b
:url_tag
set "url=%url:*"https="https%"
setlocal enabledelayedexpansion
set "_t=!url:*/helium_=helium_!"
set "_t=!_t:.zip"=!"
endlocal& set tag=%_t%
exit /b

:download
if not defined url (
   pause
   exit
)
echo Downloading latest Helium PORTABLE ...
curl.exe -L -o new.zip %url% || (
   echo error: DOWNLOAD FAILED
   pause
   exit
)
cls
exit /b

:backup
echo Backup %BIN% TO _%BIN% ...
move /Y %BIN% _%BIN% >nul 2>&1 || (
   echo Helium PORTABLE IS CURRENTLY RUNNING [%BIN% folder is being used]
   echo UPDATE will be applied on next LAUNCH!
   ping.exe -n 5 127.0.0.1>nul
   exit
)
exit /b

:unzip
echo Extracting Helium ...
tar.exe -xf new.zip || (
   echo error: Extract failed. Corrupt zip file ? ... Cleaning up ...
   del new.zip
   if exist %tag%\ rd /s /q %tag%
   if exist _%BIN%\ (
      echo Restoring backup ...
      move /y _%BIN% %BIN%
      exit /b
   )
   exit
)
if exist _%BIN%\ rd /s /q _%BIN%
del new.zip
set "BIN=%tag%"
echo ... SUCCESS!
exit /b

:cleanup
set "a=%user_dir%\Default"
:: CACHE CLEANING
call :cc "%~dp0%a%\Cache\"
call :cc "%~dp0%a%\Code Cache\"
:: FURTHER CLEANING
call :cc "%~dp0%a%\Service Worker\"
call :cc "%~dp0%a%\File System\"
rem call :cc "%~dp0%a%\IndexedDB\"
exit /b
:cc
set "_="
if exist %1 (2>NUL rd /s /q %1 || set "_=NOT ")
echo %_%REMOVED: %1
exit /b

:brandnew
choice.exe /m "... Helium PORTABLE WILL BE DOWNLOADED AND LAUNCHED. CONTINUE?"
if %ERRORLEVEL% EQU 2 exit
cls
