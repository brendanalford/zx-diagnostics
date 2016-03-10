@echo off
echo *****************
echo Building Main ROM
echo *****************
echo.
git rev-parse --abbrev-ref HEAD > branch.txt
git rev-parse --short HEAD > commit.txt
call buildmain.bat
if %errorlevel% neq 0 goto :error
echo.
echo *****************
echo Building SLAM ROM
echo *****************
echo.
call buildslam.bat
if %errorlevel% neq 0 goto :error
cd FlashUtils
echo.
echo **********************
echo Building FLASH Utility
echo **********************
echo.
call build.bat
cd ..\TestTape
if %errorlevel% neq 0 goto :error
echo.
echo *************************
echo Building tape based tests
echo *************************
echo.
call build.bat
if %errorlevel% neq 0 goto :error
cd ..\Spectranet
echo.
echo ********************************
echo Building Spectranet test modules
echo ********************************
echo.
call build.bat
cd ..
if %errorlevel% neq 0 goto :error
echo All builds complete.
goto :done

:error

echo Aborting main build.

:done
