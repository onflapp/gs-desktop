#!/bin/bash

. /Developer/Makefiles/GNUstep.sh

cd ../../nextspace/Frameworks || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig
