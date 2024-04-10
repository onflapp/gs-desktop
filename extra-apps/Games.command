#!/bin/bash

D=`pwd`
G="/Applications/Games"

git clone https://github.com/gnustep/gap.git gnustep-gap

cd ./gnustep-gap/ported-apps/Games
make || exit 1

echo ""
echo "install to $G"
sudo -E make install APP_INSTALL_DIR=$G

cd "$D"
cd ./gnustep-gap/user-apps/Games
make || exit 1

echo ""
echo "install to $G"
sudo -E make install APP_INSTALL_DIR=$G

cd "$D"
git clone https://github.com/gomoku/Gomoku.app-GNUstep.git gomoku
cd ./gomoku
make || exit 1

echo ""
echo "install to $G"
sudo -E make install APP_INSTALL_DIR=$G
