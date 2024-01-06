@echo off
echo ************************
echo Building Diagboard stuff
echo ************************
call builddiag.bat
if %errorlevel% neq 0 goto :error
echo *****************
echo Building Main ROM
echo *****************
echo.
git rev-parse --abbrev-ref HEAD > branch.txt
git rev-parse --short HEAD > commit.txt
call buildmain.bat
if %errorlevel% neq 0 goto :error
rem echo.
rem echo *****************
rem echo Building SLAM ROM
rem echo *****************
rem echo.
rem call buildslam.bat
rem if %errorlevel% neq 0 goto :error
cd FlashUtils
echo.
echo **********************
echo Building FLASH Utility
echo **********************
echo.
call build.bat
if %errorlevel% neq 0 goto :cderror
cd ..\TestTape
echo.
echo *************************
echo Building tape based tests
echo *************************
echo.
call build.bat
if %errorlevel% neq 0 goto :cderror
cd ..\Spectranet
echo.
echo ********************************
echo Building Spectranet test modules
echo ********************************
echo.
call build.bat
if %errorlevel% neq 0 goto :cderror
cd ..\ROMCheck
echo.
echo ****************************
echo Building ROM Checker utility
echo ****************************
echo.
call build.bat
cd ..
if %errorlevel% neq 0 goto :cderror
echo All builds complete.
goto :done

:cderror

cd ..

:error

echo Aborting main build.

:done
REM
REM These are used to pass various binary/tape images to an emulator for testing. They can be 
REM modified based on your own chosen emulator or workflow.
REM 
REM curl --request POST --data-binary "@testrom.bin" "http://localhost:49152/services/media/bin?autostart=true&isDiagnosticRom=true"
REM curl --request POST --data-binary "@TestTape/testram.tap" "http://localhost:49152/services/media/tap?autostart=true"
curl --request POST --data-binary "@ROMCheck/romcheck.tap" "http://localhost:49152/services/media/tap?autostart=true"