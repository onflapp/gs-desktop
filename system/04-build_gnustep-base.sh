#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

echo "##################"
echo "GNUstep base"
echo "##################"

cd ../../gnustep-base || exit 1

make clean
./configure || exit 1
make -j2 || exit 1

sudo -E make install
