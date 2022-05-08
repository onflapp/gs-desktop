#!/bin/bash
set -e

cd ../../
D=`pwd`

if [ -d libs-steptalk ];then
  cd ./libs-steptalk
  git pull
else
  git clone https://github.com/gnustep/libs-steptalk.git
fi

cd "$D"
if [ -d libs-dbuskit ];then
  cd ./libs-dbuskit
  git pull
else
  git clone https://github.com/onflapp/libs-dbuskit.git
fi

