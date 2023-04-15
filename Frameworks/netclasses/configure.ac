AC_INIT([netclasses], [1.1.0], [aeruder@ksu.edu], [netclasses])
AC_PREREQ([2.57])
AC_SUBST(PACKAGE_VERSION)
AC_CONFIG_SRCDIR([Source/NetBase.m])
AC_CONFIG_HEADER([Source/config.h])

#--------------------------------------------------------------------
# Find the compiler
#--------------------------------------------------------------------
if test "$CC" = ""; then
  CC=`gnustep-config --variable=CC`
fi
if test "$CPP" = ""; then
  CPP=`gnustep-config --variable=CPP`
fi
if test "$CXX" = ""; then
  CXX=`gnustep-config --variable=CXX`
fi
AC_PROG_CC
AC_PROG_CPP


AC_CHECK_HEADERS([sys/types.h sys/socket.h])
AC_CHECK_TYPES([socklen_t],,,[
#include <sys/types.h>
#include <sys/socket.h>
])


AC_OUTPUT([ GNUmakefile
Source/GNUmakefile
])


