@echo off
echo ==================================================
echo STARTING FULL BUILD (Win32/Win64 - Debug/Release)
echo ==================================================

echo [1/4] Building Win32 Debug...
call mk_rd.bat debug

echo [2/4] Building Win64 Debug...
call mk_rd64.bat debug

echo [3/4] Building Win32 Release...
call mk_rd.bat release

echo [4/4] Building Win64 Release...
call mk_rd64.bat release

echo ==================================================
echo ALL BUILDS COMPLETED SUCCESSFULLY!
echo ==================================================
pause
