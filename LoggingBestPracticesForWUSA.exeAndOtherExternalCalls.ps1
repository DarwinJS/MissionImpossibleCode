
<#
Best explanation of why this coded is needed: https://cloudywindows.com/post/logging-best-practices-for-automating-windows-update-installs-msu-with-wusa.exe-or-any-called-process/
The sample update used here was purposedly chosen so as not to be applicable to the system being tested.
Disable the Windows Installer service to see the attempted resolution in action.

Samples below:
1. Fully Serialized Example of Log Naming (logs never overwritten - retains historical runs)
2. Non-serialized of Log Naming, reset logs to clean everytime (does not retain history)
3. Using the Existence of an Error in the Verbose Log to throw an error
4. Just display log all errors and warnings - use try catch for other errors experienced when starting wusa.exe
5. Acting Upon Specific Messages (Most Complete Solution)
#>

## Fully Serialized Example of Log Naming (logs never overwritten - retains historical runs)

$LogRoot = "$env:PUBLIC\Logs" ## Non-serialized, globally consistent "logroot" on every machine.
$SerializedStringForThisRun = $(Get-date -format 'yyyyMMddhhmmss')  ## date based serialized string - allows all serialized items to have the same serialization.
$LogFolder = "$LogRoot\InstallPSH5-$SerializedStringForThisRun"  ## date based serialized folder
New-Item -ItemType Directory $LogFolder -Force -ErrorAction SilentlyContinue | Out-Null ## This will create the logroot and specific log folder in one shot
$logfilename = "$logfolder\PowerShell-Install-W2K12-KB3191565-x64-$SerializedStringForThisRun-Log.evtx"  ##date based serialized log filename

$wusaswitches = "/quiet /norestart /log:`"$logfilename`""

Write-Host "Running Windows Update with the following command which generate a verbose log at: $logfilename"  ##Logging the fact that a verbose log is available for the sub-process we are about to call

Write-Host "Initiating command: wusa.exe W2K12-KB3191565-x64.msu $wusaswitches"

$ResultObject = start-process "wusa.exe" -ArgumentList "$pwd\W2K12-KB3191565-x64.msu $wusaswitches" -Wait -PassThru

## Non-serialized, reset logs to clean everytime (does not retain history)
$LogRoot = "$env:PUBLIC\Logs"
$LogFolder = "$LogRoot\InstallPSH5"
If (Test-Path $LogFolder) {Remove-Item $LogFolder -Recurse -Force -ErrorAction SilentlyContinue}
New-Item -ItemType Directory $LogFolder -Force -ErrorAction SilentlyContinue | Out-Null
$logfilename = "$logfolder\PowerShell-Install-W2K12-KB3191565-x64-Log.evtx"

$wusaswitches = "/quiet /norestart /log:`"$logfilename`""

Write-Host "Running Windows Update with the following command which generate a verbose log at: $logfilename"  ##Logging the fact that a verbose log is available for the sub-process we are about to call

Write-Host "Initiating command: wusa.exe W2K12-KB3191565-x64.msu $wusaswitches"

$ResultObject = start-process "wusa.exe" -ArgumentList "$pwd\W2K12-KB3191565-x64.msu $wusaswitches" -Wait -PassThru
Write-Output "Return code is: $($ResultObject.ExitCode) - this could also be used for error detection if it is descriptive enough."

## Always Show All Messages in Log
$WarningMsgs = 3
$ErrorMsgs = 2

$LogRoot = "$env:PUBLIC\Logs"
$SerializedStringForThisRun = $(Get-date -format 'yyyyMMddhhmmss')
$LogFolder = "$LogRoot\InstallPSH5-$SerializedStringForThisRun"
New-Item -ItemType Directory $LogFolder -Force -ErrorAction SilentlyContinue | Out-Null
$logfilename = "$logfolder\PowerShell-Install-W2K12-KB3191565-x64-$SerializedStringForThisRun-Log.evtx"
$wusaswitches = "/quiet /norestart /log:`"$logfilename`""

$ResultObject = start-process "wusa.exe" -ArgumentList "$pwd\W2K12-KB3191565-x64.msu $wusaswitches" -Wait -PassThru
Write-Output "Return code is: $($ResultObject.ExitCode) - this could also be used for error detection if it is descriptive enough."

$LogMessagesOfConcern = @(Get-WinEvent -Path "$logfilename" -oldest | where {($_.level -ge $ErrorMsgs) -AND ($_.level -le $WarningMsgs)})
If ($LogMessagesOfConcern.count -gt 0)
{
    Write-Host "Found the following concerning messages in the MSU log `"$logfilename`""
    $LogMessagesOfConcern | Format-List ID, Message | out-string | write-host
}

## Using the Existence of an Error in the Verbose Log to throw an error
$WarningMsgs = 3
$ErrorMsgs = 2

