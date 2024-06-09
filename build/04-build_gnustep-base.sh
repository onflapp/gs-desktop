#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

echo "=================="
echo " GNUstep base"
echo "=================="

cd ../../gnustep-base || exit 1

gmake clean
./configure || exit 1

gmake $MKARGS || exit 1
gmake install || exit 1
