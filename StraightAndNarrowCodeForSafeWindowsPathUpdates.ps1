
#Best explanation of why this coded is needed: https://cloudywindows.com/post/straight-and-narrow-code-for-safe-windows-path-updates/
#Using .NET method prevents expansion (and loss) of environment variables (whether the target of the removal or not)
#To avoid bad situations - does not use substring matching or regular expressions
#Removes duplicates of the target removal path, Cleans up double ";", Handles ending "\"


Function Ensure-OnPath ($PathToAdd,$Scope,$PathVariable,$AddToStartOrEnd)
{
  If (!$Scope) {$Scope='Machine'}
  If (!$PathVariable) {$PathVariable='PATH'}
  If (!$AddToStartOrEnd) {$AddToStartOrEnd='END'}
  If (($PathToAdd -ilike '*%*') -AND ($Scope -ieq 'Process')) {Throw 'Unexpanded environment variables do not work on the Process level path'}
  write-host "Ensuring `"$pathtoadd`" is added to the $AddToStartOrEnd of variable `"$PathVariable`" for scope `"$scope`" "
  $ExistingPathArray = @([Environment]::GetEnvironmentVariable("$PathVariable","$Scope").split(';'))
  if (($ExistingPathArray -inotcontains $PathToAdd) -AND ($ExistingPathArray -inotcontains "$PathToAdd\"))
  {
    If ($AddToStartOrEnd -ieq 'START')
    { $Newpath = @("$PathToAdd") + $ExistingPathArray }
    else 
    { $Newpath = $ExistingPathArray + @("$PathToAdd")  }
    $AssembledNewPath = ($newpath -join(';')).trimend(';')
    [Environment]::SetEnvironmentVariable("$PathVariable",$AssembledNewPath,"$Scope")
  }
}

#Test code
Ensure-OnPath '%TEST%\bin'
$env:ABC = 'C:\ABC'
Ensure-OnPath '%ABC%' 'Machine' 'PSModulePath' 'START'
Ensure-OnPath 'C:\ABC' 'Process' 'PSModulePath' 'START' #Make available in current process, can't use environment variables

#Show Modification Results
[Environment]::GetEnvironmentVariable("PATH","Process")
[Environment]::GetEnvironmentVariable("PSModulePath","Machine")
[Environment]::GetEnvironmentVariable("PSModulePath","Process")

Function Ensure-RemovedFromPath ($PathToRemove,$Scope,$PathVariable)
{
  If (!$Scope) {$Scope='Machine'}
  If (!$PathVariable) {$PathVariable='PATH'}
  $ExistingPathArray = @([Environment]::GetEnvironmentVariable("$PathVariable","$Scope").split(';'))
  write-host "Ensuring `"$pathtoadd`" is removed from variable `"$PathVariable`" for scope `"$scope`" "
  if (($ExistingPathArray -icontains $PathToRemove) -OR ($ExistingPathArray -icontains "$PathToRemove\"))
  {
    foreach ($path in $ExistingPathArray)
    {
      If ($Path)
      {
        If (($path -ine "$PathToRemove") -AND ($path -ine "$PathToRemove\"))
        {
          [string[]]$Newpath += "$path"
        }
      }
    }
    $AssembledNewPath = ($Newpath -join(';')).trimend(';')
    [Environment]::SetEnvironmentVariable("$PathVariable",$AssembledNewPath,"$Scope")
  }
}

#Test code (undoes changes from Ensure-OnPath test code)
Ensure-RemovedFromPath '%TEST%\bin'
Ensure-RemovedFromPath '%ABC%' 'Machine' 'PSModulePath'
Ensure-RemovedFromPath 'C:\ABC' 'Machine' 'PSModulePath'

#Show Modification Results
[Environment]::GetEnvironmentVariable("PATH","Machine")
[Environment]::GetEnvironmentVariable("PSModulePath","Machine")
[Environment]::GetEnvironmentVariable("PSModulePath","Process")
