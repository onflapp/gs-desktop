#!/bin/sh
#
# executable.template.  Generated from executable.template.in by configure.
#
# Copyright (C) 1999-2002 Free Software Foundation, Inc.
#
# Author: Adam Fedor <fedor@gnu.org>
# Date: May 1999
#
# Author: Nicola Pero <n.pero@mi.flashnet.it>
# Date: 2001, 2002
#
# This file is part of the GNUstep Makefile Package.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 

# This is a shell script which attempts to find the GNUstep executable
# of the same name based on the current host and library_combo.

#--------------------------------------------------------------------------
# Main body
#--------------------------------------------------------------------------
if [ -z "$EXEEXT" ]; then
  EXEEXT=
fi
if [ -z "$LIBRARY_COMBO" ]; then
  LIBRARY_COMBO=gnu-gnu-gnu
fi

# Process arguments
app="$0"
show_available_platforms=0
show_relative_path=0
show_full_path=0
while true
do
  case "$1" in

    --script-help)
	echo usage: `basename "$0"` [--library-combo=...]
	echo "       [--available-platforms][--full-executable-path]"
	echo "       [--relative-executable-path] [arguments...]"
	echo
	echo "   --library-combo=... specifies a GNUstep backend to use."
	echo "   It overrides the default LIBRARY_COMBO environment variable."
	echo
	echo "   --available-platforms displays a list of valid exec hosts"
	echo "   --full-executable-path displays full path to executable"
	echo "   --relative-executable-path displays subdirectory path"
	echo "   arguments... are the arguments to the application."
	exit 0
	;;
    --library-combo=*)
        tmp_root="$GNUSTEP_SYSTEM_ROOT"
        . "$tmp_root/Library/Makefiles/GNUstep-reset.sh"
	LIBRARY_COMBO=`echo "$1" | sed 's/--library-combo=//'`
        . "$tmp_root/Library/Makefiles/GNUstep.sh"
	shift
	;;
    --available-platforms)
        show_available_platforms=1
        exit 0
	;;
    --full-executable-path)
	show_full_path=1
        break
	;;
    --relative-executable-path)
	show_relative_path=1
        break
	;;
    *)
        break;;
    esac
done

if [ "$LIBRARY_COMBO" = nx ]; then
  LIBRARY_COMBO=nx-nx-nx
elif [ "$LIBRARY_COMBO" = gnu ]; then
  LIBRARY_COMBO=gnu-gnu-gnu
elif [ "$LIBRARY_COMBO" = fd ]; then
  LIBRARY_COMBO=gnu-fd-gnu
elif [ "$LIBRARY_COMBO" = apple ]; then
  LIBRARY_COMBO=apple-apple-apple
fi
export LIBRARY_COMBO

# Find path to ourself
dir="`dirname \"$app\"`"

case "$app" in
  /*)	# An absolute path.
	full_appname="$dir";;
  */*)	# A relative path
	full_appname="`(cd \"$dir\"; pwd)`";;
  *)	# A path that needs to be searched
	if [ -n "$GNUSTEP_PATHLIST" ]; then
	    SPATH="$GNUSTEP_PATHLIST"
	else
	    SPATH="$PATH"
	fi
	SPATH=".:$SPATH"
	IFS=:
	for path_dir in $SPATH; do
	  if [ -d "$path_dir/$dir" ]; then
	    full_appname="`(cd \"$path_dir/$dir\"; pwd)`"
	    break;
	  fi
	  if [ -d "$path_dir/Applications/$dir" ]; then
	    full_appname="`(cd \"$path_dir/Applications/$dir\"; pwd)`"
	    break;
	  fi
	done;;
esac

if [ -z "$full_appname" ]; then
  echo "Can't find absolute path for $app! Please specify full path when"
  echo "invoking executable"
  exit 1
fi

#
# get base app name
#
appname=
if [ -f "$full_appname/Resources/Info-gnustep.plist" ]; then
# -n disable auto-print (for portability reasons)
#   /^ *NSExecutable *=/ matches every line beginning with
#        zero or more spaces, followed by 'NSExecutable', followed by zero or
#        more spaces, followed by '='
#   to this line we apply the following commands:
#   s/"//g; which deletes all " in the line.
#   s/^ *NSExecutable *= *\([^ ;]*\) *;.*/\1/p;
#     which replaces 'NSExecutable = Gorm; ' with 'Gorm', then, because
#     of the 'p' at the end, prints out the result
#   q; which quits sed since we know there must be only a single line
#      to replace.
  appname=`sed -n -e '/^ *NSExecutable *=/ \
           {s/"//g; s/^ *NSExecutable *= *\([^ ;]*\) *;.*/\1/p; q;}' \
                "$full_appname/Resources/Info-gnustep.plist"`
