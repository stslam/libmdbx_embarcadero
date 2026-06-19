@echo off
setlocal

:: 1. Сразу сохраняем аргумент в уникальную переменную MY_CONFIG
set "MY_CONFIG=%~1"

:: 2. Если параметр пустой или равен release, жестко идем на ветку Релиза
if "%MY_CONFIG%"=="" goto :DO_RELEASE
if /i "%MY_CONFIG%"=="release" goto :DO_RELEASE

:: 3. Если написали debug, идем на ветку Дебага
if /i "%MY_CONFIG%"=="debug" goto :DO_DEBUG

:: Если ввели что-то непонятное, по умолчанию делаем Релиз
goto :DO_RELEASE

:DO_DEBUG
set "BUILD_TYPE=Debug"
:: --- ПРАВИЛЬНЫЕ КЛЮЧИ EMBARCADERO ДЛЯ ОТЛАДКИ ---
:: -Od   : Отключить оптимизацию (вместо -O0)
:: -v    : Включить отладочную информацию в OBJ
:: -vi-  : Отключить инлайнинг функций
:: -D_DEBUG : Макрос отладки
set "COMPILER_FLAGS=-Od -v -vi- -D_DEBUG"
goto :MAIN_BUILD

:DO_RELEASE
set "BUILD_TYPE=Release"
:: --- ПРАВИЛЬНЫЕ КЛЮЧИ EMBARCADERO ДЛЯ РЕЛИЗА ---
:: -O2   : Максимальная оптимизация по скорости
:: -vi   : Включить инлайнинг функций
:: -DNDEBUG : Отключить отладочный код
set "COMPILER_FLAGS=-O2 -vi -DNDEBUG"
goto :MAIN_BUILD

:MAIN_BUILD
echo ====================================
echo Building Configuration: %BUILD_TYPE%
echo Flags: %COMPILER_FLAGS%
echo ====================================

:: Базовые пути БЕЗ кавычек
SET "PRJDIR=E:\NewQDB\GIT\draft"
SET "OUTDIR=E:\NewQDB\GIT\draft\bcb_build.draft\Win32\%BUILD_TYPE%"

SET "BCBENV32=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
SET "COMPILER=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\bcc32c.exe"
SET "TLIB=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\tlib.exe"

:: Проверяем и создаем подпапки
if not exist "%OUTDIR%\TEMP" mkdir "%OUTDIR%\TEMP"
if not exist "%OUTDIR%\LIB" mkdir "%OUTDIR%\LIB"

cd /d "%PRJDIR%"
call "%BCBENV32%"
del /f /q *.obj mdbx.lib 2>nul

:: Компиляция mdbx.c
"%COMPILER%" -c -I. %COMPILER_FLAGS% ^
-std=c11 ^
-DMDBX_WITHOUT_MSVC_CRT=1 ^
-DMDBX_BUILD_CXX=1 ^
-DMDBX_BUILD_SHARED_LIBRARY=0 ^
-DMDBX_MANUAL_MODULE_HANDLER=0 ^
-DMDBX_BUILD_FLAGS="\"bcc32c Win32 %BUILD_TYPE%\"" ^
"%PRJDIR%\mdbx.c" -o "%OUTDIR%\TEMP\mdbx.obj"

@echo on
:: Компиляция mdbx.c++
"%COMPILER%" -c -I. %COMPILER_FLAGS% ^
-DMDBX_WITHOUT_MSVC_CRT=1 ^
-DMDBX_BUILD_CXX=1 ^
-DMDBX_BUILD_SHARED_LIBRARY=0 ^
-DMDBX_MANUAL_MODULE_HANDLER=0 ^
-DMDBX_BUILD_FLAGS="\"bcc32c Win32 %BUILD_TYPE%\"" ^
"%PRJDIR%\mdbx.c++" -o "%OUTDIR%\TEMP\mdbxpp.obj"

echo Creating library mdbx.lib from mdbx.obj...
"%TLIB%" /C "%OUTDIR%\LIB\mdbx.lib" +"%OUTDIR%\TEMP\mdbx.obj" +"%OUTDIR%\TEMP\mdbxpp.obj"
