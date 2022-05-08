#!/bin/bash
set -e

export PATH=/System/bin:$PATH

D=`pwd`
cd ./system
./fetch_all.sh

cd "$D"
cd ./Applications
./fetch_applications.sh
