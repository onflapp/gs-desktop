#!/bin/sh
set -e

cd ../../
if [ -d nextspace ];then
  cd ./nextspace
  git pull
else
  git clone https://github.com/onflapp/nextspace.git
fi
