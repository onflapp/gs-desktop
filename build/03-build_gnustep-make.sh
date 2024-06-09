#!/bin/sh

. ../BUILD_SETTINGS.conf

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

if [ "x$RUNTIME" = "xgnu" ];then
  RUNTIME_ARGS="--with-library-combo=gnu-gnu-gnu"
else
  if command -V dpkg >/dev/null 2>&1 ;then
    if [ `dpkg --print-architecture 2>/dev/null` = "armhf" ];then
      echo ""
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "this is ARM 32bit, forcing runtime-abi to 1.9"
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo ""
      RUNTIME_ARGS="--with-runtime-abi=gnustep-1.9 --with-library-combo=ng-gnu-gnu"
    else
      RUNTIME_ARGS="--with-library-combo=ng-gnu-gnu"
    fi
  fi
fi

gmake clean
./configure \
	    --prefix=/ \
	    --with-config-file=/Library/Preferences/GNUstep.conf \
	    --with-layout=gs-desktop.layout \
	    --enable-native-objc-exceptions \
	    $DEBUG_ARGS $RUNTIME_ARGS

gmake || exit 1
gmake install || exit 1
