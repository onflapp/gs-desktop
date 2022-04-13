#!/bin/bash

. ./BUILD_SETTINGS.sh

cp ./gs-desktop.layout ../../gnustep-make/FilesystemLayouts/

cd ../../gnustep-make || exit 1

make clean
./configure \
	    --prefix=/ \
	    --with-config-file=/Library/Preferences/GNUstep.conf \
	    --with-layout=gs-desktop.layout \
	    --enable-native-objc-exceptions \
	    --enable-objc-arc \
	    --enable-debug-by-default \
	    --with-library-combo=ng-gnu-gnu

make || exit 1
sudo -E make install
