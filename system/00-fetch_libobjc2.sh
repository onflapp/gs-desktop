#!/bin/bash

cd ../../

if [ -d libobjc2 ];then
  cd ./libobjc2
  git pull
else
  git clone https://github.com/gnustep/libobjc2.git
  cd ./libobjc2

  git submodule init
  git submodule update
fi
