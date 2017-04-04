#!/bin/bash

#Companion code for the blog https://cloudywindows.com
#call this code direction from the web with:
#bash <(curl -v -H "Cache-Control: no-cache" -s https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/pshcoredevenv.sh)

#Your help is needed - there is no possible way I can test on every version of every distro - 
#  please do a pull request if you know how to fix a problem for your deployment scenario 
# (without breaking the already covered, mainline scenarios)

echo "PowerShell Core Development Environment Installer Kickstarter"
echo "Installs full PowerShell Core Development Environment:"
echo "- PowerShell Core via Microsoft Repos (for applicable OSes)"
echo "- Visual Studio Code via Microsoft Repos (for applicable OSes)"
echo "- Visual Studio Code Plug-in for PowerShell (ms-vscode.PowerShell)"

echo "Determining the OS and doing prerequisite work for those that require it..."

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

SCRIPTFOLDER=$(dirname $(readlink -f $0))

if [ "$OS" == "mac" ] ; then
    echo "Configuring PowerShell and VS Code for: $DistroBasedOn distro $DIST version $REV"
    echo "Although Mac is supported, there are no package repositories to allow it to be installed automatically"
elif [ "$DistroBasedOn" == "redhat" ] ; then
    echo "Configuring PowerShell and VS Code for: $DistroBasedOn distro $DIST version $REV"
    if [ -f $SCRIPTFOLDER/pshcoredevenv-redhat.sh ]; then
      . $SCRIPTFOLDER/pshcoredevenv-redhat.sh
    else
      bash <(curl -v -H "Cache-Control: no-cache" -s https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/pshcoredevenv-redhat.sh)
   fi

elif [ "$DIST" == "Ubuntu" ] ; then
    echo "Configuring PowerShell and VS Code for: $DistroBasedOn distro $DIST version $REV"
    if [ -f $SCRIPTFOLDER/pshcoredevenv-debian.sh ]; then
      . $SCRIPTFOLDER/pshcoredevenv-debian.sh
    else
      bash <(curl -v -H "Cache-Control: no-cache" -s https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/pshcoredevenv/pshcoredevenv-debian.sh)
   fi
else
    echo "Your operating system is not supported by PowerShell"
fi

