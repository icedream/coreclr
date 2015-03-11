@echo off
rem
rem This file invokes cmake and generates the build system for windows.

set argC=0
for %%x in (%*) do Set /A argC+=1

if NOT %argC%==1 GOTO :USAGE
if %1=="/?" GOTO :USAGE

setlocal
set basePath=%~dp0
:: remove quotes
set "basePath=%basePath:"=%"

:: remove trailing slash
if %basePath:~-1%==\ set "basePath=%basePath:~0,-1%"

if defined CMakePath goto DoGen

:: Eval the output from probe-win1.ps1
for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy RemoteSigned "& .\probe-win.ps1"') do %%a

:DoGen
if /i "%__BuildArch%"=="x86" (
  "%CMakePath%" -G "Visual Studio 12 2013" %1
) else (
  "%CMakePath%" -G "Visual Studio 12 2013 Win64" %1
)
endlocal
GOTO :DONE

:USAGE
  echo "Usage..."
  echo "gen-buildsys-win.bat <path to top level CMakeLists.txt>"
  echo "Specify the path to the top level CMake file - <ProjectK>/src/NDP"
  EXIT /B 1

:DONE
  EXIT /B 0






