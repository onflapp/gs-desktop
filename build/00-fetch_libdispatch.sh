#!/bin/sh

set -e

cd ../../
if [ -d libdispatch ];then
  cd ./libdispatch
  git pull
else
  git clone https://github.com/onflapp/libdispatch
fi
