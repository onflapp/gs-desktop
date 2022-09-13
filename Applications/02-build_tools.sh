#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

cd ./Tools || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ./Addresses || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ./FontManager || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ./ImageViewer || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ./DocumentViewer || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
sudo cp -R ./WPrefs.app /Applications

cd "$D"
cd ../Applications/Addresses/Goodies/VCFViewer || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig
