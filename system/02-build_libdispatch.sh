#!/bin/bash

cd ../../libdispatch || exit 1
rm -Rf _build 2>/dev/null
mkdir -p _build
cd _build

cmake .. \
	-DCMAKE_C_COMPILER=$CC \
	-DCMAKE_CXX_COMPILER=$CXX \
	-DCMAKE_SKIP_RPATH=ON \
  -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/System \
	-DCMAKE_INSTALL_LIBDIR=/System/lib \
	-DINSTALL_PRIVATE_HEADERS=YES \
	-DENABLE_TESTING=OFF \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
	-DUSE_GOLD_LINKER=YES

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig
