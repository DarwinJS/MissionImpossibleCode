#!/usr/bin/env bash
#See usage() function below for help and features description

set -o errexit
set -eo pipefail

SCRIPT_VERSION=1.8
SCRIPTNETLOCATION=https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh
REPORTFILE=/var/tmp/initializediskswithfioreport.txt
DONEMARKERFILE=/var/tmp/initializediskswithfio.done

usage(){
  cat <<- EndOfHereDocument1

  Note: Script name in below will look unusual if using oneliner to download and run help.

  You must be root or able to SUDO (to list sizes of block devices)

  Usage: $0 [-b] [-v] [-h] [-n 10] [-u] [-r 5] [-d \"sda xda\"]

  -b - bare output - must be used as first argument
  -v - emit version and exit
  -h - show help
  -n <int> - use nice to throttle CPU usage. Range: -20 to 19
  -u - unschedule (if scheduled)
  -r <int> - schedule to run every x minutes.  Range: 1 to 59.
      Use for: (a) synchcronous (parallel) execution, (b) reboot resilience, (c) run after other automation complete (max 59 mins).
      -r will also update existing schedule 
      -r also pushes source script version if you are not rerunning the local script (upgrades or downgrades to source version)
      Ok to reschedule by calling /etc/cron.d/InitializeDisksWithFIO.sh -r <newvalue>
      Once device initialization is successfully accomplished, script removes itself from cron and from the system.
      When -r is not used, the command runs asyncrhonously.
  -d - space seperated list of block devices, when not used, all local, writable, non-removable devices are initialized.
      Takes either bare device names from /dev or full device names.
      Use full device names to limit initialization to specific partitions AND/OR to 
      override incorrect detection of local, writable, non-removable devices.

  Examples:
    $0    # (no args) initialize all local, writable, non-removable disk devices immediately
    $0 -r 5 # schedule every 5 minutes to initialize all local, writable, non-removable disk devices immediately

    $0 -d \"sda xda\" # initialize specified devices at /dev/
    $0 -d \"/dev/sda /dev/xda\" # initialize specified devices at full device path as specified
    $0 -d \"/dev/sda1\" # initialize specified partition at full device path as specified

    $0 -n 5 # use specified nice cpu priority to initialize all local, writable, non-removable disk devices
    $0 -b -v # emit only script version (good for comparing whether local version is older than latest online version)
    
    DOWNLOAD AND RUN FROM GITHUB:
    sudo bash <(wget -O - https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh) <arguments>
    # The above works with directly running and scheduling, but does not exit with some arguments like -v, the below always works and is used in the code sample for update checking
    wget https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh -O /tmp/InitializeDisksWithFIO.sh ; sudo bash /tmp/InitializeDisksWithFIO.sh -b -v

  Features:
    Deploying Solution
    - oneliner to download from web and run
    - complete offline operation by copying script and installing or copying fio to image
    - defaults to prefer using fio from path or current directory
    - on the fly install of FIO (supports CentOS, RedHat, Ubuntu, Amazon Linux (1 & 2)), 
      other distros will probably work if you pre-install fio or place the distro matched 
      edition of fio next to this script
    - requires root or sudo - auto-detects what to use - errors if neither is available
    - schedule recurrent cron job for (only a single instance ever runs):
      - reboot resilience - cron job is recurrent each x minutes and self deletes after 
        successful completion
      - future run - up to 59 minutes away (e.g. allow other automation to complete) 
      - parallel run - allow automation to continue (set -r 1) 

    Running
    - initialize multiple devices in parallel (default)
    - CPU throttling (nice)
    - skips non-existence devices
    - takes device list (full path or just last path part) (use -d)
    - if no device list, enumerates all local, writable, non-removable devices 
      (override incorrect device detection by specifying device list)
    - emits bare version (can be used to update or warn when a local copy is older than the latest online version)

    Completion and Cleanup (when fio runs to completion)
    - saves fio output report
    - marks initialization done - which preempts further runs and scheduling until done file is removed
    - removes cron job and copy of script in /etc/cron.d

  Notes on Scheduling
    - If you run the script directly from a URL to schedule it, the original script code must be re-downloaded 
      to set it up in cron - the download is always attempted from the original SOURCE url even if you have rehosted this script.
    - If you wish to avoid the behavior of downloading to schedule, then download a full copy of the script 
      before running the schedule command, this approach also handles a custom hosted location:
      wget https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh -O /tmp/InitializeDisksWithFIO.sh
      bash /tmp/InitializeDisksWithFIO.sh -r 5
  
  Notes and Code for Update Checking:
    The below oneliner that gives an INFO message that the current version is not up to date.
    Note local persisted location "/opt/scripts" should be updated with where you stage the script locally.
    [[ `echo "$(sudo bash /opt/scripts/InitializeDisksWithFIO.sh -b -v) $(wget https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/InitializeDisksWithFIO.sh -O /tmp/InitializeDisksWithFIO.sh ; sudo bash /tmp/InitializeDisksWithFIO.sh -b -v)" | awk '{print ($1 <= $2)}'` == 1 ]] && echo "INFO: Running an old version"

EndOfHereDocument1
}

EmitVersion(){
  if [[ -z "$bareoutput" ]]; then
    echo "The version of ${0} is ${SCRIPT_VERSION}"
  else
    echo "${SCRIPT_VERSION}"
  fi
  exit 0
}

DisplayBanner(){
if [[ -z "${bareoutput}" ]]; then
  cat <<- EndOfHereDocument2

  $0 (InitializeDisksWithFIO.sh) Version: ${SCRIPT_VERSION}
  Updates and information: github link

EndOfHereDocument2
fi
}

RemoveCronJobIfItExists(){
if [[ ! -z "$($SUDO cat /etc/crontab | grep '/etc/cron.d/InitializeDisksWithFIO.sh')" ]]; then
  echo "Removing cron job if it exists  "
  FILECONTENTS=`cat /etc/crontab` ; echo "${FILECONTENTS}" | grep -v '/etc/cron.d/InitializeDisksWithFIO.sh'  | $SUDO tee /etc/crontab > /dev/null
  $SUDO chown root:root /etc/crontab
  $SUDO chmod 644 /etc/crontab
fi
}

RemoveCronScriptIfItExists(){
if [[ -e /etc/cron.d/InitializeDisksWithFIO.sh ]]; then
  echo "Removing cron job script file /etc/cron.d/InitializeDisksWithFIO.sh"
  $SUDO rm /etc/cron.d/InitializeDisksWithFIO.sh -f
fi
}

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

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

while getopts ":cbvhud:n:s:r:" opt; do
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
      if [[ "${OPTARG}" =~ ^-?[0-9]+$ && "${OPTARG}" -ge -20 && "${OPTARG}" -le 19 ]]; then
        [[ -z "${bareoutput}" ]] && echo "-n (nice) was used, adding nicelevel=${OPTARG}" >&2
        nicelevel=${OPTARG}
      else
        echo "Error: parameter \"-n ${OPTARG}\" must be numeric AND in the range -20 to 19.  Use $0 -h for help."
        exit 1
      fi
      ;;
    r)
      if [[ "${OPTARG}" =~ ^-?[0-9]+$ && "${OPTARG}" -ge 1 && "${OPTARG}" -le 59 ]]; then
        [[ -z "${bareoutput}" ]] && echo "-r (recurrenceminutes) was used, adding recurrenceminutes=${OPTARG}" >&2
        recurrenceminutes=${OPTARG}
      else
        echo "Error: parameter \"-r ${OPTARG}\" must be numeric AND in the range 1 to 59.  Use $0 -h for help."
        exit 1
      fi
      ;;
    u)
      [[ -z "${bareoutput}" ]] && echo "removing cron job if it exists" >&2
      RemoveCronJobIfItExists
      RemoveCronScriptIfItExists
      exit 0
      ;;
    v)
      EmitVersion
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

