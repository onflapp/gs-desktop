#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

D=`pwd`

build_kit() {
  cd "$D"
  echo "=================="
  echo " $1"
  echo "=================="

  cd "$2" || exit 1

  gmake distclean
  gmake clean

  if [ -x ./configure ];then
    ./configure
  fi

  gmake $MKARGS || exit 1
  gmake install || exit 1

  ldconfig
}

build_kit "StepTalk Kit" "../../libs-steptalk"
build_kit "SimpleWeb Kit" "../../libs-simplewebkit"
build_kit "PDF Kit" "../Frameworks/PDFKit"
build_kit "Netclasses" "../Frameworks/netclasses"
build_kit "Pantomine" "../../gnumail/pantomime"
build_kit "Terminal Kit" "../../gs-terminal/TerminalKit"
build_kit "Addresses Kit" "../Applications/Addresses/Frameworks"
build_kit "System Kit" "../Frameworks/SystemKit"
build_kit "Sound Kit" "../Frameworks/SoundKit"
build_kit "Desktop Kit" "../Frameworks/DesktopKit"
