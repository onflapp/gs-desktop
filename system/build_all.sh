#!/bin/bash
set -e

if [ -z "$CC" ];then
  . ./BUILD_SETTINGS.sh
fi

sudo -E cp ../config/etc/ld.so.conf.d/gs-desktop.conf /etc/ld.so.conf.d

./build_libobjc2.sh
./build_libdispatch.sh

./build_gnustep-make.sh
./build_gnustep-base.sh
./build_gnustep-gui.sh
./build_gnustep-back.sh

./build_nextspace-kits.sh
./build_nextspace-utils.sh

./build_gs-workspace.sh
./build_gs-wmaker.sh
