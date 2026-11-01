@echo off
rem AutoMacros: link every installed WoW client's AddOns\AutoMacros to this project
rem folder (a junction), so each build loads everywhere without copying.
rem A plain copy found there is moved to Interface\AutoMacros-old-copy* (not deleted);
rem an empty AutoMacros folder is removed (rd only removes empty folders).
rem No ( ) blocks: "Program Files (x86)" in a variable would end a block early.
rem Output goes to link_clients.log next to this file.
setlocal
set "SRC=%~dp0.."
for %%I in ("%SRC%") do set "SRC=%%~fI"
set "WOW=C:\Program Files (x86)\World of Warcraft"
set "LOG=%~dp0link_clients.log"
echo AutoMacros link run %DATE% %TIME%> "%LOG%"
echo project: "%SRC%">> "%LOG%"
for %%G in (_forever_ _classic_beta_ _retail_ _classic_era_ _classic_ _anniversary_ _ptr_ _xptr_ _beta_) do call :link %%G
echo done>> "%LOG%"
exit /b

:link
set "C=%~1"
set "ADD=%WOW%\%C%\Interface\AddOns"
set "T=%ADD%\AutoMacros"
if not exist "%WOW%\%C%\" exit /b
if not exist "%ADD%\" mkdir "%ADD%"
dir /AL "%ADD%" 2>nul | findstr /I /L /C:" AutoMacros [" >nul
if errorlevel 1 goto notlinked
echo %C%: already a link, left alone>> "%LOG%"
exit /b

:notlinked
if not exist "%T%\" goto makelink
rem an empty folder: just remove it
rd "%T%" 2>nul
if not exist "%T%\" goto makelink
rem a real copy: move it out of AddOns
set "OLD=%WOW%\%C%\Interface\AutoMacros-old-copy"
if exist "%OLD%\" set "OLD=%WOW%\%C%\Interface\AutoMacros-old-copy-%RANDOM%"
move "%T%" "%OLD%" >nul 2>&1
if exist "%OLD%\" echo %C%: old copy moved to "%OLD%">> "%LOG%"
rd "%T%" 2>nul
if not exist "%T%\" goto makelink
echo %C%: AutoMacros folder still there (in use? close WoW and run again), not linked>> "%LOG%"
exit /b

:makelink
mklink /J "%T%" "%SRC%" >> "%LOG%" 2>&1
if errorlevel 1 goto failed
echo %C%: linked>> "%LOG%"
exit /b

:failed
echo %C%: mklink FAILED>> "%LOG%"
exit /b
