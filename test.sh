#!/bin/bash

#bash <(curl -v -H "Cache-Control: no-cache" -s https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/test.sh)
#curl -v -H "Cache-Control: no-cache" -s https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/test.sh | bash

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=`lowercase \`uname\``
KERNEL=`uname -r`
MACH=`uname -m`

if [ "{$OS}" == "windowsnt" ]; then
    OS=windows
elif [ "{$OS}" == "darwin" ]; then
    OS=mac
else
    OS=`uname`
    if [ "${OS}" == "SunOS" ] ; then
        OS=solaris
        ARCH=`uname -p`
        OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
    elif [ "${OS}" == "AIX" ] ; then
        OSSTR="${OS} `oslevel` (`oslevel -r`)"
    elif [ "${OS}" == "Linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='redhat'
            DIST=`cat /etc/redhat-release |sed s/\ release.*//`
            PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='suse'
            PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
            REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='mandrake'
            PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='debian'
            DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
            PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
            REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
        fi
        OS=`lowercase $OS`
        DistroBasedOn=`lowercase $DistroBasedOn`
        readonly OS
        readonly DIST
        readonly DistroBasedOn
        readonly PSUEDONAME
        readonly REV
        readonly KERNEL
        readonly MACH
    fi

fi

echo "Operating System Details:"
echo "  OS: $OS"
echo "  DIST: $DIST"
echo "  DistroBasedOn: $DistroBasedOn"
echo "  PSUEDONAME: $PSUEDONAME"
echo "  REV: $REV"
echo "  KERNEL: $KERNEL"
echo "  MACH: $MACH"

if [ "$OS" == "mac" ] ; then
    echo "Configuring PowerShell and VS Code for: $DistroBasedOn distro $DIST version $REV"
elif [ "$DistroBasedOn" == "centos" ] ; then
    echo "Configuring PowerShell and VS Code for: $DistroBasedOn distro $DIST version $REV"    

elif [ "$DIST" == "Ubuntu" ] ; then
      # Import the public repository GPG keys
      curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
      curl https://packages.microsoft.com/config/ubuntu/$REV/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
    #if [ "$REV" == "14.04" ] ; then
      #echo "Configuring PowerShell and VS Code for: $DIST version $REV"
      # Register the Microsoft Ubuntu repository 14.04
      curl https://packages.microsoft.com/config/ubuntu/14.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
    #elif [ "$REV" == "16.04" ] ; then
      #echo "Configuring PowerShell and VS Code for: $DIST version $REV"   
      # Register the Microsoft Ubuntu repository
      #curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list 
    #fi
      # Update apt-get
      sudo apt-get update
      # Install PowerShell
      sudo apt-get install -y powershell
else
    echo "Your operating system is not supported by PowerShell"

fi

