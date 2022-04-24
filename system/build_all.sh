#!/bin/bash
set -e

if [ -z "$CC" ];then
  . ./BUILD_SETTINGS.sh
fi

echo "enter your admin password to install all system files"
sudo -E cp ../config/etc/ld.so.conf.d/gs-desktop.conf /etc/ld.so.conf.d

for DD in `ls -1 *-build_*.sh`; do
  echo $DD
  ./$DD || exit
done
