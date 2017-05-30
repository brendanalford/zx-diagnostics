@echo off
echo Building ROMCheck program...
sjasmplus romcheck.sjasm  --lst=romcheck.lst --lstlab
if %errorlevel% neq 0 goto :end
echo Building tape image...
bin2tap -a 32768 -o romcheck_main.tap romcheck.bin
copy /b romcheck_loader.tap + romcheck_main.tap romcheck.tap
:end

exit /b errorlevel
