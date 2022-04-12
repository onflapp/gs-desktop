#!/bin/bash
set -e

. /Developer/Makefiles/GNUstep.sh

cd ../../gnustep-gui || exit 1

make clean
./configure

make install
