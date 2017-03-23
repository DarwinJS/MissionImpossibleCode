
#Best explanation of why this coded is needed: https://cloudywindows.com/post/straight-and-narrow-code-for-safe-windows-path-updates/
#Using .NET method prevents expansion (and loss) of environment variables (whether the target of the removal or not)
#To avoid bad situations - does not use substring matching or regular expressions
#Removes duplicates of the target removal path, Cleans up double ";", Handles ending "\"


Function Ensure-OnPath ($PathToAdd,$Scope,$PathVariable,$AddToStartOrEnd)
{
  If (!$Scope) {$Scope='Machine'}
  If (!$PathVariable) {$PathVariable='PATH'}
  If (!$AddToStartOrEnd) {$PathVariable='END'}
  $ExistingPathArray = @([Environment]::GetEnvironmentVariable("$PathVariable","$Scope").split(';'))
  if ($ExistingPathArray -inotcontains $PathToAdd)
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
Ensure-OnPath '%ABC%' 'Machine' 'PSModulePath' 'START'

Function Ensure-RemovedFromPath ($PathToRemove,$Scope,$PathVariable)
{
  If (!$Scope) {$Scope='Machine'}
  If (!$PathVariable) {$PathVariable='PATH'}
  $ExistingPathArray = @([Environment]::GetEnvironmentVariable("$PathVariable","$Scope").split(';'))
  if ($ExistingPathArray -icontains $PathToRemove)
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

