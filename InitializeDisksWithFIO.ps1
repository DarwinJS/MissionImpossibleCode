<#
CloudyWindows.io Escalation Toolkit: http://cloudywindows.io
#Run this directly from this location with: 
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/WindowsEscalationToolkit/master/DropSysinternalsTools.ps1')

Grabs one or more sysinternals tools and places them in the target folder.

To use a different default tool list, call the code like this:

Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/WindowsEscalationToolkit/master/InitializeDisksWithFIO.ps1') ; Invoke-FIO -DeviceIDsToInitialize

#>
Function Invoke-FIO {
Param (
  [String]$DeviceIDsToInitialize,
  [Switch]$Version,
  [Switch]$Unschedule,
  [ValidateRange(1,59)] 
  [Int]$RepeatIntervalMinutes,
  [ValidateRange(-20,19)] 
  [String]$NiceLevel,
  [Switch]$InvokedFromSchedule
  )
  
  #update to grab latest tag?

  $Release = 'fio-3.1-x64'
  $EXE = "fio.exe"
  $URL = "https://www.bluestop.org/files/fio/releases/$Release.zip"
  $SubFolder = 'fio'
  $LastSegment = (("$URL") -split '/') | select -last 1

$SharedWritableLocation="$env:public"
$env:path += ";$pwd;$SharedWritableLocation"
$SCRIPT_VERSION=1.1
$SCRIPTNETLOCATION='https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.ps1'
$REPORTFILE="$SharedWritableLocation/initializediskswithfioreport.txt"
$DONEMARKERFILE="$SharedWritableLocation/initializediskswithfio.done"

If ($Version)
{
  Write-Output "$SCRIPT_VERSION"
  Exit 0
}

$Banner = @"
*****************************************************
* CloudyWindows.io Provisioning Tools:
*    $Name - $Description
"*****************************************************
"@
Write-Host $Banner

#If fio is found on the path or in the same folder as the script, it is used, otherwise it is automatically downloaded to the sharedwritablelocation and used from there.
$FIOPATHNAME="$((Get-Command fio.exe -ErrorAction SilentlyContinue).Source)"
If (!$FIOPATHNAME -OR !(Test-Path "$FIOPATHNAME"))
{
  Write-Host "Fetching `"$URL`" to `"$SharedWritableLocation`""
  Invoke-WebRequest -Uri "$URL" -outfile "$SharedWritableLocation\$LastSegment"

  If ($LastSegment.endswith(".zip"))
  {
    If (Test-Path "$SharedWritableLocation\$Release") {remove-item "$SharedWritableLocation\$Release" -Force -Recurse}
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory("$SharedWritableLocation\$LastSegment","$SharedWritableLocation")
  }
  copy-item "$SharedWritableLocation\$Release\fio.exe" "$SharedWritableLocation" -Force
  Remove-Item "$SharedWritableLocation\$Release" -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item "$SharedWritableLocation\$LastSegment" -Recurse -Force -ErrorAction SilentlyContinue
}

$FIOPATHNAME="$((Get-Command fio.exe -ErrorAction SilentlyContinue).Source)"
If (!$FIOPATHNAME -OR !(Test-Path "$FIOPATHNAME"))
{ 
  Throw "Could not find, nor install fio.exe"
}

#If PhysicalDevicesToInitialize is unspecified or "All" then enumerate all devices
If ((!(Test-Path variable:DeviceIDsToInitialize)) -OR ($DeviceIDsToInitialize -ieq 'All') -OR ($DeviceIDsToInitialize -ieq ''))
{
  Write-Host "Enumerating all local, writable, non-removable devices"
  $PhysicalDriveEnumList = 1..$((get-itemproperty HKLM:SYSTEM\CurrentControlSet\Services\disk\Enum | Select -ExpandProperty Count))
}
Elseif ($DeviceIDsToInitialize -ne '')
{
  $PhysicalDriveEnumList = [int[]]($DeviceIDsToInitialize -split ';')
}

#Only process if we were actually given a value for PhysicalDriveEnumList
If (Test-Path variable:PhysicalDriveEnumList)
{
  Write-Host "Devices that will be initialized: $($PhysicalDriveEnumList -join ',')"
  if ($NiceLevel)
  { 
    $nicecmd="--nice=${nicelevel}"
  }
  Foreach ($DriveEnum in $PhysicalDriveEnumList)
  {
    $command += " --filename=\\.\PHYSICALDRIVE$DriveEnum ${nicecmd} --rw=read --bs=128k --iodepth=32 --ioengine=windowsaio --direct=1 --name=volume-initialize-$DriveEnum  --output ${REPORTFILE}$DriveEnum"
  }
}
Else
{
  Throw "Was not able to determine a list of devices to initialize, exiting..."
}

write-host "`$command is $command"


if ($RepeatIntervalMinutes -ge 1)
{
    Write-Host "SCHEDULING: Initializing the EBS volume(s) ${DriveEnum} ..."
    Write-Host "SCHEDULING: command: '$command' for every ${RepeatIntervalMinutes} minutes until all initializations complete."
    if((!(test-path variable:psscriptroot)) -or ($psscriptroot -eq ''))
    {
      Write-Host "SCHEDULING: Script is running from a pipe, must download a copy to schedule it"
      Write-Host "SCHEDULING: downloading ${SCRIPTNETLOCATION}"
      Invoke-WebRequest -Uri $SCRIPTNETLOCATION -OutFile $SharedWritableLocation\$((("$SCRIPTNETLOCATION") -split '/') | select -last 1)
    }
    elseif ($myinvocation.MyCommand.Definition -ieq $SharedWritableLocation\$((("$SCRIPTNETLOCATION") -split '/')))
    {
      Write-Host "Already running from correct location"
    }
    Else
    {
      Write-Host "Copying `"$($myinvocation.MyCommand.Definition)`" to `"$SharedWritableLocation\$((("$SCRIPTNETLOCATION") -split '/'))`""
      Copy-item $($myinvocation.MyCommand.Definition) "$SharedWritableLocation\$((("$SCRIPTNETLOCATION") -split '/'))"
    }
  <#
    RemoveCronJobIfItExists #In case we are updating an existing job
    #Strip -r or else the cron job will just keep rescheduling itself.  
    #Strip -c if it exists so we wont have two when we insert -c
    Write-Host "Adding cron job"
    $STRIPEDRPARAM=$(Write-Host "$@" | sed 's/\-r\ [0-9]//' | sed 's/\-c//')
    Write-Host "*/${RepeatIntervalMinutes} * * * * root bash ${SCRIPTNAME} ${STRIPEDRPARAM} -c" | $SUDO tee -a /etc/crontab > /dev/null
    $SUDO chown root:root /etc/crontab
    $SUDO chmod 644 /etc/crontab
    exit 0
    #>
}
else
{
    Write-Host "Running FIO now..."
    # NOTE having one letter of the regex square bracketed prevents grep from finding itself, otherwise it needs to be > 1
    if ((get-process fio -EA SilentlyContinue).count -gt 0)
    {
      Write-Host "fio is already running, exiting..."
      exit 0
    }
    Write-Host "running command: '$FIOPATHNAME $command'"
    Start-Process -Wait -NoNewWindow "$FIOPATHNAME" -ArgumentList "${command}" 
    If ($? -lt 1)
    {
      Write-Host "EBS volume(s) ${DriveEnum} completed initialization, marking as done and removing cron job if it was setup."
      Write-Host "INFO: ${DONEMARKERFILE} would need to be removed to either run or schedule again."
      Set-content "$(get-date)" -path "${DONEMARKERFILE}"
      #RemoveCronJobIfItExists
      #RemoveCronScriptIfItExists
    }
    else
    {
      Write-Host "fio did not complete successfully."
    }
}
<#
if [[ -n "${crontriggeredrun}" ]]
{
  Write-Host "Completed successfully, removing cron job"
  RemoveCronJobIfItExists
  RemoveCronScriptIfItExists
}
#>
}
