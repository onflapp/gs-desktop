#!/bin/bash
set -e

. /Developer/Makefiles/GNUstep.sh

cd ../../gnustep-back || exit 1

make clean
./configure \
  --enable-graphics=art \
  --with-name=art

make fonts=no install