$LogRoot = "$env:PUBLIC\Logs"
$SerializedStringForThisRun = $(Get-date -format 'yyyyMMddhhmmss')
$LogFolder = "$LogRoot\InstallPSH5-$SerializedStringForThisRun"
New-Item -ItemType Directory $LogFolder -Force -ErrorAction SilentlyContinue | Out-Null
$logfilename = "$logfolder\PowerShell-Install-W2K12-KB3191565-x64-$SerializedStringForThisRun-Log.evtx"
$wusaswitches = "/quiet /norestart /log:`"$logfilename`""

Write-Host "Running Windows Update with the following command which generate a verbose log at: $logfilename"

Write-Host "Initiating command: wusa.exe W2K12-KB3191565-x64.msu $wusaswitches"

$ResultObject = start-process "wusa.exe" -ArgumentList "$pwd\W2K12-KB3191565-x64.msu $wusaswitches" -Wait -PassThru

$LogMessagesOfConcern = @(Get-WinEvent -Path "$logfilename" -oldest | where {($_.level -ge $ErrorMsgs) -AND ($_.level -le $WarningMsgs)})
$LogErrorsOnly = @(Get-WinEvent -Path "$logfilename" -oldest | where {$_.level -eq $ErrorMsgs})

If ($LogErrorsOnly.count -gt 0)
{
  Write-Host "Found the following error(s) (and possibly some warnings) in the MSU log `"$logfilename`""
  Throw ($LogMessagesOfConcern | Format-List ID, Message | out-string)
}

## Just display log all errors and warnings - use try catch for other errors experienced when starting wusa.exe
$ErrorActionPreference = 'Stop'
$LogRoot = "$env:PUBLIC\Logs"
$SerializedStringForThisRun = $(Get-date -format 'yyyyMMddhhmmss')
$LogFolder = "$LogRoot\Install PSH5-$SerializedStringForThisRun"
New-Item -ItemType Directory $LogFolder -Force -ErrorAction SilentlyContinue | out-null
$logfilename = "$logfolder\PowerShell-Install-W2K12-KB3191565-x64-$SerializedStringForThisRun-Log.evtx"

$WarningMsgs = 3
$ErrorMsgs = 2

$wusaswitches = "/quiet /norestart /log:`"$logfilename`""

Write-Host "Running Windows Update with the following command which generate a verbose log at: $logfilename"

Write-Host "Initiating command: wusa.exe W2K12-KB3191565-x64.msu $wusaswitches"

Try {
  $ResultObject = start-process "wusa.exe" -ArgumentList "$pwd\W2K12-KB3191565-x64.msu $wusaswitches" -Wait -Passthru
  Write-Output "Return code is: $($ResultObject.ExitCode) - this could also be used for error detection if it is descriptive enough."
  If (Test-Path "$logfilename")
  {
    $LogMessagesOfConcern = @(Get-WinEvent -Path "$logfilename" -oldest | where {($_.level -ge $ErrorMsgs) -AND ($_.level -le $WarningMsgs)})
    If ($LogMessagesOfConcern.count -gt 0)
    {
      Write-Host "Found the following error(s) and warnings in the MSU log `"$logfilename`""
      $LogMessagesOfConcern | Format-List ID, Message | out-string | write-host
    }
  }
}
catch {
  Throw $_.Exception
}

## Acting Upon Specific Messages (Most Complete Solution)
$ErrorActionPreference = 'Stop'
$LogRoot = "$env:PUBLIC\Logs"
$SerializedStringForThisRun = $(Get-date -format 'yyyyMMddhhmmss')
$LogFolder = "$LogRoot\Install PSH5-$SerializedStringForThisRun"
New-Item -ItemType Directory $LogFolder -Force -ErrorAction SilentlyContinue | Out-Null
$logfilename = "$logfolder\PowerShell-Install-W2K12-KB3191565-x64-$SerializedStringForThisRun-Log.evtx"

$WarningMsgs = 3
$ErrorMsgs = 2

$wusaswitches = "/quiet /norestart /log:`"$logfilename`""

Write-Host "Running Windows Update with the following command which generate a verbose log at: $logfilename"  ##Logging the fact that a verbose log is available for the sub-process we are about to call
Write-Host "Initiating command: wusa.exe W2K12-KB3191565-x64.msu $wusaswitches"

Try {
  $ResultObject = start-process "wusa.exe" -ArgumentList "$pwd\W2K12-KB3191565-x64.msu $wusaswitches" -Wait -Passthru
  Write-Output "Return code is: $($ResultObject.ExitCode) - this could also be used for error detection if it is descriptive enough."
  If (Test-Path "$logfilename")
  {
    $LogMessagesOfConcern = @(Get-WinEvent -Path "$logfilename" -oldest | where {($_.level -ge $ErrorMsgs) -AND ($_.level -le $WarningMsgs)})
    If ($LogMessagesOfConcern.count -gt 0)
    {
      Write-Host "Found the following error(s) and warnings in the MSU log `"$logfilename`""
      $LogMessagesOfConcern | Format-List ID, Message | out-string | write-host
      # Check a given substring against all messages to find and handle a known exception
      If ([bool]($LogMessagesOfConcern | where {$_.message -ilike "*error 2147943458*"}))
      {
        Write-warning "Service could not be started, attempting to fix this situation."
        If ((get-service wuauserv).Starttype -ieq 'Disabled')
        {
          Write-warning "The Windows Update Server was disabled, renenabling..."
          Set-Service wuauserv -StartupType 'Manual'
          #Place code to retry install here.
        }
      }
      ElseIf ([bool]($LogMessagesOfConcern | where {$_.message -ilike "*error 2149842967*"}))
      {
        Throw "The update is not applicable to this computer - possibilities reasons include: a prerequisite is missing or the update is not for this operating system."
      }
      else 
      {
        Throw ($LogMessagesOfConcern | Format-List ID, Message | out-string)  
      }
    }
  }
}
catch {
  Throw $_.Exception
}
