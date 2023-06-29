#!/bin/bash

if [ ! -d "/etc/X11/wdm" ];then
  echo "install wdm first!"
  exit 1
fi

echo "=================="
echo " install WDM"
echo "=================="

cp ./etc/X11/wdm/* /etc/X11/wdm
