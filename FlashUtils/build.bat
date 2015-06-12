@echo off
echo Building Flash Utility...
sjasmplus flashutil.sjasm
sjasmplus flashutilrom.sjasm
echo Building tape images...
bin2tap -o flashutil.tap -a 57344 flashutil.bin
bin2tap -o flashutilrom.tap -a 32768 flashutilrom.bin
echo Done.
