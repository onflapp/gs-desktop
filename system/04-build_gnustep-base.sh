#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

echo "=================="
echo " GNUstep base"
echo "=================="

cd ../../gnustep-base || exit 1

make clean
./configure || exit 1
make -j$NPROC || exit 1

make install
