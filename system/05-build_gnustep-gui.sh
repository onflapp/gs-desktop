#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

echo "=================="
echo " GNUstep GUI"
echo "=================="

cd ../../gnustep-gui || exit 1

make clean
./configure --disable-icu-config || exit 1

make -j$NPROC || exit 1
make install
