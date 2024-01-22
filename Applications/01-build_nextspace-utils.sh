#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

cd ../../nextspace/Applications/Preferences || exit 1

make clean
make -j2 || exit 1

make install

cd "$D"
cd ../../nextspace/Applications/TimeMon || exit 1

make clean
make -j2 || exit 1

make install 'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
