#!/bin/bash

. ../BUILD_SETTINGS.sh

echo "=================="
echo " libobjc2"
echo "=================="

cd ../../libobjc2 || exit 1

rm -Rf _build 2>/dev/null
mkdir -p _build
cd ./_build

if [ -n "$RELEASE_BUILD" ];then
  BTYPE="Release"
else
  BTYPE="Debug"
fi

### force release build
#BTYPE="Release"

cmake .. \
	-DGNUSTEP_INSTALL_TYPE=NONE \
	-DCMAKE_C_COMPILER=$CC \
	-DCMAKE_CXX_COMPILER=$CXX \
	-DCMAKE_C_FLAGS="-DNO_SELECTOR_MISMATCH_WARNINGS -I/System/include -g" \
	-DCMAKE_LIBRARY_PATH=/System/lib \
	-DCMAKE_INSTALL_LIBDIR=/System/lib \
	-DCMAKE_INSTALL_PREFIX=/System \
	-DCMAKE_LINKER=$LD \
	-DCMAKE_MODULE_LINKER_FLAGS="$LDFLAGS -Wl,-rpath,/System/lib" \
	-DCMAKE_SKIP_RPATH=ON \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_BUILD_TYPE=$BTYPE \
	-DOLDABI_COMPAT=OFF \
	-DTESTS=OFF \
	|| exit 1

make -j$NPROC || exit 1

make install
ldconfig
