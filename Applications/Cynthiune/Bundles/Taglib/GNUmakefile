# GNUmakefile - this file is part of Cynthiune
#
# Copyright (C) 2005  Wolfgang Sourdeau
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

PACKAGE_NAME=Taglib
BUNDLE_NAME=Taglib
BUNDLE_EXTENSION=.tags
BUNDLE_INSTALL_DIR=$(GNUSTEP_BUNDLES)/Cynthiune
Taglib_PRINCIPAL_CLASS=Taglib


#
# Additional libraries
#

Taglib_LIBRARIES_DEPEND_UPON += 

#
# Resource files
#

Taglib_RESOURCE_FILES=

#
# Header files
#

Taglib_HEADERS= \
Taglib.h 

#
# Class files
#

Taglib_OBJC_FILES= \
Taglib.m 

#
# C files
#

Taglib_C_FILES= 

#
# C++ files
#

Taglib_CC_FILES= 

ADDITIONAL_INCLUDE_DIRS += -I../../Frameworks

FRAMEWORKS_DIRS = ../../Frameworks/Cynthiune
FRAMEWORKS = Cynthiune

include ../../frameworks.make

include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
