#!/bin/sh
set -e

if [ `id -u` -ne 0 ];then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo " please run this script as root"
  echo " sudo -E $0"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
fi

if ! [ -d "../gnustep-make" ];then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo " system sources not found"
  echo " run './fetch_world.sh' first"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
fi

export PATH=/System/bin:/Library/bin:$PATH

D=`pwd`
cd ./build
./build_all.sh 2>&1 | tee $D/build_world.system.log

if ! [ -f "/System/Applications/GWorkspace.app/GWorkspace" ];then
  echo "error building the system apps"
  exit 1
fi

cd "$D"
cd ./Applications
./build_all.sh 2>&1 | tee $D/build_world.apps.log

if ! [ -f "/Applications/GNUMail.app/GNUMail" ];then
  echo "error building the user apps"
  exit 1
fi

cd "$D"
./document_world.sh 2>&1 | tee $D/build_world.docs.log

cd "$D"
cd ./config

./install_config.sh
./make_hidden.sh

cd "$D"
clear
cat ./WELCOME.txt
