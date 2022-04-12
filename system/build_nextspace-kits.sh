#!/bin/bash
set -e

. /Developer/Makefiles/GNUstep.sh

cd ../../nextspace/Frameworks || exit 1

make -j2 install
ldconfig
