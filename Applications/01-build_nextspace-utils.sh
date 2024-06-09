#!/bin/sh
D=`pwd`

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

cd ../../nextspace/Applications/Preferences || exit 1

gmake clean

gmake $MKARGS || exit 1
gmake install || exit 1

cd "$D"
cd ../../nextspace/Applications/TimeMon || exit 1

gmake clean
gmake $MKARGS || exit 1
gmake install 'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)' || exit 1
