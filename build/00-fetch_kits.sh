#!/bin/sh
set -e

cd ../../
D=`pwd`

if [ -d libs-steptalk ];then
  cd ./libs-steptalk
  git pull
else
  git clone https://github.com/onflapp/libs-steptalk.git
fi

cd "$D"
if [ -d libs-dbuskit ];then
  cd ./libs-dbuskit
  git pull
else
  git clone https://github.com/onflapp/libs-dbuskit.git
fi

cd "$D"
if [ -d libs-simplewebkit ];then
  cd ./libs-simplewebkit
  git pull
else
  git clone https://github.com/onflapp/libs-simplewebkit.git
fi

