#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

cd ../../gs-workspace || exit 1

./configure || exit 1

make -j2 || exit 1
make install 'APP_INSTALL_DIR=$(GNUSTEP_SYSTEM_ADMIN_APPS)'
