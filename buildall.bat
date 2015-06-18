@echo off
echo Building all...
call build.bat
cd FlashUtils
call build.bat
cd ..\TestTape
call build.bat
cd ..
echo All builds complete.