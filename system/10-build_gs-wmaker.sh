#!/bin/bash

. /Developer/Makefiles/GNUstep.sh
. ../BUILD_SETTINGS.sh

unset LD
unset LDFLAGS

cd ../../gs-wmaker || exit 1

make clean
if [ -n "$RELEASE_BUILD" ];then
  DEBUG_ARGS=""
else
  DEBUG_ARGS="--enable-debug"
fi


./autogen.sh
./configure --prefix=/System $DEBUG_ARGS --enable-randr || exit 1

make -j2 || exit 1
sudo -E make install
