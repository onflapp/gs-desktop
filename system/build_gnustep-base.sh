#!/bin/bash
set -e

. /Developer/Makefiles/GNUstep.sh

cd ../../gnustep-base || exit 1

make clean
./configure || exit 1

make -j2 install
