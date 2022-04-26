#!/bin/bash
set -e

if [ -z "$CC" ];then
  . ../BUILD_SETTINGS.sh
fi

sudo -E cp ../config/etc/ld.so.conf.d/gs-desktop.conf /etc/ld.so.conf.d

for DD in `ls -1 *-build_*.sh`; do
  echo $DD
  ./$DD || exit
done
