#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

cd ../../nextspace/Applications/Preferences || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../nextspace/Applications/TimeMon || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../nextspace/Applications/OpenUp || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../nextspace/Applications/Network || exit 1

make clean
make -j2 || exit 1

sudo -E make install
