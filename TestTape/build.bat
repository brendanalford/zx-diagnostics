@echo off
echo Building main test...
sjasmplus testrammain.sjasm
echo Building bootstrap...
sjasmplus testram.sjasm
echo Creating tape image...
..\bin2tap -b -a 24500 -c 24499 -r 24500 testram.bin
echo Build complete.
copy /y testram.bin bin
copy /y testram.tap bin
echo Binaries copied to bin directory.
