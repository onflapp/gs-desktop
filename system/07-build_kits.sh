#!/bin/bash

. /Developer/Makefiles/GNUstep.sh
D=`pwd`

export PATH=/System/bin:$PATH

echo "=================="
echo " DBus Kit"
echo "=================="

cd ../../libs-dbuskit || exit 1

make distclean
./configure
make -j2 || exit 1

make install
ldconfig

echo "=================="
echo " StepTalk Kit"
echo "=================="

cd "$D"
cd ../../libs-steptalk || exit 1

make -j2 || exit 1

make install
ldconfig

cd ./Examples/Shell || exit 1

make || exit 1
make install

echo "=================="
echo " SimpleWeb Kit"
echo "=================="

cd "$D"
cd ../../libs-simplewebkit || exit 1

make -j2 || exit 1

make install
ldconfig

echo "=================="
echo " PDF Kit"
echo "=================="

cd "$D"
cd ../Frameworks/PDFKit || exit 1

make distclean
./configure || exit 1
make -j2 || exit 1

make install
ldconfig

echo "=================="
echo " Netclasses"
echo "=================="

cd "$D"
cd ../Frameworks/netclasses || exit 1

./configure || exit 1
make -j2 || exit 1

make install
ldconfig

echo "=================="
echo " Pantomine"
echo "=================="

cd "$D"
cd ../../gnumail/pantomime || exit 1

make -j2 || exit 1

make install
ldconfig

echo "=================="
echo " Terminal Kit"
echo "=================="

cd ../../gs-terminal/TerminalKit || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " Addresses Kit"
echo "=================="

cd "$D"
cd ../Applications/Addresses/Frameworks || exit 1

make -j2 || exit 1

make install
ldconfig

echo "=================="
echo " XCode Kit"
echo "=================="

cd "$D"
cd ../../libs-xcode || exit 1

make -j2 || exit 1

make install
ldconfig
