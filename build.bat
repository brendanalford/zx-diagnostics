@echo off
echo *****************
echo Building Main ROM
echo *****************
git rev-parse --abbrev-ref HEAD > branch.txt
git rev-parse --short HEAD > commit.txt
call buildmain.bat
echo *****************
echo Building SLAM ROM
echo *****************
call buildslam.bat
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
cd ..\Spectranet
echo ********************************
echo Building Spectranet test modules
echo ********************************
call build.bat
cd ..
echo All builds complete.
