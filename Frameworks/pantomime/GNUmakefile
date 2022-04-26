#
#  GNUstep Makefile for Pantomime Framework
#
#  Copyright (C) 2001-2004 Ludovic Marcotte
#                2013 The GNUstep team
#
#  Author: Ludovic Marcotte <ludovic@Sophos.ca>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details. 
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(warning )
    $(warning Unable to obtain GNUSTEP_MAKEFILES setting from gnustep-config!)
    $(warning Perhaps gnustep-make is not properly installed,)
    $(warning so gnustep-config is not in your PATH.)
    $(warning )
    $(warning Your PATH is currently $(PATH))
    $(warning )
  endif
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

PACKAGE_NAME = Pantomime

MAJOR_VERSION=1
MINOR_VERSION=3
SUBMINOR_VERSION=0
VERSION=${MAJOR_VERSION}.${MINOR_VERSION}.${SUBMINOR_VERSION}

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECTS = Framework/Pantomime 

include $(GNUSTEP_MAKEFILES)/aggregate.make

include GNUmakefile.postamble
