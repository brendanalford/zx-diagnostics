@echo off
echo *****************
echo Building Main ROM
echo *****************
call build.bat
cd FlashUtils
echo **********************
echo Building FLASH Utility
echo **********************
call build.bat
cd ..\TestTape
echo *************************
echo Building tape based tests
echo *************************
call build.bat
cd ..
echo All builds complete.