<#
#Best explanation of why this coded is needed: https://cloudywindows.com/post/straight-and-narrow-code-for-safe-windows-path-updates/
#Run this directly from this location with: 
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/CollectAndPackageSystemInfo.ps1')

#>


If (![bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{Throw "You must be an administrator to run this!"}
Invoke-WebRequest -Uri 'http://download.eset.com/download/sysinspector/64/ENU/SysInspector.exe' -outfile "$env:public\SysInspector.exe"
cd $env:PUBLIC
$Filename = "$env:PUBLIC\SysInspector-$env:Computername-$(Get-date -format 'yyMMdd-hhmmss').zip"
Write-Host "Starting ESET SysInspector - it is not unusual for it to run up to 10 minutes as it collects a lot of data"
$ProcessHandle = Start-Process "$env:PUBLIC\sysinspector.exe" -ArgumentList "/gen=$Filename /silent /privacy /zip" -Passthru
Do {
    ++$ElapsedTime
    Start-Sleep -Seconds 60
    Write-Host "Been waiting $ElapsedTime Minutes..."
} until ($ProcessHandle.HasExited -eq $True)
Write-Host "Please send this file to the requester: `"$Filename`""
Write-Host "You can also run `"$env:PUBLIC\sysinspector.exe`" to open the file and examine what was collected."
