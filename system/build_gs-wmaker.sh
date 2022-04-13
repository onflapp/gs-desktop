#!/bin/bash
set -e

. /Developer/Makefiles/GNUstep.sh

cd ../../gs-wmaker || exit 1

./autogen.sh
./configure --prefix=/System --enable-randr
make install
