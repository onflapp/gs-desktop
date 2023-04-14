#!/bin/bash

cd ../../

if [ -d libobjc2 ];then
  cd ./libobjc2
  git pull
else
  git clone https://github.com/gnustep/libobjc2.git
  cd ./libobjc2

  if [ `dpkg --print-architecture 2>/dev/null` = "armhf" ];then

    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "this is ARM 32bit, we need to downgrade to version 1.9"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

    git checkout origin/1.9
  fi

  git submodule init
  git submodule update
fi