fi
if [ -z "$appname" ]; then
  appname="`basename \"$app\"`"
fi

appname="$appname$EXEEXT"

if [ $show_available_platforms = 1 ]; then
  cd "$full_appname"
  #available_platforms
  exit 0
fi

#
# Determine the host information
#
if [ -z "$GNUSTEP_HOST" ]; then
  GNUSTEP_HOST=`(cd /tmp; $GNUSTEP_SYSTEM_ROOT/Library/Makefiles/config.guess)`
  GNUSTEP_HOST=`(cd /tmp; $GNUSTEP_SYSTEM_ROOT/Library/Makefiles/config.sub $GNUSTEP_HOST)`
  export GNUSTEP_HOST
fi
if [ -z "$GNUSTEP_HOST_CPU" ]; then
  GNUSTEP_HOST_CPU=`$GNUSTEP_SYSTEM_ROOT/Library/Makefiles/cpu.sh $GNUSTEP_HOST`
  GNUSTEP_HOST_CPU=`$GNUSTEP_SYSTEM_ROOT/Library/Makefiles/clean_cpu.sh $GNUSTEP_HOST_CPU`
  export GNUSTEP_HOST_CPU
fi
if [ -z "$GNUSTEP_HOST_VENDOR" ]; then
  GNUSTEP_HOST_VENDOR=`$GNUSTEP_SYSTEM_ROOT/Library/Makefiles/vendor.sh $GNUSTEP_HOST`
  GNUSTEP_HOST_VENDOR=`$GNUSTEP_SYSTEM_ROOT/Library/Makefiles/clean_vendor.sh $GNUSTEP_HOST_VENDOR`
  export GNUSTEP_HOST_VENDOR
fi
if [ -z "$GNUSTEP_HOST_OS" ]; then
  GNUSTEP_HOST_OS=`$GNUSTEP_SYSTEM_ROOT/Library/Makefiles/os.sh $GNUSTEP_HOST`
  GNUSTEP_HOST_OS=`$GNUSTEP_SYSTEM_ROOT/Library/Makefiles/clean_os.sh $GNUSTEP_HOST_OS`
  export GNUSTEP_HOST_OS
fi

#
# Make sure the executable is there
#
if [ -x "$full_appname/$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS/$LIBRARY_COMBO/$appname" ]; then
  relative_path="$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS/$LIBRARY_COMBO/$appname"
elif [ -x "$full_appname/$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS/$appname" ]; then
  relative_path="$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS/$appname"
elif [ -x "$full_appname/$GNUSTEP_HOST_CPU/$appname" ]; then
  relative_path="$GNUSTEP_HOST_CPU/$appname"
elif [ "$full_appname/$appname" != "$0" -a -x "$full_appname/$appname" ]; then
  relative_path="$appname"
else
  # Search for a binary for this machine but a different library combo
  if [ -d "$full_appname/$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS" ]; then
    tmp_path="`pwd`"
    cd "$full_appname/$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS";
    found=no
    for lib_combo in * ; do
      if [ "$lib_combo" != '*' ]; then
        if [ -x "$lib_combo/$appname" ]; then
          # Switch LIBRARY_COMBO on the fly
          tmp_root="$GNUSTEP_SYSTEM_ROOT"
          . "$tmp_root/Library/Makefiles/GNUstep-reset.sh"
          LIBRARY_COMBO="$lib_combo"
          . "$tmp_root/Library/Makefiles/GNUstep.sh"
          # Use the found executable
          relative_path="$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS/$LIBRARY_COMBO/$appname"
          found=yes
          break
        fi
      fi
    done
    cd "$tmp_path"
    if [ "$found" != yes ]; then
      echo "$full_appname application does not have a binary for this kind of machine/operating system ($GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS)."
      exit 1
    fi
  fi
fi

if [ $show_relative_path = 1 ]; then
  echo "$relative_path"
  exit 0
fi
if [ $show_full_path = 1 ]; then
  echo "$full_appname/$relative_path"
  exit 0
fi

if [ "$LIBRARY_COMBO" = nx-nx-nx -a "$GNUSTEP_HOST_OS" = nextstep4 ]; then
  if [ -f "$full_appname/library_paths.openapp" ]; then
    additional_library_paths="`cat $full_appname/library_paths.openapp`"
  fi
else
  if [ -f "$full_appname/$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS/$LIBRARY_COMBO/library_paths.openapp" ]; then
    additional_library_paths="`cat \"$full_appname/$GNUSTEP_HOST_CPU/$GNUSTEP_HOST_OS/$LIBRARY_COMBO/library_paths.openapp\"`"
  fi
fi

# Load up LD_LIBRARY_PATH
. "$GNUSTEP_SYSTEM_ROOT/Library/Makefiles/ld_lib_path.sh"

exec "$full_appname/$relative_path" "$@"

