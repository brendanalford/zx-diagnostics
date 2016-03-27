@echo off
echo Building main test...
sjasmplus testrammain.sjasm  --lst=testrammain.lst --lstlab 
if %errorlevel% neq 0 goto :end
echo Building bootstrap...
sjasmplus testram.sjasm  --lst=testram.lst --lstlab
if %errorlevel% neq 0 goto :end
echo Creating tape image...
..\bin2tap -b -a 24500 -c 24499 -r 24500 testram.bin
echo Build complete.
copy /y testram.bin bin
copy /y testram.tap bin
echo Binaries copied to bin directory.

:end

exit /b errorlevel
