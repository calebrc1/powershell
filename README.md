## README for powershell scripts

### Copy-Multithreaded.ps1 is a tool for multi-threaded copy operations when you need to copy 
### a directory as well as all of its underlying folders.

Tested on PowerShell v5.1

The script takes the source and destination directory as the required parameters.

To use it, run Powershell as administrator, type
> set-executionpolicy unrestricted

Then cd into wherever the script is and type the following 
(must use full path for both source and destination)

>.\Copy-Multithreaded.ps1 C:\source C:\destination

While PowerShell versions 7+ included the "foreach -parallel" option, older versions of
powershell require a bit more work to orchestrate multi-threading a for-each loop.

This script simplifies that, and you can simply specify the maximum number of threads that you would 
like to run in your loop simultaneously.
