@echo off
echo Building Diagboard detection routines...
sjasmplus diagboard.sjasm
if %errorlevel% neq 0 goto :end
:end

exit /b errorlevel
