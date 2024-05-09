#!/bin/bash

cd ../../

if command -V dpkg >/dev/null 2>&1 ;then
  if [ `dpkg --print-architecture 2>/dev/null` = "armhf" ];then
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "this is ARM 32bit, we need to downgrade to version 1.9"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    BRANCH="origin/1.9"
  fi
fi
  
if [ -d libobjc2 ];then
  cd ./libobjc2
  if [ -n "$BRANCH" ];then
    echo "...in branch $BRANCH, skip pull"
  else
    git pull
  fi
else
  git clone https://github.com/gnustep/libobjc2.git
  cd ./libobjc2

  if [ -n "$BRANCH" ];then
    git checkout origin/1.9
  fi

  git submodule init
  git submodule update
fi
