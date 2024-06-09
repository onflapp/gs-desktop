#!/bin/sh
set -e

cd ../../
if [ -d gs-wmaker ];then
  cd ./gs-wmaker
  git pull
else
  git clone https://github.com/onflapp/gs-wmaker.git
fi
