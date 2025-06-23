@echo off
setlocal EnableDelayedExpansion

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "BIN_DIR=%SCRIPT_DIR%\bin"

echo Uninstalling %BIN_DIR% from PATH...

:: Create a VBS script to do all the work (avoids CMD parsing issues)
echo Option Explicit > "%TEMP%\path_remove.vbs"
echo On Error Resume Next >> "%TEMP%\path_remove.vbs"
echo Dim WshShell, currentPath, pathParts, newPath, foundPath, i >> "%TEMP%\path_remove.vbs"
echo Set WshShell = CreateObject("WScript.Shell") >> "%TEMP%\path_remove.vbs"

:: Properly escape backslashes and quotes for VBS
set "ESCAPED_BIN_DIR=%BIN_DIR:\=\\%"
set "ESCAPED_BIN_DIR=%ESCAPED_BIN_DIR:"=\"%"
echo Dim binDir >> "%TEMP%\path_remove.vbs" 
echo binDir = "%ESCAPED_BIN_DIR%" >> "%TEMP%\path_remove.vbs"
echo WScript.Echo "Looking for path to remove: " ^& binDir >> "%TEMP%\path_remove.vbs"

:: Get current path and check if our directory exists
echo currentPath = WshShell.Environment("USER").Item("PATH") >> "%TEMP%\path_remove.vbs"
echo If Err.Number ^<^> 0 Then >> "%TEMP%\path_remove.vbs"
echo     WScript.Echo "Error reading PATH: " ^& Err.Description >> "%TEMP%\path_remove.vbs"
echo     currentPath = "" >> "%TEMP%\path_remove.vbs"
echo     Err.Clear >> "%TEMP%\path_remove.vbs"
echo End If >> "%TEMP%\path_remove.vbs"

:: Split path and rebuild without our directory
echo If currentPath ^<^> "" Then >> "%TEMP%\path_remove.vbs"
echo     pathParts = Split(currentPath, ";") >> "%TEMP%\path_remove.vbs"
echo     newPath = "" >> "%TEMP%\path_remove.vbs"
echo     foundPath = False >> "%TEMP%\path_remove.vbs"
echo     For i = 0 To UBound(pathParts) >> "%TEMP%\path_remove.vbs"
echo         If LCase(Trim(pathParts(i))) ^<^> LCase(binDir) Then >> "%TEMP%\path_remove.vbs"
echo             If newPath = "" Then >> "%TEMP%\path_remove.vbs"
echo                 newPath = pathParts(i) >> "%TEMP%\path_remove.vbs"
echo             Else >> "%TEMP%\path_remove.vbs"
echo                 newPath = newPath ^& ";" ^& pathParts(i) >> "%TEMP%\path_remove.vbs"
echo             End If >> "%TEMP%\path_remove.vbs"
echo         Else >> "%TEMP%\path_remove.vbs"
echo             foundPath = True >> "%TEMP%\path_remove.vbs"
echo             WScript.Echo "Found path entry to remove." >> "%TEMP%\path_remove.vbs"
echo         End If >> "%TEMP%\path_remove.vbs"
echo     Next >> "%TEMP%\path_remove.vbs"
echo Else >> "%TEMP%\path_remove.vbs"
echo     WScript.Echo "PATH is empty. Nothing to do." >> "%TEMP%\path_remove.vbs"
echo     WScript.Quit(0) >> "%TEMP%\path_remove.vbs"
echo End If >> "%TEMP%\path_remove.vbs"

:: Update PATH if the directory was found and removed
echo If foundPath Then >> "%TEMP%\path_remove.vbs"
echo     WScript.Echo "Updating PATH..." >> "%TEMP%\path_remove.vbs"
echo     On Error Resume Next >> "%TEMP%\path_remove.vbs"
echo     WshShell.Environment("USER").Item("PATH") = newPath >> "%TEMP%\path_remove.vbs"
echo     If Err.Number ^<^> 0 Then >> "%TEMP%\path_remove.vbs"
echo         WScript.Echo "Error updating PATH: " ^& Err.Description >> "%TEMP%\path_remove.vbs"
echo         WScript.Echo "Trying registry method..." >> "%TEMP%\path_remove.vbs"
echo         On Error Resume Next >> "%TEMP%\path_remove.vbs"
echo         WshShell.RegWrite "HKCU\Environment\PATH", newPath, "REG_EXPAND_SZ" >> "%TEMP%\path_remove.vbs"
echo         If Err.Number ^<^> 0 Then >> "%TEMP%\path_remove.vbs"
echo             WScript.Echo "Error updating registry: " ^& Err.Description >> "%TEMP%\path_remove.vbs"
echo         Else >> "%TEMP%\path_remove.vbs"
echo             WScript.Echo "Registry updated successfully." >> "%TEMP%\path_remove.vbs"
echo         End If >> "%TEMP%\path_remove.vbs"
echo     Else >> "%TEMP%\path_remove.vbs"
echo         WScript.Echo "PATH environment variable updated successfully." >> "%TEMP%\path_remove.vbs"
echo     End If >> "%TEMP%\path_remove.vbs"
echo Else >> "%TEMP%\path_remove.vbs"
echo     WScript.Echo "Path entry not found in PATH. Nothing to remove." >> "%TEMP%\path_remove.vbs"
echo End If >> "%TEMP%\path_remove.vbs"

:: Run the VBS script
echo Executing VBScript to safely update PATH...
cscript //nologo "%TEMP%\path_remove.vbs"
if %ERRORLEVEL% neq 0 (
    echo Failed to run VBScript.
    goto :EOF
)

:: Clean up
del "%TEMP%\path_remove.vbs" >nul 2>&1

:: Try to broadcast the changes so other windows get updated
echo Broadcasting environment change...
rundll32 user32.dll,UpdatePerUserSystemParameters 1, 1

echo.
echo You may need to restart any open command prompts 
echo or applications to see the updated PATH.
echo.
IF /I %0 EQU "%~dpnx0" PAUSE