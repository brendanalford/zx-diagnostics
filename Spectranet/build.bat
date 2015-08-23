@echo off
echo Building Spectranet Test ROM module...
sjasmplus testmodule.sjasm
sjasmplus testmodule2.sjasm
echo Building tape images...
bin2tap -a 32768 -o testmodule.tap testmodule.bin
bin2tap -a 32768 -o testmodule2.tap testmodule2.bin
echo Done!
