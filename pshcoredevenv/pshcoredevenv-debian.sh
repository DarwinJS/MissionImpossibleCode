#!/bin/bash

#Companion code for the blog https://cloudywindows.com
#call this code direction from the web with:
#bash <(wget -O - https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/pshcoredevenv-debian.sh)

#Your help is needed - there is no possible way I can test on every version of every distro - 
#  please do a pull request if you know how to fix a problem for your deployment scenario 
# (without breaking the already covered, mainline scenarios)

VERSION="1.1.2"
echo ""
echo "*** DEBIAN: PowerShell Core Development Environment Installer $VERSION"

echo "*** Arguments used: $*"
echo ""

echo "*** Installing PowerShell Core..."
sudo apt-get install -y curl

REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`

# Import the public repository GPG keys
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
#Add the Repo
curl https://packages.microsoft.com/config/ubuntu/$REV/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
# Update apt-get
sudo apt-get update
# Install PowerShell
sudo apt-get install -y powershell

echo "*** Installing VS Code..."
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
sudo apt-get install -y code

echo "*** Installing VS Code PowerShell Extension"
code --install-extension ms-vscode.PowerShell

if [[ "'$*'" =~ NONINTERACTIVE ]] ; then
    echo "*** Install Complete"
else
    echo "*** Loading test code in VS Code"
    wget -O ./testpowershell.ps1 https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/testpowershell.ps1
    code ./testpowershell.ps1        
fi