#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

D=`pwd`

echo "=================="
echo " DBus Kit"
echo "=================="

cd ../../libs-dbuskit || exit 1

gmake distclean
./configure
gmake $MKARGS || exit 1
gmake install || exit 1

ldconfig

echo "=================="
echo " StepTalk Kit"
echo "=================="

cd "$D"
cd ../../libs-steptalk || exit 1

gmake clean
gmake $MKARGS || exit 1
gmake install || exit 1

ldconfig

cd ./Examples/Shell || exit 1

gmake || exit 1
gmake install

echo "=================="
echo " SimpleWeb Kit"
echo "=================="

cd "$D"
cd ../../libs-simplewebkit || exit 1

gmake clean
gmake $MKARGS || exit 1
gmake install

ldconfig

echo "=================="
echo " PDF Kit"
echo "=================="

cd "$D"
cd ../Frameworks/PDFKit || exit 1

gmake distclean
./configure || exit 1
gmake $MKARGS || exit 1
gmake install

ldconfig

echo "=================="
echo " Netclasses"
echo "=================="

cd "$D"
cd ../Frameworks/netclasses || exit 1

./configure || exit 1
gmake $MKARGS || exit 1
gmake install

ldconfig

echo "=================="
echo " Pantomine"
echo "=================="

cd "$D"
cd ../../gnumail/pantomime || exit 1

make clean
make -j$NPROC || exit 1

make install
ldconfig

echo "=================="
echo " Terminal Kit"
echo "=================="

cd ../../gs-terminal/TerminalKit || exit 1

make clean
make -j$NPROC || exit 1

make install

echo "=================="
echo " Addresses Kit"
echo "=================="

cd "$D"
cd ../Applications/Addresses/Frameworks || exit 1

make clean
make -j$NPROC || exit 1

make install
ldconfig

echo "=================="
echo " XCode Kit"
echo "=================="

cd "$D"
cd ../../libs-xcode || exit 1

make clean
make -j$NPROC || exit 1

make install
ldconfig
