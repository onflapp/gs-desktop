#!/bin/sh

set -e

cd ../../
if [ -d gnustep-gui ];then
  cd ./gnustep-gui
  git pull
else
  git clone https://github.com/onflapp/libs-gui.git gnustep-gui
fi
