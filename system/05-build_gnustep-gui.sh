#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

cd ../../gnustep-gui || exit 1

make clean
./configure --disable-icu-config || exit 1

make || exit 1
sudo -E make install
