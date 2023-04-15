#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

echo "=================="
echo " GNUstep Backend"
echo "=================="

cd ../../gnustep-back || exit 1

make clean
./configure --enable-graphics=art --with-name=art
make || exit 1

sudo -E make fonts=no install

make clean
./configure --enable-graphics=cairo --with-name=cairo
make || exit 1

sudo -E make fonts=no install
