@echo off
setlocal EnableDelayedExpansion

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "BIN_DIR=%SCRIPT_DIR%\bin"

echo Installing %BIN_DIR% to PATH...

:: Check if bin directory exists
if not exist "%BIN_DIR%" (
    echo Creating bin directory...
    mkdir "%BIN_DIR%"
    if !ERRORLEVEL! neq 0 (
        echo Failed to create bin directory.
        goto :EOF
    )
    echo Bin directory created successfully.
)

:: Create a VBS script to do all the work (avoids CMD parsing issues)
echo Option Explicit > "%TEMP%\path_update.vbs"
echo On Error Resume Next >> "%TEMP%\path_update.vbs"
echo Dim WshShell, currentPath, pathParts, newPath, foundPath, i >> "%TEMP%\path_update.vbs"
echo Set WshShell = CreateObject("WScript.Shell") >> "%TEMP%\path_update.vbs"
:: Properly escape backslashes and quotes for VBS
set "ESCAPED_BIN_DIR=%BIN_DIR:\=\\%"
set "ESCAPED_BIN_DIR=%ESCAPED_BIN_DIR:"=\"%"
echo Dim binDir >> "%TEMP%\path_update.vbs" 
echo binDir = "%ESCAPED_BIN_DIR%" >> "%TEMP%\path_update.vbs"
echo WScript.Echo "Checking for path: " ^& binDir >> "%TEMP%\path_update.vbs"

:: Get current path and check if our directory exists
echo currentPath = WshShell.Environment("USER").Item("PATH") >> "%TEMP%\path_update.vbs"
echo If Err.Number ^<^> 0 Then >> "%TEMP%\path_update.vbs"
echo     WScript.Echo "Error reading PATH: " ^& Err.Description >> "%TEMP%\path_update.vbs"
echo     currentPath = "" >> "%TEMP%\path_update.vbs"
echo     Err.Clear >> "%TEMP%\path_update.vbs"
echo End If >> "%TEMP%\path_update.vbs"

:: Split and check the path
echo If currentPath ^<^> "" Then >> "%TEMP%\path_update.vbs"
echo     pathParts = Split(currentPath, ";") >> "%TEMP%\path_update.vbs"
echo     foundPath = False >> "%TEMP%\path_update.vbs"
echo     For i = 0 To UBound(pathParts) >> "%TEMP%\path_update.vbs"
echo         If LCase(Trim(pathParts(i))) = LCase(binDir) Then >> "%TEMP%\path_update.vbs"
echo             foundPath = True >> "%TEMP%\path_update.vbs"
echo             WScript.Echo "Path already exists in PATH environment variable." >> "%TEMP%\path_update.vbs"
echo             Exit For >> "%TEMP%\path_update.vbs"
echo         End If >> "%TEMP%\path_update.vbs"
echo     Next >> "%TEMP%\path_update.vbs"
echo Else >> "%TEMP%\path_update.vbs"
echo     foundPath = False >> "%TEMP%\path_update.vbs"
echo End If >> "%TEMP%\path_update.vbs"

:: Add to path if not found
echo If Not foundPath Then >> "%TEMP%\path_update.vbs"
echo     WScript.Echo "Path not found. Adding to PATH environment variable." >> "%TEMP%\path_update.vbs"
echo     If currentPath = "" Then >> "%TEMP%\path_update.vbs"
echo         newPath = binDir >> "%TEMP%\path_update.vbs"
echo     Else >> "%TEMP%\path_update.vbs"
echo         newPath = currentPath ^& ";" ^& binDir >> "%TEMP%\path_update.vbs"
echo     End If >> "%TEMP%\path_update.vbs"
echo     On Error Resume Next >> "%TEMP%\path_update.vbs"
echo     WshShell.Environment("USER").Item("PATH") = newPath >> "%TEMP%\path_update.vbs"
echo     If Err.Number ^<^> 0 Then >> "%TEMP%\path_update.vbs"
echo         WScript.Echo "Error updating PATH: " ^& Err.Description >> "%TEMP%\path_update.vbs"
echo         WScript.Echo "Trying registry method..." >> "%TEMP%\path_update.vbs"
echo         On Error Resume Next >> "%TEMP%\path_update.vbs"
echo         WshShell.RegWrite "HKCU\Environment\PATH", newPath, "REG_EXPAND_SZ" >> "%TEMP%\path_update.vbs"
echo         If Err.Number ^<^> 0 Then >> "%TEMP%\path_update.vbs"
echo             WScript.Echo "Error updating registry: " ^& Err.Description >> "%TEMP%\path_update.vbs"
echo         Else >> "%TEMP%\path_update.vbs"
echo             WScript.Echo "Registry updated successfully." >> "%TEMP%\path_update.vbs"
echo         End If >> "%TEMP%\path_update.vbs"
echo     Else >> "%TEMP%\path_update.vbs"
echo         WScript.Echo "PATH environment variable updated successfully." >> "%TEMP%\path_update.vbs"
echo     End If >> "%TEMP%\path_update.vbs"
echo Else >> "%TEMP%\path_update.vbs"
echo     WScript.Echo "No changes needed." >> "%TEMP%\path_update.vbs"
echo End If >> "%TEMP%\path_update.vbs"

:: Run the VBS script
echo Executing VBScript to safely update PATH...
cscript //nologo "%TEMP%\path_update.vbs"
if %ERRORLEVEL% neq 0 (
    echo Failed to run VBScript.
    goto :EOF
)

:: Clean up
del "%TEMP%\path_update.vbs" >nul 2>&1

:: Try to broadcast the changes so other windows get updated
echo Broadcasting environment change...
rundll32 user32.dll,UpdatePerUserSystemParameters 1, 1

echo.
echo You may need to restart any open command prompts 
echo or applications to see the updated PATH.
echo.
IF /I %0 EQU "%~dpnx0" PAUSE