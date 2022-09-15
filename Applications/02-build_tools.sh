#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

function build_app {
  cd "$D"
  cd ./$1 || exit 1

  make clean
  make -j2 || exit 1

  sudo -E make install
}

build_app "Tools"
build_app "Affiche"
build_app "FontManager"
build_app "Calculator"
build_app "DefaultsManager"
build_app "HelpViewer"
build_app "BatMon"
build_app "OpenUp"
build_app "ImageViewer"
build_app "DocumentViewer"
build_app "ScreenShot"

cd "$D"
sudo cp -R ./WPrefs.app /Applications

cd "$D"
cd ../Applications/Addresses/Goodies/VCFViewer || exit 1

make -j2 || exit 1

sudo -E make install
sudo -E ldconfig
