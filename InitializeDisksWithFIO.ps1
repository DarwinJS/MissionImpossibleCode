<#
CloudyWindows.io Escalation Toolkit: http://cloudywindows.io
#Run this directly from this location with: 
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/WindowsEscalationToolkit/master/DropSysinternalsTools.ps1')

Grabs one or more sysinternals tools and places them in the target folder.

To use a different default tool list, call the code like this:

Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/WindowsEscalationToolkit/master/DropSysinternalsTools.ps1') -ToolsToPull procexp.exe,procmon.exe

#>
Function Invoke-FIO {
Param (
  [String]$DeviceIDsToInitialize,
  [Switch]$Version,
  [Switch]$Unschedule,
  [ValidateRange(1,59)] 
  [Int]$RepeatIntervalMinutes,
  [ValidateRange(-20,19)] 
  [Int]$NiceValue,
  [Switch]Job
  )

  $Release = 'fio-3.1-x64'
  $EXE = "fio.exe"
  $URL = "https://www.bluestop.org/files/fio/releases/$Release.zip"
  $SubFolder = 'fio'
  $LastSegment = (("$URL") -split '/') | select -last 1

$Banner = @"
*****************************************************
* CloudyWindows.io Escalation Toolkit:
*    $Name - $Description
"*****************************************************
"@
Write-Host $Banner

$SharedWritableLocation="$env:public"
$SCRIPT_VERSION=1.1
$SCRIPTNETLOCATION='https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh'
$REPORTFILE="$SharedWritableLocation/initializediskswithfioreport.txt"
$DONEMARKERFILE="$SharedWritableLocation/initializediskswithfio.done"

$FIOPATHNAME="$((Get-Command fio.exe -ErrorAction SilentlyContinue).Source)"
If (!(Test-Path "$FIOPATHNAME"))
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

$env:path += ";$env:public"
$FIOPATHNAME="$((Get-Command fio.exe -ErrorAction SilentlyContinue).Source)"
If (!(Test-Path "$FIOPATHNAME"))
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
  Foreach ($DriveEnum in $PhysicalDriveEnumList)
  {
    Write-output "Initializing \\.\PHYSICALDRIVE$DriveEnum"
    & $EXE --filename=\\.\PHYSICALDRIVE$DriveEnum --rw=randread --bs=128k --iodepth=32 --ioengine=windowsaio --direct=1 --name=volume-initialize
  }
}
Else
{
  Throw "Was not able to determine a list of devices to initialize, exiting..."
}

If ($CloudyWindowsToolCleanup)
{
  Remove-Item "$SharedWritableLocation" -Recurse -Force
}
}