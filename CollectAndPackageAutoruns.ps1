<#
#Best explanation of why this coded is needed: https://cloudywindows.com/post/straight-and-narrow-code-for-safe-windows-path-updates/
#Run this directly from this location with: 
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/CollectAndPackageAutoruns.ps1')

#>

#Autoruns
If (![bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{$erroractionpreference = 'Stop' ; Throw "You must be an administrator to run this!"}
Invoke-WebRequest -Uri 'http://live.sysinternals.com/autoruns.exe'  -outfile "$env:public\autoruns.exe"
cd $env:PUBLIC
$Filename = "$env:PUBLIC\Autoruns-$env:Computername-$(Get-date -format 'yyMMdd-hhmmss').arn"
Write-Host "Starting autoruns - it is not unusual for it to run up to 3 minutes as it collects a lot of data."
$ProcessHandle = Start-Process "$env:public\autoruns.exe" -ArgumentList "-e -a $Filename" -Passthru
Do {
    ++$ElapsedTime
    Start-Sleep -Seconds 60
    Write-Host "Been waiting $ElapsedTime Minutes..."
} until ($ProcessHandle.HasExited -eq $True)
Write-Host "Please send this file to the requester: `"$Filename`""
Write-Host "You can also run `"$env:PUBLIC\autoruns.exe`" to open the file and examine what was collected."
