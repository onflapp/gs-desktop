#!/bin/sh

set -e

cd ../../
if [ -d gnustep-base ];then
  cd ./gnustep-base
  git pull
else
  git clone https://github.com/onflapp/libs-base.git gnustep-base
fi
