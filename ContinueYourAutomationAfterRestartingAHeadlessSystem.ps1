
#The arcicle for this code is here: https://cloudywindows.com/post/continue-your-automation-to-run-once-after-restarting-a-headless-windows-system/

$scriptlocation = "$env:windir\temp\afterreboot.ps1"
"Write-EventLog -Message 'HeadlessRestartTask: hi I ran on reboot' -LogName System -Source EventLog -EventId 333"| out-file $scriptlocation
start-sleep -s 2" | out-file $scriptlocation -append
"schtasks.exe /delete /f /tn HeadlessRestartTask | out-file $scriptlocation -append


#This code schedules the above script
schtasks.exe /create /f /tn HeadlessRestartTask /ru SYSTEM /sc ONSTART /tr "powershell.exe -file $scriptlocation"
Write-Host "`"$scriptlocation`" is scheduled to run once after reboot."

#This oneliner schedules a bit of Powershell and self deletes without a script file.
#managing your quotes and escaping can be a challenge if your scheduled code is not simple
schtasks.exe /create /f /tn HeadlessRestartTask /ru SYSTEM /sc ONSTART /tr "powershell.exe -executionpolicy remotesigned -command 'Write-EventLog -Message HeadlessRestartTask_hi_I_ran_on_reboot -LogName System -Source EventLog -EventId 333 ; schtasks.exe /delete /f /tn HeadlessRestartTask'"
