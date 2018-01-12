<#
Run this with: 
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/install-pwsh.ps1')
#>

If (!(Test-Path env:chocolateyinstall)) 
{
  write-host "Installing Chocolatey..."
  iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
}
choco upgrade -y powershell-core visualstudiocode
code --install-extension ms-vscode.PowerShell

Write-Host "*********************************************************************"
Write-Host " How to setup core as the default PowerShell for visual studio code: "
Write-Host "  https://github.com/PowerShell/PowerShell/blob/master/docs/learning-powershell/using-vscode.md"
Write-Host