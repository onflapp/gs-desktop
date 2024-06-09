#!/bin/sh

set -e

cd ../../
if [ -d gnustep-make ];then
  cd ./gnustep-make
  git pull
else
  git clone https://github.com/gnustep/tools-make.git gnustep-make
fi
