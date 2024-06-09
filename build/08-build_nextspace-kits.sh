#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

cd ../../nextspace/Frameworks || exit 1

gmake clean
gmake $MKARGS || exit 1
gmake install || exit 1

ldconfig
