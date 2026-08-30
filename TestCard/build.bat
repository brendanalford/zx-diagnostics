@echo off
echo Building main test...
sjasmplus testcard.sjasm  --lst=testcard.lst --lstlab
if %errorlevel% neq 0 goto :end
echo Creating tape image...
bin2tap -a 32768 -o testcard-data.tap testcard.bin
copy /b loader.tap + testcard-data.tap testcard.tap
echo Build complete.
copy /y testcard.bin bin
copy /y testcard.tap bin
echo Binaries copied to bin directory.

:end

exit /b errorlevel
