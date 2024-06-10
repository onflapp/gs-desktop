#!/bin/sh
D=`pwd`

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

build_app() {
  cd "$D"
  cd ./$1 || exit 1

  gmake clean

  gmake $MKARGS || exit 1
  gmake install $2
}

build_app "Tools"
build_app "Preferences"
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
build_app "TimeMon"         'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "VolMon"          'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "OpenUp"          'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "MountUp"         'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "NetHood"         'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
#build_app "Network"         'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "ScreenShot"      'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "WrapperFactory"  'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "SystemManager"   'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "InnerSpace"      'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'
build_app "ScanImage"       'APP_INSTALL_DIR=$(GNUSTEP_LOCAL_ADMIN_APPS)'

build_app "NotMon"          'APP_INSTALL_DIR=$(GNUSTEP_SYSTEM_APPS)'
build_app "GestureHelper"   'APP_INSTALL_DIR=$(GNUSTEP_SYSTEM_APPS)'

###
cd "$D"
cd ../Applications/Addresses/Goodies/VCFViewer || exit 1

gmake $MKARGS || exit 1
gmake install

ldconfig

###
cd "$D"
cd ../../libs-steptalk/Examples/Shell

gmake $MKARGS || exit 1
gmake install

###
. /Library/Preferences/GNUstep.conf


cd "$D"
cp -R ./Wrappers/WPrefs.app $GNUSTEP_LOCAL_ADMIN_APPS

cp -R ./Wrappers/Lookup.app $GNUSTEP_LOCAL_ADMIN_APPS

cp ./Librarian/Tools/* /System/bin

cd "$D"
if [ -d "/Applications/GSSpeechRecognitionServer.app" ];then
  mv /Applications/GSSpeechRecognitionServer.app $GNUSTEP_SYSTEM_APPS
fi

if [ -d "/Applications/GSSpeechServer.app" ];then
  mv /Applications/GSSpeechServer.app $GNUSTEP_SYSTEM_APPS
fi
