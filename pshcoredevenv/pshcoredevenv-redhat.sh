#!/bin/bash

#Companion code for the blog https://cloudywindows.com
#call this code direction from the web with:
#bash <(wget -O - https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/pshcoredevenv-redhat.sh)

#Your help is needed - there is no possible way I can test on every version of every distro - 
#  please do a pull request if you know how to fix a problem for your deployment scenario 
# (without breaking the already covered, mainline scenarios)

echo "Arguments used:"
echo $@
echo ""

echo "PowerShell Core Development Environment Installer for Redhat 7"
echo "Installing PowerShell Core..."
sudo curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/microsoft.repo
sudo yum install -y powershell

echo "Installing VS Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'    
yum check-update
sudo yum install -y code

echo "Installing VS Code PowerShell Extension"
code --install-extension ms-vscode.PowerShell

if [[ "$@" != "NONITERACTIVE" ]]; then
  echo "Loading test code in VS Code"
  wget -O ./testpowershell.ps1 https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/testpowershell.ps1
  code ./testpowershell.ps1
fi