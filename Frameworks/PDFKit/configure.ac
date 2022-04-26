AC_PREREQ(2.52)
AC_INIT(PDFKit, 1.0.1)

if test -z "$GNUSTEP_MAKEFILES"; then
  AC_MSG_ERROR([You must run the GNUstep initialization script first!])
fi

#--------------------------------------------------------------------
# Use config.guess, config.sub and install-sh provided by gnustep-make
#--------------------------------------------------------------------
AC_CONFIG_AUX_DIR([$GNUSTEP_MAKEFILES])

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

#--------------------------------------------------------------------
# Determine the host, build, and target systems
#--------------------------------------------------------------------
AC_CANONICAL_TARGET([])

AC_PROG_CC
AC_PROG_CXX


AC_CONFIG_FILES([GNUmakefile xpdf/GNUmakefile xpdf/bridge/GNUmakefile xpdf/xpdf-3.04/GNUmakefile])

AC_OUTPUT

