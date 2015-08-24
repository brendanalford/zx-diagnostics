@echo off
echo Building Spectranet Test ROM module...
sjasmplus testmodule.sjasm
sjasmplus testmodule2.sjasm
echo make installers...
call make-installer.bat testmodule.module
call make-installer.bat testmodule2.module
echo Done!
