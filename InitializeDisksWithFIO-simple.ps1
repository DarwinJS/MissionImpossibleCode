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
  [String]$PhysicalDeviceIDsToInitialize,
  [String]$CloudyWindowsToolsRoot = "$(If ("$env:CloudyWindowsToolsRoot") {"$env:CloudyWindowsToolsRoot"} else {"$env:public\CloudyWindows.io_EscallationTools"})",
  [String]$CloudyWindowsToolsCleanUp = "$(If ("$env:CloudyWindowsToolsCleanUp") {"$env:CloudyWindowsToolsCleanUp"} else {"$true"})",
  [String]$Name = "fio disk utility",
  [String]$Description = "disk reading utility useful for initializing AWS EBS volumes",
  [String]$Release = 'fio-3.1-x64',
  [String]$EXE = "$Release\fio.exe",
  [String]$URL = 'http://www.bluestop.org/files/fio/releases/fio-3.1-x64.zip',
  [String]$SubFolder = 'fio'
  )

  $LastSegment = (("$URL") -split '/') | select -last 1
  $CloudyWindowsToolFolder = "$CloudyWindowsToolsRoot\$SubFolder"

$ToolBanner = @"
*****************************************************
* CloudyWindows.io Escalation Toolkit:
*    $Name - $Description
"*****************************************************
"@
Write-Host $ToolBanner

If (!(Test-Path "$CloudyWindowsToolFolder")) { New-Item -ItemType Directory -Path "$CloudyWindowsToolFolder" -Force | Out-Null}
If (!(Test-Path "$CloudyWindowsToolFolder\$EXE"))
{
  Write-Host "Fetching `"$URL`" to `"$CloudyWindowsToolFolder\$LastSegment`""
  Invoke-WebRequest -Uri "$URL" -outfile "$CloudyWindowsToolFolder\$LastSegment"

  If ($LastSegment.endswith(".zip"))
  {
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory("$CloudyWindowsToolFolder\$LastSegment","$CloudyWindowsToolFolder")
  }
}

Write-Host "Waiting for $CloudyWindowsToolFolder\$EXE to exit"

#Parm PhysicalDevicesToInitialize = All | string of positive integers seperated by ';'
If (Test-Path variable:PhysicalDeviceIDsToInitialize)
{
  If ($PhysicalDeviceIDsToInitialize -ieq 'All')
  {
    $PhysicalDriveEnumList = 1..$((get-itemproperty HKLM:SYSTEM\CurrentControlSet\Services\disk\Enum | Select -ExpandProperty Count))
  }
  Elseif ($PhysicalDeviceIDsToInitialize -ne '')
  {
    $PhysicalDriveEnumList = [int[]]($PhysicalDeviceIDsToInitialize -split ';')
  }
}
#Only process if we were actually given a value for PhysicalDriveEnumList
If (Test-Path variable:PhysicalDriveEnumList)
{
  Write-Host "Devices that will be initialized: $($PhysicalDriveEnumList -join ',')"
  cd $CloudyWindowsToolFolder
  Foreach ($DriveEnum in $PhysicalDriveEnumList)
  {
    Write-output "Initializing \\.\PHYSICALDRIVE$DriveEnum"
    & $EXE --filename=\\.\PHYSICALDRIVE$DriveEnum --rw=randread --bs=128k --iodepth=32 --ioengine=windowsaio --direct=1 --name=volume-initialize
  }
}

If ($CloudyWindowsToolCleanup)
{
  Remove-Item "$CloudyWindowsToolFolder" -Recurse -Force
}
}