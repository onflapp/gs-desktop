#!/bin/sh

set -e

cd ../../
if [ -d gnustep-back ];then
  cd ./gnustep-back
  git pull
else
  git clone https://github.com/onflapp/libs-back.git gnustep-back
fi
