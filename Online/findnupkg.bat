@echo off
setlocal

:: Set the search directory based on the user's profile directory
set search_directory="%USERPROFILE%\Box\FM Game Systems\Choco"
set output_file="%~dp0nupkg_list.txt" 

:: Clear out the old file without causing unwanted output
type nul > %output_file%

:: Check if the Choco directory exists in the user's profile
if not exist %search_directory% (
    echo The required directory %search_directory% does not exist. Please ensure the directory is available.
    exit /b 1
)

:: Search for nupkg files and append them to the output file
for /f "delims=" %%i in ('dir %search_directory% /s /b ^| findstr ".nupkg$"') do (
    echo %%i >> %output_file%
)

:: Debug to provide feedback on the number of packages found
set /a count=0
for /f %%i in (%output_file%) do set /a count+=1
if %count% gtr 0 (
    echo Found %count% .nupkg files! List is saved in nupkg_list.txt.
) else (
    echo No .nupkg files were found in the specified directory.
)

endlocal
exit /b 0
