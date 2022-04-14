#!/bin/bash
set -e

if [ -z "$CC" ];then
  . ./BUILD_SETTINGS.sh
fi

./fetch_gnustep-back.sh
./fetch_gnustep-base.sh
./fetch_gnustep-gui.sh
./fetch_gnustep-make.sh
./fetch_gs-wmaker.sh
./fetch_gs-workspace.sh
./fetch_libdispatch.sh
./fetch_libobjc2.sh
./fetch_nextspace.sh
