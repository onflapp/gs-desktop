#!/bin/bash
set -e

D=`pwd`
cd ./system
./build_all.sh

cd "$D"
cd ./config
sudo -E ./install_config.sh

cd "$D"
cd ./Applications
./build_all.sh
