#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

echo "=================="
echo " GNUstep base"
echo "=================="

cd ../../gnustep-base || exit 1

export ICU_CFLAGS="`icu-config --cppflags`"
export ICU_LIBS="`icu-config --ldflags`"

gmake clean
./configure || exit 1

gmake $MKARGS || exit 1
gmake install || exit 1
