#!/bin/bash

. /Developer/Makefiles/GNUstep.sh
. ../BUILD_SETTINGS.sh

cd ../../gs-wmaker || exit 1

make clean

./autogen.sh
./configure --prefix=/System --enable-randr || exit 1

make -j2 || exit 1
sudo -E make install
