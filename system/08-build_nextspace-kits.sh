#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

cd ../../nextspace/Frameworks || exit 1

make clean
make -j$NPROC || exit 1

make install
ldconfig
