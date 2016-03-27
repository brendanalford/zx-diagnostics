@echo off
echo Building Flash Utility...
sjasmplus flashutil.sjasm  --lst=flashutil.lst --lstlab 
if %errorlevel% neq 0 goto :end
sjasmplus flashutilrom.sjasm  --lst=flashutilrom.lst --lstlab
if %errorlevel% neq 0 goto :end
echo Building tape images...
bin2tap -o flashutil.tap -a 57344 flashutil.bin
bin2tap -o flashutilrom.tap -a 32768 flashutilrom.bin

:end

exit /b errorlevel
