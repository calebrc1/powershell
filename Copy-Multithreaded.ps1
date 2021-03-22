# This PowerShell Script will recursively scan all files in 
# the given $sourceDir and use multi-threading to copy to a new $destDir. 
# The number of threads can be modified with
# the below "$MAX_THREAD_COUNT" variable.
# It will generate a new log file with the names 
# and counts of all files and directories scanned

param (
    [Parameter(Mandatory=$true)][string]$sourceDir,
    [Parameter(Mandatory=$true)][string]$destDir
    )

#Modify this variable to change maximum number of threads.
$MAX_THREAD_COUNT = 4

# get start date and time for tracking
$startDateAndTime = Get-Date # for log header
$startTime = Get-Date -UFormat "%m_%d_%Y_%H%M%S" #for log file name

$StopWatch = [system.diagnostics.stopwatch]::startNew()

$startMs = (Get-Date).Millisecond  # for calculating runtime

# # get current directory
$curPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# # generate logfile and Write-Log function
$logFile = $curPath + "\" + $startTime + "_CopyResults.log"

Function Write-Log
{
   param ([string]$logstring)
   Add-Content $logFile -value $logstring
}

Write-Log "Copy initiated: $startDateAndTime"

# ScriptBlock that will run in new parallelized process
$block = {
    param($originalFilePath, $fileDest, $logFile)
    Copy-Item -Path  $originalFilePath -Destination $fileDest -Force
    Add-Content $logFile -value $fileDest
}

# recursively get a list of all items 
$allItems = Get-ChildItem -Recurse $sourceDir 

# print and log start time, number of items to copy
Write-Output "Copying $($allItems.Count) items from ($sourceDir) to ($destDir)"
Write-Log "Copying $($allItems.Count) items from ($sourceDir) to ($destDir)"

Write-Log --

#instantiate empty incrementers
$totalSize = [int] 0
$fileCount = [int] 0
$folderCount = [int] 0

Write-Log "The following files and directories were transferred successfully"

$allItems |  foreach { 
   
    $item = $_

    # handle folder naming and copy operation (SINGLE THREADED)
    if ($item.PSIsContainer) {
        $folderDest = Join-Path $destDir $item.Parent.FullName.Substring($sourceDir.length)
        Copy-Item -Path $item.FullName -Destination $folderDest -Force
        Write-Log "$folderDest\$item"
        $folderCount++
        }

    # handle file naming and copy operation
    else {
        $fileDest = Join-Path $destDir $_.FullName.Substring($sourceDir.length)
        $originalFilePath = $item.Fullname
        Write-Output "Copying $item"
        #start the job, running specified maximum jobs simultaneously
        While ($(Get-Job -State Running).count -ge $MAX_THREAD_COUNT){
            Start-Sleep -Milliseconds 3
        }
        Start-Job -Scriptblock $block -ArgumentList ($originalFilePath, $fileDest, $logFile)
        # get file size
        $fileSize = ($item | % {[int]($item.length / 1kb)})
        #increment totalSize before restarting loop
        $totalSize = $totalSize + $fileSize
        $fileCount++
    }

}

Write-Output "All transfers successfully initiated. Waiting for pending copy processes to complete."

#Wait for all jobs to finish.
While ($(Get-Job -State Running).count -gt 0){
    start-sleep 1
}

Write-Output "All copy jobs complete. Closing remaining processes."

#Remove all jobs created.
Get-Job | Remove-Job

Write-Output "Processes terminated successfully"

#finalize calculations
$sizeMBs = $totalSize/1000
$elapsedTimeInSeconds = $StopWatch.Elapsed.TotalSeconds

#update log
Write-Log --
Write-Log "Copy Completed: $startDateAndTime"
Write-Log "Elapsed Time"
Write-Log "$elapsedTimeInSeconds Seconds ($($elapsedTimeInSeconds/60) Minutes)"
Write-Log "Copied a total of $fileCount files in $folderCount directories"
Write-Log "Total amount of data transferred: $sizeMBs MBs"
Write-Log "Average transfer speed: $($sizeMBs/$elapsedTimeInSeconds) MB/s"

#print output
Write-Output "Copy complete. Successfuly copied $($allItems.Count) items"
Write-Output "Elapsed Time"
Write-Output "$elapsedTimeInSeconds Seconds ($($elapsedTimeInSeconds/60) Minutes)"
Write-Output "Total amount of data transferred: $sizeMBs MBs"
Write-Output "Average transfer speed: $($sizeMBs/$elapsedTimeInSeconds) MB/s"
Write-Output "Logfile is located at $logFile"
Write-Output "------------------------------"