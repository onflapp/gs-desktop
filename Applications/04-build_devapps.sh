#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

cd ../../apps-gorm || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../apps-projectcenter || exit 1

make clean
make -j2 || exit 1

sudo -E make install
