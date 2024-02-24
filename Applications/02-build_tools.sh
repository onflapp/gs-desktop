#!/bin/bash
D=`pwd`

. /Developer/Makefiles/GNUstep.sh

export PATH=/System/bin:$PATH

function build_app {
  cd "$D"
  cd ./$1 || exit 1

  make clean
  make -j2 || exit 1

  make install $2
}

build_app "Tools"
build_app "Addresses"
build_app "Affiche"
build_app "Calculator"
build_app "ImageViewer"
build_app "DocumentViewer"
build_app "DictionaryReader"
build_app "RemoteView"
build_app "FTP"
build_app "Librarian"
build_app "Player"
build_app "Sketch"

build_app "CloudManager"    'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "DefaultsManager" 'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "HelpViewer"      'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "FontManager"     'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "BatMon"          'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "VolMon"          'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "OpenUp"          'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "MountUp"         'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "NetHood"         'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "Network"         'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "ScreenShot"      'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "WrapperFactory"  'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "SystemManager"   'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "InnerSpace"      'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'

build_app "NotMon"          'APP_INSTALL_DIR=$(GNUSTEP_SYSTEM_APPS)'

cd "$D"
cd ../Applications/Addresses/Goodies/VCFViewer || exit 1

make -j2 || exit 1

make install
ldconfig

. /Library/Preferences/GNUstep.conf


cd "$D"
cp -R ./WPrefs.app $GNUSTEP_LOCAL_ADMIN_APPS

cp -R ./Lookup.app $GNUSTEP_LOCAL_ADMIN_APPS

cp ./Librarian/Tools/* /System/bin

cd "$D"
if [ -d "/Applications/GSSpeechRecognitionServer.app" ];then
  mv /Applications/GSSpeechRecognitionServer.app $GNUSTEP_SYSTEM_APPS
fi

if [ -d "/Applications/GSSpeechServer.app" ];then
  mv /Applications/GSSpeechServer.app $GNUSTEP_SYSTEM_APPS
fi
