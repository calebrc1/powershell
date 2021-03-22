# README for powershell scripts

## Copy-Iterator.ps1 is a tool for multi-threaded copy operations. 

While PowerShell versions 7+ included the "foreach -parallel" option, older versions of
powershell require a bit more work to orchestrate multi-threading a for-each loop.

This script simplifies that, and you can simply specify the maximum number of threads that you would 
like to run in your loop simultaneously.
