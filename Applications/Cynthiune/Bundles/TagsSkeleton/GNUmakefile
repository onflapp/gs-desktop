# GNUmakefile - this file is part of Cynthiune
#
# Copyright (C) 2006  Wolfgang Sourdeau
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

PACKAGE_NAME=$TAGS$
BUNDLE_NAME=$TAGS$
BUNDLE_EXTENSION=.tags
BUNDLE_INSTALL_DIR=$(GNUSTEP_BUNDLES)/Cynthiune
$TAGS$_PRINCIPAL_CLASS=$TAGS$


#
# Additional libraries
#

$TAGS$_LIBRARIES_DEPEND_UPON += 

#
# Resource files
#

$TAGS$_RESOURCE_FILES=

#
# Header files
#

$TAGS$_HEADERS= \
$TAGS$.h 

#
# Class files
#

$TAGS$_OBJC_FILES= \
$TAGS$.m 

#
# C files
#

$TAGS$_C_FILES= 

#
# C++ files
#

$TAGS$_CC_FILES= 

ADDITIONAL_INCLUDE_DIRS += -I../../Frameworks

FRAMEWORKS_DIRS = ../../Frameworks/Cynthiune
FRAMEWORKS = Cynthiune

include ../../frameworks.make

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
