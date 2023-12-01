#!/bin/bash
set -e

git pull

export PATH=/System/bin:$PATH

D=`pwd`
cd ./system
./fetch_all.sh

cd "$D"
cd ./Applications
./fetch_applications.sh
