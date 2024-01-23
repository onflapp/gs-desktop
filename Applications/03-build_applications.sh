#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

echo "=================="
echo " Terminal App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Terminal || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " VimGS App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/VimGS || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " EmacsGS App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/EmacsGS || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " GNUPlot"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/GNUPlot || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " HtopGS App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/HtopGS || exit 1

make clean
make -j2 || exit 1

make install 'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'

echo "=================="
echo " Console App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/Console || exit 1

make clean
make -j2 || exit 1

make install 'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'

echo "=================="
echo " Console App"
echo "=================="

cd "$D"
cd ../../gs-webbrowser || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " TextEdit App"
echo "=================="

cd "$D"
cd ../../gs-textedit || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " GNUMail App"
echo "=================="

cd "$D"
cd ../../gnumail/gnumail || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " TalkSoap App"
echo "=================="

cd "$D"
cd ../../gs-talksoup || exit 1

make clean
make -j2 || exit 1

make install

echo "=================="
echo " SimpleAgenda App"
echo "=================="

cd "$D"
cd ../../simpleagenda || exit 1

./configure || exit 1
make clean
make -j2 || exit 1

make install
