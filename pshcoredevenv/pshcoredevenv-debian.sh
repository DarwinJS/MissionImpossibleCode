#!/bin/bash

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
