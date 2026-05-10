@echo off
:: NAS Transfer (Windows)
:: Drop files or folders onto this script to copy them to the NAS media share.
::
:: Setup:
::   1. Map the NAS share to a drive letter in File Explorer:
::      Right-click "This PC" -> Map network drive
::      Drive: Z:
::      Folder: \\<your-nas-ip>\media
::      Check "Reconnect at sign-in" and "Connect using different credentials"
::      Enter your Samba username and password.
::   2. Edit the DEST line below if you mapped to a letter other than Z:.
::   3. Drag any file or folder onto this .bat to transfer it.
::
:: Robocopy is built into Windows since Vista. It handles large SMB transfers
:: reliably, retries on failure, and resumes interrupted copies.

setlocal EnableDelayedExpansion

:: ---- Configuration ----------------------------------------------------------
:: Destination drive (mapped network drive) or UNC path.
:: Examples:
::   set "DEST=Z:\"
::   set "DEST=\\192.168.1.100\media\"
set "DEST=Z:\"

:: -----------------------------------------------------------------------------

if "%~1"=="" (
  echo.
  echo NAS Transfer
  echo ============
  echo Drag files or folders onto this script to copy them to the NAS.
  echo Current destination: %DEST%
  echo.
  pause
  exit /b
)

if not exist "%DEST%" (
  echo.
  echo ERROR: Destination "%DEST%" is not reachable.
  echo The mapped drive may have disconnected, or the NAS is offline.
  echo Reconnect the network drive in File Explorer and try again.
  echo.
  pause
  exit /b 1
)

echo.
echo Starting transfer to %DEST%
echo.

:loop
if "%~1"=="" goto done
if exist "%~1\*" (
  rem Folder: copy contents recursively into a same-named subfolder on the NAS
  robocopy "%~1" "%DEST%%~n1" /E /Z /R:3 /W:5 ^
    /XF .DS_Store ._* desktop.ini Thumbs.db ^
    /XD .Spotlight-V100 .Trashes
) else (
  rem Single file
  robocopy "%~dp1." "%DEST%" "%~nx1" /Z /R:3 /W:5
)
shift
goto loop

:done
echo.
echo Transfer complete.
timeout /t 5
endlocal
