# GNUmakefile - this file is part of Cynthiune
#
# Copyright (C) 2003, 2004  Wolfgang Sourdeau
# Copyright (C) 2012 Philippe Roussel
#
# Author: Philippe Roussel <p.o.roussel@free.fr>
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

PACKAGE_NAME = AO
BUNDLE_NAME = AO
BUNDLE_EXTENSION = .output
BUNDLE_INSTALL_DIR = $(GNUSTEP_BUNDLES)/Cynthiune
AO_PRINCIPAL_CLASS = AO

#
# Additional libraries
#

AO_LIBRARIES_DEPEND_UPON +=

#
# Resource files
#

AO_RESOURCE_FILES=

#
# Header files
#

AO_HEADERS=

#
# Class files
#

AO_OBJC_FILES= \
ao.m

ADDITIONAL_INCLUDE_DIRS += -I../../Frameworks

FRAMEWORKS_DIRS = ../../Frameworks/Cynthiune
FRAMEWORKS = Cynthiune

include ../../frameworks.make

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
