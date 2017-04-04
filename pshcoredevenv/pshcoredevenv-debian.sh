#!/bin/bash

#Companion code for the blog https://cloudywindows.com
#call this code direction from the web with:
#bash <(curl -v -H "Cache-Control: no-cache" -s https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/pshcoredevenv-debian.sh)

echo "Processing for Debian"

REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`

# Import the public repository GPG keys
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
#Add the Repo
curl https://packages.microsoft.com/config/ubuntu/$REV/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
# Update apt-get
sudo apt-get update
# Install PowerShell
sudo apt-get install -y powershell

echo "Installing VS Code..."
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt-get update
sudo apt-get install -y code

echo "Installing VS Code PowerShell Extension"
code --install-extension ms-vscode.PowerShell
