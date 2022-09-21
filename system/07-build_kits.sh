#!/bin/bash

. /Developer/Makefiles/GNUstep.sh
D=`pwd`

cd ../../libs-dbuskit || exit 1

./configure
make -j2 || exit 1

sudo -E make install
sudo -E ldconfig

cd "$D"
cd ../../libs-steptalk || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig

cd ./Examples/Shell || exit 1

make || exit 1
sudo -E make install

cd "$D"
cd ../../libs-simplewebkit || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig

cd "$D"
cd ../Frameworks/PDFKit || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig

cd "$D"
cd ../Frameworks/pantomime || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig

cd "$D"
cd ../Applications/Addresses/Frameworks || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig
