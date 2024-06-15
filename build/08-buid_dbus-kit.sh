#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

D=`pwd`

echo "=================="
echo " DBUS Kit"
echo "=================="

cd ../../libs-dbuskit

if [ "x$CC" = "xgcc" ];then
  GCC_BASE=`gcc -print-search-dirs | awk '/install:/{print $2}'`
  echo "gcc:$GCC_BASE"
  export CPPFLAGS="$CPPFLAGS -I$GCC_BASE/include"
fi

./configure --disable-global-menu-bundle \
            --disable-notification-bundle || exit 1

gmake $MKARGS || exit 1
gmake install || exit 1

ldconfig
