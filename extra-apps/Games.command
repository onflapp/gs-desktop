#!/bin/bash

git clone https://github.com/gnustep/gap.git gnustep-gap
cd gnustep-gap
D=`pwd`
G="/Applications/Games"

cd ./ported-apps/Games
make || exit 1

echo ""
echo "install to $G"
sudo -E make install APP_INSTALL_DIR=$G

cd "$D"
cd ./user-apps/Games
make || exit 1

echo ""
echo "install to $G"
sudo -E make install APP_INSTALL_DIR=$G
