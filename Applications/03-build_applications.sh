#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

cd ../../gs-terminal/TerminalKit || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../gs-terminal/Terminal || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../gs-webbrowser || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../gs-textedit || exit 1

make clean
make -j2 || exit 1

sudo -E make install

cd "$D"
cd ../../gs-mail || exit 1

make clean
make -j2 || exit 1

sudo -E make install
