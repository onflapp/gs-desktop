#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

cd ../../apps-gorm || exit 1

make clean
make -j2 || exit 1

make install

cd "$D"
cd ../../apps-projectcenter || exit 1

make clean
make -j2 || exit 1

make install
