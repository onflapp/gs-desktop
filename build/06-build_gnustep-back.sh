#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

echo "=================="
echo " GNUstep Backend"
echo "=================="

cd ../../gnustep-back || exit 1

gmake clean
./configure --enable-graphics=art --with-name=art
gmake $MKARGS || exit 1

gmake fonts=no install || exit 1

gmake clean
./configure --enable-graphics=cairo --with-name=cairo
gmake $MKARGS || exit 1

gmake fonts=no install || exit 1
