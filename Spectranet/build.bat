@echo off
echo Building Spectranet Test ROM module...
sjasmplus testmodule1.sjasm
sjasmplus testmodule2.sjasm
echo Building installer...
sjasmplus installer.sjasm
bin2tap -a 32768 -b -c 32767 -o installer.tap installer.bin
echo Done!