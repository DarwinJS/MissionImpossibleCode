



#!/usr/bin/env bash
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
	echo "Usage: $0 [-d \"sda xda\"]"
    echo "Examples:"
    echo "  $0 # initialize local, writable disk devices"
    echo "  $0 -d \"sda xda\" #initialize specified devices at /dev/"
    echo "  $0 -d \"/dev/sda /dev/xda\" #initialize specified devices at full device path as specified"
    echo "  $0 -d \"/dev/sda1\" #initialize specified partition at full device path as specified"
    echo "When -d is not used, all local, writable devices are enumerated."
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
export PATH=$PATH:$(pwd)

FIOPATHNAME="$(command -v fio)"
if [[ -z "${FIOPATHNAME}" ]] ; then
  echo "Installing fio from public repository..."
  repoenabled=false
  repoadded=false
  pushd /tmp
  if [[ -n "$(command -v yum)" ]] ; then
    packagemanager=yum
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
    $SUDO $packagemanager update
    $SUDO $packagemanager install fio -y
  elif [[ -n "$(command -v zypper)" ]] ; then
    packagemanager=zypper
    $SUDO $packagemanager install fio -y
  else
    unset packagemanager
  fi
  popd
fi

FIOPATHNAME="$(command -v fio)"
if [[ -z "${FIOPATHNAME}" ]] ; then
  echo "ERROR: fio is not available and installation attempt failed."
  exit 5
fi

if [ -z "${blkdevlist[*]}" ]; then
  echo "-d was not used to specify block device list, finding all local, writable block devices."
  blkdevlist="$(lsblk -d -n -oNAME,RO,RM | grep '0\s*0$' | awk {'print $1'})"
  echo "enumerated block devices: ${blkdevlist}"
fi

if [ ! -z "${blkdevlist[*]}" ]; then
  echo "Processing block devices: ${blkdevlist}"
  for device_name in ${blkdevlist}
  do
    if [[ ${device_name} == /dev/* ]]; then
      device_to_warm="${device_name}"
    else
      device_to_warm="/dev/${device_name}"
    fi
    number_of_cores=$(nproc)
    echo "Initialing the EBS volume ${device_to_warm} ..."
    command="$SUDO $FIOPATHNAME --filename=${device_to_warm} --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize"
    echo "running command: '$command'"
    $command
    echo "EBS volume ${device_to_warm} initialized !"
  done
fi
 