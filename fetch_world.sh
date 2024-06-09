#!/bin/sh
set -e

git pull

export PATH=/System/bin:$PATH

D=`pwd`
cd ./build
./fetch_all.sh

cd "$D"
cd ./Applications
./fetch_applications.sh
