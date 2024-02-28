#!/bin/bash

newjre="/depot/software/oracle/JDKs/1.8/jre/linux/latest/"

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

# Check if /usr/openv/tmp/root_tmp folder exists and create if not there
if [ ! -d "/usr/openv/tmp/root_tmp" ]; then
  mkdir -p "/usr/openv/tmp/root_tmp"
fi

# Typically /tmp is mounted as noexec, we'll check that, if it is true we'll make a new temp directory for the installer
if mount | grep '/tmp.*noexec' > /dev/null; then
  # Check if /usr/openv/tmp/root_tmp folder exists
  if [ ! -d "/usr/openv/tmp/root_tmp" ]; then
  # Create the directory if it does not exist
    mkdir -p "/usr/openv/tmp/root_tmp"
  fi
  # Set the value of TEMP to /usr/openv/tmp/root_tmp
  export TEMP="/usr/openv/tmp/root_tmp"
fi


# Run the nbcomponentupdate command
/usr/openv/netbackup/bin/goodies/nbcomponentupdate -force -product NetBackup -component jre -path $newjre -logpath /tmp

