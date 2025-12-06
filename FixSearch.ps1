### PHASE 1: Fix Service Dependencies ###
# Remove circular/broken dependencies, pointing WSearch only to RPC
sc.exe config WSearch depend= RPCSS

# Set the start type to Automatic (Delayed) to prevent boot traffic jams
sc.exe config WSearch start= delayed-auto

### PHASE 2: "Nuclear" Database Reset ###
# Stop the service to release file locks
sc.exe stop WSearch

# Take ownership of the corrupted data folder
takeown /f "C:\ProgramData\Microsoft\Search" /r /d y

# Rename the old folder (effectively deleting the corrupted database)
Rename-Item -Path "C:\ProgramData\Microsoft\Search" -NewName "Search_BROKEN_OLD" -Force -ErrorAction SilentlyContinue

# Create a fresh, empty folder for the new database
New-Item -ItemType Directory -Path "C:\ProgramData\Microsoft\Search" -Force

# Grant the SYSTEM account full Read/Write access to the new folder
icacls "C:\ProgramData\Microsoft\Search" /grant "SYSTEM:(OI)(CI)F" /T

### PHASE 3: The Root Cause Fix ###
# Enable the Windows Event Log (It was Disabled, causing Error 1722/1058)
sc.exe config EventLog start= auto

# Start the Event Log immediately
sc.exe start EventLog

### PHASE 4: Restart Search ###
# Start the Windows Search Service now that dependencies and data are clean
sc.exe start WSearch

# Verify the service is RUNNING
sc.exe query WSearch
