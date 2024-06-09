#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

unset LD
unset LDFLAGS

cd ../../gs-wmaker || exit 1

gmake clean
if [ -n "$RELEASE_BUILD" ];then
  DEBUG_ARGS=""
else
  DEBUG_ARGS="--enable-debug"
fi


./autogen.sh
./configure --prefix=/System $DEBUG_ARGS --enable-randr --enable-dbus || exit 1

gmake $MKARGS || exit 1
gmake install || exit 1
