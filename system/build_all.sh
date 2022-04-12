#!/bin/bash
set -e

if [ -z "$CC" ];then
  . ./BUILD_SETTINGS.sh
fi

cp ./nextspace/System/etc/ld.so.conf.d/nextspace.conf /etc/ld.so.conf.d

./build_libobjc2.sh
./build_libdispatch.sh
ldconfig

./build_gnustep-make.sh
./build_gnustep-base.sh
./build_gnustep-gui.sh
./build_gnustep-back.sh
./build_nextspace.sh
