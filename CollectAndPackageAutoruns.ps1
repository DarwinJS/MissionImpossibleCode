<#
#Best explanation of why this coded is needed: https://cloudywindows.com/post/automated-collection-of-diagnostic-system-information-from-systems-you-dont-own/
#Run this directly from this location with: 
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/CollectAndPackageAutoruns.ps1')

#>

#Autoruns
If (![bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{$erroractionpreference = 'Stop' ; Throw "You must be an administrator to run this!"}
Invoke-WebRequest -Uri 'http://live.sysinternals.com/autoruns.exe'  -outfile "$env:public\autoruns.exe"
cd $env:PUBLIC
$Filename = "$env:PUBLIC\Autoruns-$env:Computername-$(Get-date -format 'yyMMdd-hhmmss').arn"
Start-Process "$env:public\autoruns.exe" -ArgumentList "-e -a $Filename" -wait
Write-Host "Please send this file to the requester: `"$Filename`""
Write-Host "You can also run `"$env:PUBLIC\autoruns.exe`" and use File => Open to open the file and examine what was collected."
