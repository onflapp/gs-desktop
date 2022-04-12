#!/bin/bash
set -e
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

cd ../../nextspace/Applications/Preferences || exit 1

make -j2 install
ldconfig

cd "$D"
