@echo off
echo Building Spectranet Test ROM module...
sjasmplus testmodule1.sjasm
sjasmplus testmodule2.sjasm
echo make installers...
call make-installer.bat testmodule1.module
call make-installer.bat testmodule2.module
echo Done!
