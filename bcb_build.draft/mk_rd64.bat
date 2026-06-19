@echo off
setlocal

:: 1. Сохраняем аргумент в уникальную переменную MY_CONFIG
set "MY_CONFIG=%~1"

:: 2. Выбор конфигурации
if "%MY_CONFIG%"=="" goto :DO_RELEASE
if /i "%MY_CONFIG%"=="release" goto :DO_RELEASE
if /i "%MY_CONFIG%"=="debug" goto :DO_DEBUG
goto :DO_RELEASE

:DO_DEBUG
set "BUILD_TYPE=Debug"
:: --- КЛЮЧИ CLANG ДЛЯ ОТЛАДКИ (Win64) ---
:: -O0       : Полностью отключить оптимизацию кода
:: -g        : Сгенерировать отладочные символы DWARF/CodeView
:: -fno-inline : Отключить инлайнинг функций (чтобы дебаггер не терял переменные)
:: -D_DEBUG  : Макрос отладки
set "COMPILER_FLAGS=-O0 -g -fno-inline -D_DEBUG"
goto :MAIN_BUILD

:DO_RELEASE
set "BUILD_TYPE=Release"
:: --- КЛЮЧИ CLANG ДЛЯ РЕЛИЗА (Win64) ---
:: -O3       : Максимальная скорость Clang оптимизации
:: -finline-functions : Разрешить инлайнинг для ускорения
:: -DNDEBUG  : Отключить ассерты
set "COMPILER_FLAGS=-O3 -finline-functions -DNDEBUG"
goto :MAIN_BUILD


:MAIN_BUILD
echo ====================================
echo Building Win64 Configuration: %BUILD_TYPE%
echo Flags: %COMPILER_FLAGS%
echo ====================================

:: Базовые пути БЕЗ кавычек

SET "PRJDIR=E:\NewQDB\GIT\draft"
SET "OUTDIR=E:\NewQDB\GIT\draft\bcb_build.draft\Win64\%BUILD_TYPE%"

:: Прописываем жесткие пути к bin64, чтобы избежать конфликтов кавычек при вызове
SET "BCBENV64=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin64\rsvars64.bat"
SET "COMPILER=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin64\bcc64x.exe"
SET "LLVM_LIB=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin64\llvm-lib.exe"

:: Проверяем и создаем подпапки
if not exist "%OUTDIR%\TEMP" mkdir "%OUTDIR%\TEMP"
if not exist "%OUTDIR%\LIB" mkdir "%OUTDIR%\LIB"

cd /d "%PRJDIR%"
call "%BCBENV64%"
del /f /q *.o *.obj mdbx.lib 2>nul

:: Компиляция mdbx.c (обратите внимание на выходное расширение .o для Clang)
"%COMPILER%" -c -I. %COMPILER_FLAGS% ^
-std=c11 ^
-DMDBX_WITHOUT_MSVC_CRT=1 ^
-DMDBX_BUILD_CXX=1 ^
-DMDBX_BUILD_SHARED_LIBRARY=0 ^
-DMDBX_MANUAL_MODULE_HANDLER=0 ^
-DMDBX_BUILD_FLAGS="\"bcc64x Win64 %BUILD_TYPE%\"" ^
"%PRJDIR%\mdbx.c" -o "%OUTDIR%\TEMP\mdbx.o"

@echo on
:: Компиляция mdbx.c++
"%COMPILER%" -c -I. %COMPILER_FLAGS% ^
-DMDBX_WITHOUT_MSVC_CRT=1 ^
-DMDBX_BUILD_CXX=1 ^
-DMDBX_BUILD_SHARED_LIBRARY=0 ^
-DMDBX_MANUAL_MODULE_HANDLER=0 ^
-DMDBX_BUILD_FLAGS="\"bcc64x Win64 %BUILD_TYPE%\"" ^
"%PRJDIR%\mdbx.c++" -o "%OUTDIR%\TEMP\mdbxpp.o"

echo Creating 64-bit library mdbx.lib...
:: Утилита llvm-lib принимает файлы обычным списком аргументов через пробел
"%LLVM_LIB%" /OUT:"%OUTDIR%\LIB\mdbx.lib" "%OUTDIR%\TEMP\mdbx.o" "%OUTDIR%\TEMP\mdbxpp.o"