DisplayBanner

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
      DIST=`cat /etc/system-release |sed s/\ release.*//`
      if [[ -f /etc/redhat-release ]] ; then
        REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
      elif [[ -f /etc/system-release ]] ; then
        REV=`cat /etc/system-release | sed s/.*release\ // | sed s/\ .*//`
      fi
      echo "Running on ${DIST} version ${REV}"
      if [[ ! ($DIST == *"Amazon Linux"* && $REV == "2.0") ]] ; then
        #Amazon Linux 2.0 has fio in it's standard repo, no need to enable anything
        wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-$REVMAJOR.noarch.rpm
        $SUDO yum install -y ./epel-release-latest-*.noarch.rpm
      fi
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
fi

if [[ -z "$(command -v fio)" ]] ; then
  echo "Error: Was unable to find or install FIO, exiting."
  exit 2
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
      command+=" --filename=${device_to_warm} ${nicecmd} --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --output ${REPORTFILE} --name=volume-initialize-$(basename ${device_to_warm})"
    fi
  done
  if [[ -e "${DONEMARKERFILE}" ]]; then
    echo "WARNING: Presence of \"${DONEMARKERFILE}\" indicates FIO has completed its run on this system, doing nothing."
    echo "INFO: ${DONEMARKERFILE} would need to be removed to either run or schedule again."
    exit 0
  fi
  #We are either scheduling to run or running now...
  if [[ -n "${recurrenceminutes}" ]]; then
    echo "SCHEDULING: Initializing the EBS volume(s) ${blkdevlist} ..."
    echo "SCHEDULING: command: '$command' for every ${recurrenceminutes} minutes until all initializations complete."
    SCRIPTNAME=/etc/cron.d/InitializeDisksWithFIO.sh
    SCRIPTFOLDER=$(dirname ${SCRIPTNAME})
    SCRIPTBASENAME=$(basename ${SCRIPTNAME})
    if [[ "$0" =~ ^.*\/fd\/.*$ ]]; then
      echo "SCHEDULEING: Script is running from a pipe, must download a copy to schedule it"
      echo "SCHEDULEING: downloading ${SCRIPTNETLOCATION}"
      wget ${SCRIPTNETLOCATION} -O /tmp/InitializeDisksWithFIO.sh
      $SUDO mv /tmp/InitializeDisksWithFIO.sh "${SCRIPTFOLDER}"
    else
      [[ "$0" != "${SCRIPTNAME}" ]] && $SUDO mv $0 "${SCRIPTNAME}"
    fi
    $SUDO chown root:root "${SCRIPTNAME}"
    $SUDO chmod 644 "${SCRIPTNAME}"
    RemoveCronJobIfItExists #In case we are updating an existing job
    #Strip -r or else the cron job will just keep rescheduling itself.  
    #Strip -c if it exists so we wont have two when we insert -c
    echo "Adding cron job"
    STRIPEDRPARAM=$(echo "$@" | sed 's/\-r\ [0-9]//' | sed 's/\-c//')
    echo "*/${recurrenceminutes} * * * * root bash ${SCRIPTNAME} ${STRIPEDRPARAM} -c" | $SUDO tee -a /etc/crontab > /dev/null
    $SUDO chown root:root /etc/crontab
    $SUDO chmod 644 /etc/crontab
    exit 0
  else
    echo "Running FIO now..."
    # NOTE having one letter of the regex square bracketed prevents grep from finding itself, otherwise it needs to be > 1
    if [[ $(ps aux | grep -c "/[f]io[/s]*") > 0 ]]; then 
      echo "fio is already running, exiting..."
      exit 0
    fi
    echo "Initializing the EBS volume(s) ${blkdevlist} ..."
    echo "running command: '$command'"
    $SUDO $FIOPATHNAME ${command}
    if [[ $? -eq 0 ]]; then
      echo "EBS volume(s) ${blkdevlist} completed initialization, marking as done and removing cron job if it was setup."
      echo "INFO: ${DONEMARKERFILE} would need to be removed to either run or schedule again."
      echo $(date) > "${DONEMARKERFILE}"
      RemoveCronJobIfItExists
      RemoveCronScriptIfItExists
    else
      echo "fio did not complete successfully."
    fi
  fi
fi
if [[ -n "${crontriggeredrun}" ]]; then
  echo "Completed successfully, removing cron job"
  RemoveCronJobIfItExists
  RemoveCronScriptIfItExists
fi


: <<'COMMENT'
Tests:
- test OSes: CentOS, Ubuntu, SuSE, Amazon Linux (original and v2)
- run on clean system with no FIO => FIO installs automatically and starts fio
- run on system where fio was automatically installed => skips to running fio with no install
- copy fio from installed location to current folder ( cp $(command -v fio) .) and uninstall 
  package and run script (should find colocated version and not auto install)
- run from web with schedule parameter
COMMENT