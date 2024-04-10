#!/bin/bash

if [ "$UID" -ne 0 ];then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo " please run this script as root"
  echo " sudo $0"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
fi

echo "=================="
echo " install WDM"
echo "=================="

D=`realpath $0`
D=`dirname $D`

if [ ! -d "/etc/X11/wdm" ];then
  echo ""
  echo "You need to install WDM first."
  echo "WARNING: WDM will become your default login manager!"
  echo ""
  echo "any key to continue"
  echo "ctrl-c to abort"

  read DD

  apt install -y wdm
  sleep 1

  echo "copy new configuration"
  cp $D/etc/X11/wdm/* /etc/X11/wdm
  sleep 1

  echo "restarting the login manager"
  systemctl restart display-manager
else
  echo "copy in the GSDE configuration"
  cp $D/etc/X11/wdm/* /etc/X11/wdm
fi
