#!/bin/sh

. ../BUILD_SETTINGS.conf

echo "=================="
echo " libdispatch"
echo "=================="

if [ "x$RUNTIME" = "xgnu" ];then
	echo "skip, using GNU runtime"
	exit 0
fi
if [ "x$RUNTIME" = "xext" ];then
	echo "skip, using GNU runtime"
	exit 0
fi

cd ../../libdispatch || exit 1
rm -Rf _build 2>/dev/null
mkdir -p _build
cd _build

if [ -n "$RELEASE_BUILD" ];then
  BTYPE="Release"
else
  BTYPE="Debug"
fi

### force release build
#BTYPE="Release"

cmake .. \
	-DCMAKE_C_COMPILER=$CC \
	-DCMAKE_CXX_COMPILER=$CXX \
	-DCMAKE_SKIP_RPATH=ON \
	-DCMAKE_BUILD_TYPE=$BTYPE \
	-DCMAKE_INSTALL_PREFIX=/System \
	-DCMAKE_INSTALL_LIBDIR=/System/lib \
	-DINSTALL_PRIVATE_HEADERS=YES \
	-DUSE_GOLD_LINKER=YES \
	-DENABLE_TESTING=OFF \
	-DCMAKE_VERBOSE_MAKEFILE=ON

gmake $MKARGS || exit 1
gmake install || exit 1

ldconfig
