#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

echo "=================="
echo " GNUstep GUI"
echo "=================="

cd ../../gnustep-gui || exit 1

gmake clean
./configure --disable-icu-config || exit 1

gmake $MKARGS || exit 1
gmake install || exit 1
