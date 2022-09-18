#!/bin/bash

. ../BUILD_SETTINGS.sh

cp ./gs-desktop.layout ../../gnustep-make/FilesystemLayouts/

cd ../../gnustep-make || exit 1

if [ -n "$RELEASE_BUILD" ];then
  DEBUG_ARGS=""
else
  DEBUG_ARGS="--enable-debug-by-default"
fi

make clean
./configure \
	    --prefix=/ \
	    --with-config-file=/Library/Preferences/GNUstep.conf \
	    --with-layout=gs-desktop.layout \
	    --enable-native-objc-exceptions \
	    --enable-objc-arc $DEBUG_ARGS
            #--with-library-combo=ng-gnu-gnu
	    #--with-runtime-abi=gnustep-2.0

make || exit 1
sudo -E make install
