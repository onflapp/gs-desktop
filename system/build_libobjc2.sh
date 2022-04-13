#!/bin/bash

cd ../../libobjc2 || exit 1

rm -R _build 2>/dev/null
mkdir -p _build
cd ./_build
cmake .. \
	-DGNUSTEP_INSTALL_TYPE=NONE \
	-DCMAKE_C_COMPILER=$CC \
	-DCMAKE_CXX_COMPILER=$CXX \
	-DCMAKE_C_FLAGS="-I/System/include -g" \
	-DCMAKE_LIBRARY_PATH=/System/lib \
	-DCMAKE_INSTALL_LIBDIR=/System/lib \
	-DCMAKE_INSTALL_PREFIX=/System \
	-DCMAKE_LINKER=$LD \
	-DCMAKE_MODULE_LINKER_FLAGS="$LDFLAGS -Wl,-rpath,/System/lib" \
	-DCMAKE_SKIP_RPATH=ON \
	-DTESTS=OFF \
	-DCMAKE_BUILD_TYPE=Release \
	|| exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig
