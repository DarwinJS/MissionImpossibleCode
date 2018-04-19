
$packageid = "disablewinrm-on-shutdown"

#Write a file and call it in runonce
$psScriptsFile = "C:\Windows\System32\GroupPolicy\Machine\Scripts\psscripts.ini"
$Key1 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Shutdown\0'
$Key2 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\Shutdown\0'
$keys = @($key1,$key2)
$scriptpath = "C:\Windows\System32\GroupPolicy\Machine\Scripts\Shutdown\disablepsremoting.ps1"
#$selfdeletescriptpath = "C:\Windows\System32\GroupPolicy\Machine\Scripts\Shutdown\disablepsremotingdelete.ps1"
$scriptfilename = (Split-Path -leaf $scriptpath)
$ScriptFolder = (Split-Path -parent $scriptpath)
#$taskname = "Selfdelete_disablewinrm-on-shutdown"

$selfdeletescript = @"
Start-Sleep -milliseconds 500
Remove-Item "$key1" -Force -Recurse
Remove-Item "$key2" -Force -Recurse
Remove-Item "$scriptpath" -Force
#Remove-Item "$selfdeletescriptpath" -Force
(Get-Content "$psScriptsFile") -replace '0CmdLine=$scriptfilename', '' | Set-Content "$psScriptsFile"
(Get-Content "$psScriptsFile") -replace '0Parameters=', '' | Set-Content "$psScriptsFile"
#If ($Error) {`$Error | fl * -force | out-string | out-file "$env:public\selfdeleteerrors.txt"}
"@

$selfdeletescript =[Scriptblock]::Create($selfdeletescript)

#Register-ScheduledJob -Name CleanUpWinRM -RunNow -ScheduledJobOption @{RunElevated=$True;ShowInTaskScheduler=$True;RunWithoutNetwork=$True} -ScriptBlock $selfdeletescript
Invoke-Command -ScriptBlock $selfdeletescript
