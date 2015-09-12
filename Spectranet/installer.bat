@echo off
echo Building Spectranet Test ROM installer...
sjasmplus testmodule1.sjasm
sjasmplus testmodule2.sjasm
echo make installers...
sjasmplus installer.sjasm
bin2tap -a 32768 -b -c 32767 -o installer.tap installer.bin
copy installer.tap "x:\Spectrum Games + Docs\i.tap"
echo Done!
