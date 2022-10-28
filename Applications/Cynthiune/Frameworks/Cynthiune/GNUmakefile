# GNUmakefile - this file is part of Cynthiune
#
# Copyright (C) 2004, 2005  Wolfgang Sourdeau
#
# Author: Wolfgang Sourdeau <wolfgang@contre.com>
#
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
#

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = Cynthiune
LIBRARY_VAR = CYNTHIUNE
LIBRARY_NAME = Cynthiune

FRAMEWORK_NAME = Cynthiune

CYNTHIUNE_MAJOR_VERSION=0
CYNTHIUNE_MINOR_VERSION=0
CYNTHIUNE_SUBMINOR_VERSION=1
CYNTHIUNE_VERSION=${CYNTHIUNE_MAJOR_VERSION}.${CYNTHIUNE_MINOR_VERSION}.${CYNTHIUNE_SUBMINOR_VERSION}
VERSION=${CYNTHIUNE_VERSION}

Cynthiune_LANGUAGES=
Cynthiune_LOCALIZED_RESOURCE_FILES=

#
# Resource files
#

Cynthiune_RESOURCE_FILES=

#
# Header files
#

Cynthiune_HEADER_FILES= \
CynthiuneBundle.h \
Format.h \
NSArrayExtensions.h \
NSCellExtensions.h \
NSColorExtensions.h \
NSNumberExtensions.h \
NSStringExtensions.h \
NSTimerExtensions.h \
NSViewExtensions.h \
Output.h \
Preference.h \
utils.h

#
# Class files
#

Cynthiune_OBJC_FILES= \
NSArrayExtensions.m \
NSCellExtensions.m \
NSColorExtensions.m \
NSNumberExtensions.m \
NSStringExtensions.m \
NSTimerExtensions.m \
NSViewExtensions.m \
utils.m

Cynthiune_LIBRARIES_DEPEND_UPON += $(OBJC_LIBS) $(GUI_LIBS) \
				     -l$(FOUNDATION_LIBRARY_NAME)

-include GNUmakefile.preamble
-include GNUmakefile.local

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
include $(GNUSTEP_MAKEFILES)/library.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif
-include GNUmakefile.postamble
