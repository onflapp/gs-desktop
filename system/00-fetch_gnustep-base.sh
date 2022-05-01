#!/bin/bash

set -e

cd ../../
if [ -d gnustep-base ];then
  cd ./gnustep-base
  git pull
else
  git clone https://github.com/gnustep/libs-base.git gnustep-base
fi
