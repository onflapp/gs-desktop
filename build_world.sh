#!/bin/bash
set -e

export PATH=/System/bin:$PATH

D=`pwd`
cd ./system
./build_all.sh |& tee $D/build_world.system.log

cd "$D"
cd ./Applications
./build_all.sh |& tee $D/build_world.apps.log

cd "$D"
cd ./config
sudo -E ./install_config.sh
sudo -E ./make_hidden.sh

cd "$D"
cat ./WELCOME.txt
