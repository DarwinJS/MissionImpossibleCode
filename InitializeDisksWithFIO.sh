#!/usr/bin/env bash

# bash <(wget --no-cache -O - https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh) <arguments>
# wget --no-cache -O - https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh | bash -s <arguments>

#See usage() function for features description

set -o errexit
set -eo pipefail

SCRIPT_VERSION=1.1.0

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

emitversion(){
  if [[ -z "$bareoutput" ]]; then
    echo "The version of ${0} is ${SCRIPT_VERSION}"
  else
    echo "${SCRIPT_VERSION}"
  fi
}

usage(){
  cat <<- EndOfHereDocument1

  Note: Script name in below will look unusual if using oneliner to download and run help.

  Usage: $0 [-d \"sda xda\"]

  When -d is not used, all local, writable, non-removable devices are initialized.

  Examples:
    $0 # initialize all local, writable, non-removable disk devices
    $0 -d \"sda xda\" # initialize specified devices at /dev/
    $0 -d \"/dev/sda /dev/xda\" # initialize specified devices at full device path as specified
    $0 -d \"/dev/sda1\" # initialize specified partition at full device path as specified
    $0 -n 5 # use specified nice cpu priority to initialize all local, writable, non-removable disk devices
    $0 -b # bare - must be used as first argument - suppresses banner and extraneous output (including on emitversion)
    $0 -v # emit script name and version
    $0 -b -v # emit only script version (good for comparing whether local version is older than latest online version)
  
  Features:
    - oneliner to download from web and run
    - complete offline operation by copying script and installing fio on image
    - read multiple devices in parallel
    - supports processor throttling (nice)
    - TODO schedule for future time
    - TODO reboot resilience (through schedule)
    - uses fio from path or current if it exists
    - downloads/installs fio if not found
    - skips non-existence devices
    - takes device list (full path or just last path part) (use -d)
    - if no device list, enumerates all local, writable, non-removable devices
    - emits version (can be used to update or warn when a local copy is older than the latest online version)

EndOfHereDocument1
}

displaybanner(){
if [[ -z "${bareoutput}" ]]; then
  cat <<- EndOfHereDocument2

  $0 (InitializeDisksWithFIO.sh) Version: ${SCRIPT_VERSION}
  Updates and information: github link

EndOfHereDocument2
fi
}

while getopts ":bvhdu:n:c:s:" opt; do
  case $opt in
    b)
      bareoutput=true
      ;;
    c)
      [[ -z "${bareoutput}" ]] && echo "-c (crontriggeredrun) was used, adding crontriggeredrun=true" >&2
      unschedulewhendone=true
      ;;
    d)
      blkdevlist=${OPTARG}
      ;;
    n)
      [[ -z "${bareoutput}" ]] && echo "-n (nice) was used, adding nicelevel=${OPTARG}" >&2
      nicelevel=${OPTARG}
      ;;
    r)
      [[ -z "${bareoutput}" ]] && echo "-r (recurrenceminutes) was used, adding recurrenceminutes=${OPTARG}" >&2
      nicelevel=${OPTARG}
      ;;
    v)
      emitversion
      exit 0
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "INVALID OPTION: -$OPTARG" >&2
      echo ""
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

#Only one copy at a time (especially for scheduled runs)
LOCKDIRNAME=/tmp/InitializeDisksWithFIO.lock
if [[ -d "${LOCKDIRNAME}" ]]; then
  echo "Lock folder \"${LOCKDIRNAME}\" exists, script already running, exiting..."
  exit 0
else
  mkdir "${LOCKDIRNAME}"
fi
trap 'echo "Removing Lock" ; rm -rf "${LOCKDIRNAME}"; exit 1' 2 3 5 10 13 15 #remove lock on unexpected exit
trap 'echo "Removing Lock" ; rm -rf "${LOCKDIRNAME}";' 0 # remove lock on successful exit

displaybanner

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
      if [[ ! -z "${nicelevel}" ]]; then
        nicecmd="--nice=${nicelevel}"
      fi
      #Customize this line if you wish to customize how FIO operates
      command+=" --filename=${device_to_warm} ${nicecmd} --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize-$(basename ${device_to_warm})"
    fi
  done
  if [[ -z "${recurrenceminutes}" ]]; then
    echo "Initialing the EBS volume(s) ${blkdevlist} ..."
    echo "running command: '$command'"
    $SUDO $FIOPATHNAME ${command}
    echo "EBS volume(s) ${blkdevlist} initialized !"
  else
    echo "SCHEDULING: Initialing the EBS volume(s) ${blkdevlist} ..."
    echo "SCHEDULING: command: '$command' for every ${recurrenceminutes} minutes until all initializations complete."
    SCRIPTNAME=/etc/crontab/InitializeDisksWithFIO.sh
    if [[ "$0" -ne "${SCRIPTNAME}" ]]; then
      echo "Copying script to ${SCRIPTNAME}"
      cp $0 ${SCRIPTNAME} -f
    else
      SCRIPTNAME="$0"
    fi
    if [[ -z "$($SUDO cat /etc/crontab | grep '${SCRIPTNAME}')" ]]; then
      $SUDO sh -c 'echo "*/${recurrenceminutes} * * * * bash ${SCRIPTNAME} $@ -c" >> /etc/crontab' 
    fi
    exit 0
  fi
fi
if [[ -n "${crontriggeredrun}" ]]; then
  echo "Completed successfully, removing cron job"
  if [[ ! -z "$($SUDO cat /etc/crontab | grep '$0')" ]]; then
    $SUDO sh -c 'FILECONTENTS=`cat /etc/crontab` ; echo "${FILECONTENTS}" | grep -v "$0" > /etc/crontab'
  fi
fi


: <<'COMMENT'
Tests:
- test OSes: CentOS, Ubuntu, SuSE, Amazon Linux (original and v2)
- run on clean system with no FIO => FIO installs automatically and starts fio
- run on system where fio was automatically installed => skips to running fio with no install
- copy fio from installed location to current folder ( cp $(command -v fio) .) and uninstall 
  package and run script (should find colocated version and not auto install)

Todos:
- run using scheduler
- reboot resilience
- save output report from fio
COMMENT