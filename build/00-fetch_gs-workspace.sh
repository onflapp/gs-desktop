#!/bin/sh

set -e

cd ../../
if [ -d gs-workspace ];then
  cd ./gs-workspace
  git pull
else
  git clone https://github.com/onflapp/gs-workspace.git gs-workspace
fi
