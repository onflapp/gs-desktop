#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

cd ../../gs-workspace || exit 1

./configure || exit 1

gmake clean

gmake $MKARGS || exit 1
gmake install 'APP_INSTALL_DIR=$(GNUSTEP_SYSTEM_ADMIN_APPS)' || exit 1
