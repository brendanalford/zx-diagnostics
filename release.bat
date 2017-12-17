@echo off
echo Building release directory...
set /p Build=<branch.txt
set RelDir=Release-%Build%
rmdir /s /q %RelDir% >nul 2>&1
echo Creating %RelDir% folder...
md %RelDir%
md %RelDir%\TestTape
md %RelDir%\FlashUtils
md %RelDir%\ROMCheck

copy testrom.bin %RelDir% > nul
copy testrom.tap %RelDir% > nul

copy TestTape\testram.tap %RelDir%\TestTape > nul

copy ROMCheck\romcheck.tap %RelDir%\ROMCheck > nul
copy FlashUtils\flashutil.bin %RelDir%\FlashUtils > nul
copy FlashUtils\flashutil.tap %RelDir%\FlashUtils > nul
copy FlashUtils\flashutilrom.bin %RelDir%\FlashUtils > nul
copy FlashUtils\flashutilrom.tap %RelDir%\FlashUtils > nul

echo File copy complete.
echo.
echo Creating ZIP file %RelDir%.zip...
echo.
cd %RelDir%
zip -r -q ../%RelDir%.zip *
cd ..
echo Cleaning up...
rmdir /s /q %RelDir% >nul 2>&1
echo Done.
