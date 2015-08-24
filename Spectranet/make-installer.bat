@echo off
REM Spectranet module installer v1.0 by Guesser
REM modified to use bin2tap instead of bin2tape for zx-diagnostics
if not exist "%~n1%~x1" goto filenotfound
if not "%~x1"==".module" goto notamodule
if %~z1 GTR 4096 goto filetoobig

bin2tap.exe "%~n1%~x1" -o module.tap -a 36864
copy /b "%~d0%~p0installer-dist" + module.tap %~n1.pkg > NUL
del module.tap
echo load installer with '%%tapein %~n1.pkg' and 'LOAD ""'
goto :EOF

:filenotfound
echo file not found
goto :EOF

:notamodule
echo not a .module file
goto :EOF

:filetoobig
echo file is greater than 4kB
goto :EOF