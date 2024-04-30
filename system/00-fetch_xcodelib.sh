#!/bin/bash

set -e

cd ../../
if [ -d libs-xcode ];then
  cd ./libs-xcode
  git pull
else
  git clone https://github.com/gnustep/libs-xcode
fi
