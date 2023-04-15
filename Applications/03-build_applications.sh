#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

echo "=================="
echo " Terminal Kit"
echo "=================="

cd ../../gs-terminal/TerminalKit || exit 1

make clean
make -j2 || exit 1

sudo -E make install

echo "=================="
echo " Terminal App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Terminal || exit 1

make clean
make -j2 || exit 1

sudo -E make install

echo "=================="
echo " VimGS App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/VimGS || exit 1

make clean
make -j2 || exit 1

sudo -E make install

echo "=================="
echo " HtopGS App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/HtopGS || exit 1

make clean
make -j2 || exit 1

sudo -E make install 'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'

echo "=================="
echo " Console App"
echo "=================="

cd "$D"
cd ../../gs-terminal/Applications/Console || exit 1

make clean
make -j2 || exit 1

sudo -E make install 'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'

echo "=================="
echo " Console App"
echo "=================="

cd "$D"
cd ../../gs-webbrowser || exit 1

make clean
make -j2 || exit 1

sudo -E make install

echo "=================="
echo " TextEdit App"
echo "=================="

cd "$D"
cd ../../gs-textedit || exit 1

make clean
make -j2 || exit 1

sudo -E make install

echo "=================="
echo " GNUMail App"
echo "=================="

cd "$D"
cd ../../gnumail/gnumail || exit 1

make clean
make -j2 || exit 1

sudo -E make install

echo "=================="
echo " TalkSoap App"
echo "=================="

cd "$D"
cd ../../gs-talksoup || exit 1

make clean
make -j2 || exit 1

sudo -E make install
