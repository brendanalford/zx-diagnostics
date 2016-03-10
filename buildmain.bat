@echo off
echo Building Test ROM...
sjasmplus testrom.sjasm
if %errorlevel% neq 0 goto :end
echo Building tape image...
bin2tap -a 32768 -o testrom.tap testrom.bin

:end

exit /b errorlevel
