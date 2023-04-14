#!/bin/bash
set -e

export PATH=/System/bin:$PATH

D=`pwd`
cd ./system
./build_all.sh |& tee $D/build_world.system.log

if ! [ -f "/System/Applications/GWorkspace.app/GWorkspace" ];then
  echo "error building the system apps"
  exit 1
fi

cd "$D"
cd ./Applications
./build_all.sh |& tee $D/build_world.apps.log

if ! [ -f "/Applications/GNUMail.app/GNUMail" ];then
  echo "error building the user apps"
  exit 1
fi

cd "$D"
cd ./config
sudo -E ./install_config.sh
sudo -E ./make_hidden.sh

cd "$D"
cat ./WELCOME.txt
