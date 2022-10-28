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

include $(GNUSTEP_MAKEFILES)/common.make


#
# Subprojects
#



#
# Bundle
#

PACKAGE_NAME=WindowsMedia
BUNDLE_NAME=WindowsMedia
BUNDLE_EXTENSION=.format
BUNDLE_INSTALL_DIR=$(GNUSTEP_BUNDLES)/Cynthiune
WindowsMedia_PRINCIPAL_CLASS=WindowsMedia


#
# Additional libraries
#

WindowsMedia_LIBRARIES_DEPEND_UPON += 

#
# Resource files
#

WindowsMedia_RESOURCE_FILES=

#
# Header files
#

WindowsMedia_HEADERS= \
CWMFile.h \
ASFMetaData.h \
WindowsMedia.h

#
# Class files
#

WindowsMedia_OBJC_FILES= \
WindowsMedia.m 

#
# C++ files
#

WindowsMedia_CC_FILES= \
CWMFile.cpp

ADDITIONAL_INCLUDE_DIRS += -I../../Frameworks

FRAMEWORKS_DIRS = ../../Frameworks/Cynthiune
FRAMEWORKS = Cynthiune

include ../../frameworks.make

include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
