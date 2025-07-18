:: install_lamalib
:: an MSDOS batch file (runs on Windows) to reassemble all parts of the library for the LAMAlib project
:: and to install it in cc65 
::
:: Usage: install_lamalib
:: cc65 tools need to be installed on your system and to be in your path
::
:: Version: 0.3
:: Date: 2021-04-04
:: Author: Wil Elmenreich (wilfried at gmx dot at)
:: License: The Unlicense (public domain)

@echo off
setlocal ENABLEDELAYEDEXPANSION

echo Assembling and linking all LAMAlib modules...

:: Define some useful colorcode vars
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem "') do set "ESCchar=%%E"

set "red=%ESCchar%[91m"
set "green=%ESCchar%[92m"
set "yellow=%ESCchar%[93m"
set "magenta=%ESCchar%[95m"
set "cyan=%ESCchar%[96m"
set "white=%ESCchar%[97m"
set "black=%ESCchar%[30m"
set "nocolor=%ESCchar%[0m"
set "bold=%ESCchar%[1m"

where cc65.exe >nul
if errorlevel 1 (
  echo %red%cc65 installation not found. Please install cc65 and run this script again^^!%nocolor%
  pause
  exit /b
)

cd lib-functions
set count=1
set "o_files="
for %%f in (*.s) do (
    ca65 -t c64 %%f
    set /a count+=1
    set "o_files=!o_files! %%~nf.o"
)

ca65 -tc64 systemdependencies.as -o systemaddresses_c64.o
ca65 -tc128 systemdependencies.as -o systemaddresses_c128.o
ca65 -tvic20 systemdependencies.as -o systemaddresses_vc20.o

ar65 a LAMAlib.lib !o_files! systemaddresses_c64.o
ar65 a LAMAlib128.lib !o_files! systemaddresses_c128.o
ar65 a LAMAlib20.lib !o_files! systemaddresses_vc20.o

move /y LAMAlib*.lib ..

echo Library has been created with %count% modules in it.
cd ..

:: find cc65 directory
for /F %%I in ('where cc65.exe') do (
  for %%J in ("%%I\..\..") do set "CC65PATH=%%~fJ"
)

@copy LAMAlib*.inc "%CC65PATH%\asminc"
@xcopy /e /i /y "modules" "%CC65PATH%\asminc\modules\"
@copy LAMAlib.lib "%CC65PATH%\lib"
@copy LAMAlib128.lib "%CC65PATH%\lib"
@copy LAMAlib20.lib "%CC65PATH%\lib"
@copy *friendly-asm.cfg "%CC65PATH%\cfg"
@copy ass.bat "%CC65PATH%\bin"


echo %white%
echo *********************************************************************************************
echo * Congratulations, LAMAlib has been installed^^!                                              *
echo *                                                                                           *
echo * To use it, add the line %cyan%.include "LAMAlib.inc"%white% at the top of your assembler file          *
echo * and assemble with command %cyan%cl65 yourprog.s -lib LAMAlib.lib -C c64-asm.cfg -o yourprog.prg%white% *
echo * or rather simpler with %cyan%ass yourprog.prg%white%                                                   *
echo * There is no overhead to your assembled program for unused functions.                      *
echo *********************************************************************************************%nocolor%

IF /I %0 EQU "%~dpnx0" PAUSE