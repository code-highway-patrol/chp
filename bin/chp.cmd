@ECHO OFF

REM CHP - Code Highway Patrol
REM Windows CMD wrapper for the CHP CLI

SETLOCAL

REM Get the directory of this batch file
SET "BIN_DIR=%~dp0"

REM Remove trailing backslash
SET "BIN_DIR=%BIN_DIR:~0,-1%"

REM Path to the CLI entry point
SET "CLI_FILE=%BIN_DIR%\..\lib\cli.js"

REM Check if CLI file exists
IF NOT EXIST "%CLI_FILE%" (
    ECHO Error: CHP CLI not found at %CLI_FILE% 1>&2
    EXIT /B 1
)

REM Try to use node from the same directory first (for local installs)
IF EXIST "%BIN_DIR%\node.exe" (
    SET "NODE_EXE=%BIN_DIR%\node.exe"
) ELSE (
    SET "NODE_EXE=node"
)

REM Execute (pass all arguments through)
"%NODE_EXE%" "%CLI_FILE%" %*
