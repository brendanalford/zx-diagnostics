@echo off
echo Building Test ROM...
sjasmplus testrommain.sjasm --lst=testrommain.lst --lsttab
if %errorlevel% neq 0 goto :end
echo Building Bootstrap...
sjasmplus testrom.sjasm --lst=testrom.lst --lsttab
if %errorlevel% neq 0 goto :end
echo Building tape image...
bin2tap -a 32768 -o testrom.tap testrom.bin
:end
del testrommain.bin
exit /b errorlevel
