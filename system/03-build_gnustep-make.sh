#!/bin/bash

. ../BUILD_SETTINGS.sh

echo "=================="
echo " GNUstep make"
echo "=================="

cp ./gs-desktop.layout ../../gnustep-make/FilesystemLayouts/

cd ../../gnustep-make || exit 1

if [ -n "$RELEASE_BUILD" ];then
  DEBUG_ARGS=""
else
  DEBUG_ARGS="--enable-debug-by-default"
fi

if command -V dpkg >/dev/null 2>&1 ;then
  if [ `dpkg --print-architecture 2>/dev/null` = "armhf" ];then
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "this is ARM 32bit, forcing runtime-abi to 1.9"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    RUNTIME_ARGS="-with-runtime-abi=gnustep-1.9"
  fi
fi
 
make clean
./configure \
	    --prefix=/ \
	    --with-config-file=/Library/Preferences/GNUstep.conf \
	    --with-layout=gs-desktop.layout \
            --with-library-combo=ng-gnu-gnu \
	    --enable-native-objc-exceptions \
	    --enable-objc-arc \
	    $DEBUG_ARGS $RUNTIME_ARGS

make || exit 1
make install
