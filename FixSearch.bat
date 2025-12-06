@echo off
TITLE Windows Search Repair Tool - WinAdmin Helper
CLS

ECHO ========================================================
ECHO    WINDOWS SEARCH & EVENT LOG REPAIR TOOL
ECHO    WinAdmin Helper
ECHO    @Akuma
ECHO ========================================================
ECHO.
ECHO Checking for Administrator privileges...
net session >nul 2>&1
IF %errorLevel% == 0 (
    ECHO Success: Running as Administrator.
) ELSE (
    ECHO ERROR: You must right-click and select "Run as Administrator".
    PAUSE
    EXIT
)
ECHO.

:: ----------------------------------------------------------
:: PHASE 1: Fix Service Dependencies
:: ----------------------------------------------------------
ECHO [PHASE 1] Repairing Service Dependencies...
sc config WSearch depend= RPCSS
sc config WSearch start= delayed-auto
ECHO Done.
ECHO.

:: ----------------------------------------------------------
:: PHASE 2: Database Reset
:: ----------------------------------------------------------
ECHO [PHASE 2] Resetting Search Database...
ECHO Stopping Windows Search Service...
sc stop WSearch >nul 2>&1

:: Wait 5 seconds to ensure the service releases file locks
ECHO Waiting for service to stop...
timeout /t 5 /nobreak >nul

ECHO Taking ownership of data folder...
takeown /f "C:\ProgramData\Microsoft\Search" /r /d y >nul 2>&1

ECHO Renaming old folder (Backing up)...
:: We use 2>nul to hide errors if the folder is already renamed
ren "C:\ProgramData\Microsoft\Search" "Search_BROKEN_OLD" 2>nul

ECHO Creating fresh data folder...
mkdir "C:\ProgramData\Microsoft\Search" 2>nul

ECHO Granting SYSTEM permissions...
icacls "C:\ProgramData\Microsoft\Search" /grant "SYSTEM:(OI)(CI)F" /T
ECHO Done.
ECHO.

:: ----------------------------------------------------------
:: PHASE 3: The Root Cause Fix (Event Log)
:: ----------------------------------------------------------
ECHO [PHASE 3] Fixing Event Log Service...
sc config EventLog start= auto
sc start EventLog
ECHO Done.
ECHO.

:: ----------------------------------------------------------
:: PHASE 4: Restart Search
:: ----------------------------------------------------------
ECHO [PHASE 4] Starting Windows Search...
sc start WSearch

ECHO.
ECHO ========================================================
ECHO    CURRENT STATUS
ECHO ========================================================
sc query WSearch
ECHO.
ECHO If STATE is RUNNING, the fix is complete.
ECHO You may close this window.
PAUSE
