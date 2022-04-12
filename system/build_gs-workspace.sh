#!/bin/bash
set -e

. /Developer/Makefiles/GNUstep.sh

cd ../../gs-workspace || exit 1

./configure || exit 1

make -j2 install
