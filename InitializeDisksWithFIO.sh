#!/usr/bin/env bash

# bash <(wget -O - https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh) <arguments>
# wget -O - https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh | bash -s <arguments>

#See usage() function for features description

set -o errexit
set -eo pipefail

# configure SUDO if we are not root
SUDO=''
if [[ $EUID != 0 ]] ; then
  SUDO='sudo'
  if [[ "$SUDO" -ne "" ]]; then
    $SUDO -v
    if [ $? -ne 0 ]; then
      echo "ERROR: You must either be root or be able to use sudo" >&2
      exit 5
    fi
  fi
fi

usage(){
  cat <<- EndOfHereDocument1

  Usage: $0 [-d \"sda xda\"]

  When -d is not used, all local, writable, non-removable devices are initialized.

  Examples:
    $0 # initialize local, writable, non-removable disk devices
    $0 -d \"sda xda\" # initialize specified devices at /dev/
    $0 -d \"/dev/sda /dev/xda\" # initialize specified devices at full device path as specified
    $0 -d \"/dev/sda1\" # initialize specified partition at full device path as specified
  
  Features:
    - uses fio from current folder if it exists
    - uses fio from path if if it exists
    - downloads/installs fio if not found
    - skips non-existence devices
    - takes device list (full path or just last path part) (use -d)
    - if no device list, enumerates all local, writable, non-removable devices

EndOfHereDocument1
	exit 1
}

while getopts ":d:h" opt; do
  case $opt in
    d)
      echo "-d was used, Parameter: $OPTARG" >&2
      blkdevlist=${OPTARG}
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

#Allow FIO to just be in the same folder as the script or the current folder when pulling from web
[[ ":$PATH:" != *":$(pwd):"* ]] && PATH="${PATH}:$(pwd)"

if [[ -z "$(command -v fio)" ]] ; then
  echo "ATTENTION: fio not found on path, installing from public repository..."
  echo "NOTE: Place a copy of fio on the path or next to this script to avoid automatic installation."
  echo ""
  repoenabled=false
  repoadded=false
  pushd /tmp
  if [[ -n "$(command -v zypper)" ]] ; then
    packagemanager=zypper
    echo "Found and using ${packagemanager} package manager."
    $SUDO $packagemanager install -y fio
  elif [[ -n "$(command -v yum)" ]] ; then
    packagemanager=yum
    echo "Found and using ${packagemanager} package manager."
    if [[ -n "$(yum repolist disabled | grep 'epel/')" ]] ; then
      echo "epel repository not available, configuring (will be returned to original configuration after install)..."
      $SUDO yum-config-manager --enable epel
      repoenabled=true
    elif [[ -z "$(yum repolist enabled | grep 'epel/')" ]] ; then
      echo "epel repository not available, configuring (will be returned to original configuration after install)..."
      repoadded=true
      if [[ -f /etc/redhat-release ]] ; then
        REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
      elif [[ -f /etc/system-release ]] ; then
        REV=`cat /etc/system-release | sed s/.*release\ // | sed s/\ .*//`
      fi
      REVMAJOR="$(echo $REV | awk -F \. {'print $1'})"
      echo "REVMAJOR is $REVMAJOR"
      wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-$REVMAJOR.noarch.rpm
      $SUDO yum install -y ./epel-release-latest-*.noarch.rpm
    fi
    $SUDO $packagemanager install fio -y
    echo "Returning epel repository to original state"
    if  [[ "$repoadded" == "true" ]] ; then
      $SUDO $packagemanager remove -y epel-release
    elif [[ "$repoenabled" == "true" ]] ; then
      $SUDO yum-config-manager --disable epel
    fi
  elif [[ -n "$(command -v apt-get)" ]] ; then
    packagemanager=apt-get
    echo "Found and using ${packagemanager} package manager."
    $SUDO $packagemanager update
    $SUDO $packagemanager install -y fio
  else
    unset packagemanager
  fi
  if [[ -z "$(command -v fio)" ]] ; then
    echo "ERROR: fio is not available and installation attempt failed."
    exit 5
  else
    FIOPATHNAME="$(command -v fio)"
  fi
  popd
else
  FIOPATHNAME="$(command -v fio)"
fi

if [[ -z "${blkdevlist[*]}" ]]; then
  echo "-d was not used to specify block device list, finding all local, writable block devices."
  blkdevlist="$(lsblk -d -n -oNAME,RO,RM | grep '0\s*0$' | awk {'print $1'})"
  echo "enumerated block devices: ${blkdevlist}"
fi

if [[ ! -z "${blkdevlist[*]}" ]]; then
  echo "Processing block devices: ${blkdevlist}"
  for device_name in ${blkdevlist}
  do
    if [[ ${device_name} == /* ]]; then
      device_to_warm="${device_name}"
    else
      device_to_warm="/dev/${device_name}"
    fi
    if [[ ! -e "${device_to_warm}" ]]; then
      echo "specified device \"${device_to_warm}\" does not exist, skipping..."
    else
      number_of_cores=$(nproc)
      echo "Initialing the EBS volume ${device_to_warm} ..."
      command="$SUDO $FIOPATHNAME --filename=${device_to_warm} --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize"
      echo "running command: '$command'"
      $command
      echo "EBS volume ${device_to_warm} initialized !"
    fi
  done
fi

: <<'COMMENT'
Tests:
- test OSes: CentOS, Ubuntu, SuSE, Amazon Linux (original and v2)
- run on clean system with no FIO => FIO installs automatically and starts fio
- run on system where fio was automatically installed => skips to running fio with no install
- copy fio from installed location to current folder ( cp $(command -v fio) .) and uninstall 
  package and run script (should find colocated version and not auto install)
COMMENT